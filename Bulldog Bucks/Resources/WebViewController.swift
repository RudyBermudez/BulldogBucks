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

    public static let storyboardIdentifier: String = "webView"
    
    var logoutFunc: WebViewAction?
    
	@IBOutlet weak var webView: UIWebView!
	@IBOutlet weak var backBarButton: UIBarButtonItem!
	@IBOutlet weak var forwardBarButton: UIBarButtonItem!
	@IBOutlet weak var closeNavButton: UIBarButtonItem!
	@IBOutlet weak var refreshNavButton: UIBarButtonItem!
	
	
    override func viewWillAppear(_ animated: Bool) {
		closeNavButton.action = #selector(self.closeWebView)
        refreshNavButton.action = #selector(self.reloadWebPage)
        backBarButton.action = #selector(self.goBack)
        forwardBarButton.action = #selector(self.goForward)
        self.webView.delegate = self
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
 
    
    func loadWebView() {
        let request = URLRequest(url: URL(string: "https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions")!)
        webView.loadRequest(request)
    }
    
    
    func reloadWebPage() {
        webView.reload()
    }
   
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    func closeWebView() {
        logoutFunc?(self)
    }

}

extension WebViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if webView.canGoBack {
            backBarButton.isEnabled = true
        } else {
            backBarButton.isEnabled = false
        }
        
        if webView.canGoForward {
            forwardBarButton.isEnabled = true
        } else {
            forwardBarButton.isEnabled = false
        }
    }
    
}
