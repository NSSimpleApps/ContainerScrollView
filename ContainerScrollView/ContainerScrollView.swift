//
//  ContainerScrollView.swift
//  ContainerScrollView
//
//  Created by NSSimpleApps on 21/12/2018.
//  Copyright © 2018 NSSimpleApps. All rights reserved.
//

import UIKit

class Scheduler {
    class ScheduledOperation: Operation {
        let delay: TimeInterval
        let tag: Int
        init(delay: TimeInterval, tag: Int) {
            self.delay = delay
            self.tag = tag
            super.init()
        }
        override func cancel() {
            self.completionBlock = nil
            super.cancel()
        }
        override func main() {
            Thread.sleep(forTimeInterval: self.delay)
        }
    }
    let delay: TimeInterval
    private let operationQueue = OperationQueue()
    
    init(delay: TimeInterval) {
        self.delay = delay
        //self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    func cancel() {
        self.operationQueue.cancelAllOperations()
    }
    
    func schedule(tag: Int, action: @escaping () -> Void) {
        if self.operationQueue.operations.contains(where: { (operation) -> Bool in
            return (operation as! ScheduledOperation).tag == tag
        }) == false {
            let op = ScheduledOperation(delay: self.delay, tag: tag)
            op.completionBlock = {
                DispatchQueue.main.async {
                    action()
                }
            }
            self.operationQueue.addOperation(op)
        }
    }
    
    deinit {
        self.cancel()
    }
}

public protocol NSKScrollableSubview where Self: UIView {
    var scrollView: UIScrollView { get }
}

public typealias NSKScrollableView = UIView & NSKScrollableSubview

private var kScrollContext: Int8 = 0

class NSKContainerScrollView: UIView {
    override func willRemoveSubview(_ subview: UIView) {
        if let scrollView = self.superview as? NSKScrollView {
            scrollView.removeObservableSubview(subview)
        }
        super.willRemoveSubview(subview)
    }
}

public class NSKScrollView: UIScrollView {
    public enum HorizontalInset {
        case custom(CGFloat)
        case margin
    }
    private let contentView = NSKContainerScrollView()
    private var bottomConstraint: NSLayoutConstraint?
    private var observableSubviews: [NSKScrollableView] = []
    private let scheduler = Scheduler(delay: 0.3)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        self.contentView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.contentView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.contentView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        let h = self.contentView.heightAnchor.constraint(equalTo: self.heightAnchor)
        h.priority = .defaultLow
        h.isActive = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _addSimpleView(_ view: UIView, inset: HorizontalInset) {
        let topView = self.contentView.subviews.last
        
        view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(view)
        
        switch inset {
        case .custom(let inset):
            view.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: inset).isActive = true
            view.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -inset).isActive = true
        case .margin:
            view.leftAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.rightAnchor).isActive = true
        }
        
        if let bottomConstraint = self.bottomConstraint {
            bottomConstraint.isActive = false
            self.bottomConstraint = nil
        }
        
        if let topView = topView {
            view.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive = true
        } else {
            view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        }
        
        self.bottomConstraint = view.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor)
        self.bottomConstraint?.isActive = true
    }
    
    public func addSimpleView(_ view: UIView, inset: HorizontalInset) {
        self._addSimpleView(view, inset: inset)
        self.setNeedsLayout()
    }
    
    public func addScrollableView(_ view: NSKScrollableView, inset: HorizontalInset) {
        self._addSimpleView(view, inset: inset)
        self.observableSubviews.append(view)
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        view.scrollView.isScrollEnabled = false
        view.scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentSize), options: .old, context: &kScrollContext)
        self.setNeedsLayout()
    }
    
    public func removeAllSubviews(_ subview: UIView) {
        self.removeAllObservableSubviews()
        for sv in self.contentView.subviews {
            sv.removeFromSuperview()
        }
    }
    
    public func removeSubview(_ subview: UIView) {
        // TODO
    }
    
    func removeObservableSubview(_ subview: UIView) {
        if let index = self.observableSubviews.firstIndex(where: { (sv) -> Bool in
            sv === subview
            }) {
            let observable = self.observableSubviews.remove(at: index)
            observable.scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentSize), context: &kScrollContext)
        }
    }
    
    private func removeAllObservableSubviews() {
        for observable in self.observableSubviews {
            observable.scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentSize), context: &kScrollContext)
        }
        self.observableSubviews.removeAll()
    }
    
    deinit {
        self.scheduler.cancel()
        self.removeAllObservableSubviews()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kScrollContext {
            guard let oldSize = change?[.oldKey] as? CGSize, let scrollView = object as? UIScrollView else {
                return
            }
            guard scrollView.contentSize.height != oldSize.height else {
                return
            }
            if let parent = self.observableSubviews.first(where: { (member) -> Bool in
                member.scrollView === scrollView
            }) {
                self.scheduler.schedule(tag: parent.hashValue, action: { [weak scrollView, weak parent] in
                    guard let scrollView = scrollView, let parent = parent else { return }
                    
                    if let constraint = parent.constraints.first(where: { (c) -> Bool in
                        return c.firstAttribute == .height
                    }) {
                        constraint.constant = scrollView.contentSize.height
                    }
                })
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
