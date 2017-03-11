//
//  WebViewController.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 12/12/16.
//
//

import UIKit

typealias WebViewAction = ((WebViewController) -> Void)

/**
 WebViewController is a ViewController than contains a `UINavigationBar` and a `UIWebView` that loads `https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions`
*/
class WebViewController: UIViewController {

    
    var logoutFunc: WebViewAction?
    
    var webView = UIWebView()
    
    override func viewWillAppear(_ animated: Bool) {
        
        let navigationBarHeight = CGFloat(44 + UIApplication.shared.statusBarFrame.size.height)
        let frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: navigationBarHeight)
        
         // Setup NavBar and NavItem
        let bar = UINavigationBar(frame: frame)
        let navItem =  UINavigationItem(title: "Zagweb")
        
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeWebView))
        navItem.leftBarButtonItem = doneItem
        bar.items = [navItem]
        
        view.addSubview(bar)
        
        // Setup UIWebView
        webView = UIWebView(frame: CGRect(x: 0.0, y: navigationBarHeight, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - navigationBarHeight))
        view.addSubview(webView)

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func loadWebView() {
        let request = URLRequest(url: URL(string: "https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions")!)
        webView.loadRequest(request)
    }

    
    func closeWebView() {
        logoutFunc?(self)
    }

}
