//
//  ContainerScrollView.swift
//  ContainerScrollView
//
//  Created by NSSimpleApps on 21/12/2018.
//  Copyright © 2018 NSSimpleApps. All rights reserved.
//

import UIKit
import WebKit

public extension UIView {
    func parentView<T: UIView>(ofType type: T.Type) -> T? {
        var result = self.superview
        while true {
            if let sv = result {
                if let parentView = sv as? T {
                    return parentView
                } else {
                    result = sv.superview
                }
            } else {
                break
            }
        }
        return nil
    }
}
public extension UIScrollView {
    var totalContentHeight: CGFloat {
        let contentInset = self.contentInset
        return self.contentSize.height + contentInset.top + contentInset.bottom
    }
}

public class NSKScrollView: UIScrollView {
    public class ScrollViewContainer: UIView {
        public let scrollableView: ScrollView
        private let keyValueObservation: NSKeyValueObservation
        
        public init(scrollableView: ScrollView) {
            self.scrollableView = scrollableView
            let scrollView = scrollableView.scrollView
            scrollView.isScrollEnabled = false
            self.keyValueObservation = scrollView.observe(\UIScrollView.contentSize) { (sender, _) in
                guard let parent = sender.parentView(ofType: ScrollViewContainer.self) else { return }
                
                DispatchQueue.main.async { [weak parent] in
                    parent?.invalidateIntrinsicContentSize()
                }
            }
            super.init(frame: .zero)
            
            self.preservesSuperviewLayoutMargins = true
            let selfView = scrollableView.selfView
            self.addSubview(selfView)
            selfView.translatesAutoresizingMaskIntoConstraints = false
            selfView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            selfView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            selfView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            selfView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override public var intrinsicContentSize: CGSize {
            self.scrollableView.selfView.layoutIfNeeded()
            let scrollView = self.scrollableView.scrollView
            let size = scrollView.intrinsicContentSize
            let height = max(0, scrollView.totalContentHeight)
            return CGSize(width: size.width, height: height)
        }
        deinit {
            self.keyValueObservation.invalidate()
        }
        
        public override func willRemoveSubview(_ subview: UIView) {
            super.willRemoveSubview(subview)
            
            if self.scrollableView.selfView == subview {
                self.keyValueObservation.invalidate()
                self.removeFromSuperview()
            }
        }
    }
    public enum HorizontalInset {
        case custom(CGFloat)
        case margin
    }

    public enum ScrollView {
        case scrollView(UIScrollView)
        case webView(WKWebView)
        case collectionViewWrapper(UIView, UIScrollView)
        
        public init(scrollView: UIScrollView) {
            self = .scrollView(scrollView)
        }
        public init(webView: WKWebView) {
            self = .webView(webView)
        }
        public init?(collectionViewWrapper: UIView) {
            if let scrollView = collectionViewWrapper.subviews.first(where: { (sv) -> Bool in
                return sv is UIScrollView
            }) {
                self = .collectionViewWrapper(collectionViewWrapper, scrollView as! UIScrollView)
            } else {
                return nil
            }
        }
        
        public var scrollView: UIScrollView {
            switch self {
            case .scrollView(let scrollView):
                return scrollView
            case .webView(let webView):
                return webView.scrollView
            case .collectionViewWrapper(_, let scrollView):
                return scrollView
            }
        }
        public var selfView: UIView {
            switch self {
            case .scrollView(let scrollView):
                return scrollView
            case .webView(let webView):
                return webView
            case .collectionViewWrapper(let wrapper, _):
                return wrapper
            }
        }
    }
    private let contentView = UIStackView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.preservesSuperviewLayoutMargins = true
        self.contentView.axis = .vertical
        self.contentView.alignment = .center
        self.contentView.isLayoutMarginsRelativeArrangement = true
        self.contentView.preservesSuperviewLayoutMargins = true
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        self.contentView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.contentView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.contentView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        let h = self.contentView.heightAnchor.constraint(equalTo: self.heightAnchor)
        h.priority = .defaultLow - 1
        h.isActive = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutMargins.top = 0
        self.layoutMargins.bottom = 0
    }
    
    private func configureInsets(view: UIView, inset: HorizontalInset) {
        guard let superview = view.superview else { return }
        
        switch inset {
        case .custom(let custom):
            view.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: custom).isActive = true
            view.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -custom).isActive = true
        case .margin:
            view.leftAnchor.constraint(equalTo: superview.layoutMarginsGuide.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: superview.layoutMarginsGuide.rightAnchor).isActive = true
        }
    }
    
    public func addEmptySpace(space: CGFloat) {
        let emptySpace = UIView()
        emptySpace.heightAnchor.constraint(equalToConstant: space).isActive = true
        self._addSimpleView(emptySpace, inset: .custom(0))
    }
    public func _addSimpleView(_ view: UIView, inset: HorizontalInset) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addArrangedSubview(view)
        self.configureInsets(view: view, inset: inset)
        self.updateConstraints()
    }
    
    public func addSimpleView(_ view: UIView, inset: HorizontalInset, topSpace: CGFloat = 0) {
        if topSpace > 0 {
            self.addEmptySpace(space: topSpace)
        }
        self._addSimpleView(view, inset: inset)
    }
    
    private func prepareScrollableView(_ scrollableView: ScrollView) -> UIView {
        return ScrollViewContainer(scrollableView: scrollableView)
    }
    public func addScrollableView(_ scrollableView: ScrollView, inset: HorizontalInset, topSpace: CGFloat = 0) {
        let view = self.prepareScrollableView(scrollableView)
        self.addSimpleView(view, inset: inset, topSpace: topSpace)
    }
    
    public func insertSimpleView(_ view: UIView, inset: HorizontalInset, at index: Int) {
        guard index >= 0 && index <= self.contentView.arrangedSubviews.count else {
            return
        }
        self.contentView.insertArrangedSubview(view, at: index)
        self.configureInsets(view: view, inset: inset)
        self.updateConstraints()
    }
    
    public func insertScrollableView(_ scrollableView: ScrollView, inset: HorizontalInset, at index: Int) {
        guard index >= 0 && index <= self.contentView.arrangedSubviews.count else {
            return
        }
        let view = self.prepareScrollableView(scrollableView)
        self.insertSimpleView(view, inset: inset, at: index)
    }
    public var managedSubviews: [UIView] {
        return self.contentView.arrangedSubviews.map { (arrangedSubview) -> UIView in
            if let scrollViewContainer = arrangedSubview as? ScrollViewContainer {
                return scrollViewContainer.scrollableView.selfView
            } else {
                return arrangedSubview
            }
        }
    }
    public func removeAllManagedSubviews() {
        let arrangedSubviews = self.contentView.arrangedSubviews
        for arrangedSubview in arrangedSubviews {
            self.contentView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }
}
