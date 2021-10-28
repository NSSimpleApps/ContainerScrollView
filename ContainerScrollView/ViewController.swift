//
//  ViewController.swift
//  ContainerScrollView
//
//  Created by NSSimpleApps on 22/12/2018.
//  Copyright © 2018 NSSimpleApps. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        let container = NSKScrollView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(container)
        container.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        let label1 = UILabel()
        label1.text = "Fixed size Fixed size Fixed size Fixed size Fixed size Fixed size Fixed size"
        label1.numberOfLines = 0
        label1.backgroundColor = .red
        container.addSimpleView(label1, inset: .custom(20))
        
        let label2 = UILabel()
        label2.text = "Layout margin Layout margin Layout margin Layout margin Layout margin Layout margin Layout margin"
        label2.numberOfLines = 0
        label2.backgroundColor = .blue
        container.addSimpleView(label2, inset: .margin)
        
        let webView = WebViewBuilder.webView
        container.addScrollableView(.webView(webView), inset: .custom(0))
        
        
        let tvc1 = TableViewContoller(tag: 1)
        tvc1.view.backgroundColor = .yellow
        container.addScrollableView(.scrollView(tvc1.tableView), inset: .custom(0))
        
        self.addChild(tvc1)
        tvc1.didMove(toParent: self)
        
        let tvc2 = TableViewContoller(tag: 2)
        container.addScrollableView(.scrollView(tvc2.tableView), inset: .custom(0))
        
        self.addChild(tvc2)
        tvc2.didMove(toParent: self)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Top", style: .plain, target: self,
                                                                 action: #selector(self.topInsertAction(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Bottom", style: .plain, target: self,
                                                                action: #selector(self.bottomInsertAction(_:)))
        
        let string = try! String(contentsOf: Bundle.main.url(forResource: "html", withExtension: "html")!)
        webView.loadHTMLString(string, baseURL: nil)
    }
    
    @objc func topInsertAction(_ sender: UIBarButtonItem) {
        (self.children[0] as! TableViewContoller).insert()
    }
    @objc func bottomInsertAction(_ sender: UIBarButtonItem) {
        (self.children[1] as! TableViewContoller).insert()
    }
}

class TableViewContoller: UITableViewController {
    let tag: Int
    init(tag: Int) {
        self.tag = tag
        super.init(style: .grouped)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var n = 5
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.n
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "tag: \(self.tag), row: \(indexPath.row),"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.n -= 1
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func insert() {
        self.tableView.beginUpdates()
        let oldCount = self.n
        self.n += 1
        self.tableView.insertRows(at: [IndexPath(row: oldCount, section: 0)], with: .automatic)
        self.tableView.endUpdates()
    }
}


