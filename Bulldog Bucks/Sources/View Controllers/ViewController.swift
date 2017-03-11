//
//  ViewController.swift
//  Bulldog Bucks Meter
//
//  Created by Rudy Bermudez on 10/1/16.
//
//

import UIKit
import Kanna
import SwiftSpinner
import KCFloatingActionButton

class ViewController: UIViewController, LoginViewControllerDelegate {
	
	// MARK: - Properties
	
	@IBOutlet weak var dollarSignLabel: UILabel!
	@IBOutlet weak var dollarAmountLabel: UILabel!
	@IBOutlet weak var centsLabel: UILabel!
	@IBOutlet weak var staticMessageLabel: UILabel!
	@IBOutlet weak var dailyBalanceLabel: UILabel!
	@IBOutlet weak var fab: KCFloatingActionButton!
    
    
    /// Last Day of the Current of Semester in UNIX time
    /// This is used to calculate the amount of money remaining per week
    let lastDayOfSemester = Date(timeIntervalSince1970: 1494720000)
	
	/// Class Instance of ZagwebClient
	let client = ZagwebClient()
    
    
    /**
     The number of times `ClientError.invalidCredentials` occurs. 
     
     - Note: Unfortunately, due to the poor Zagweb website. It is normal for the website to redirect the connection to another url the first time the user connects, for that reason, if there is a saved username and password; the invalidCredentials error will only be shown when there are 2 or more failed attempts.
     */
	var failedAttempts = 0
	
	
	// MARK: - UIViewController
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if Authentication.isLoggedIn() {
			refresh()
        } else {
            logout()
        }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initializeButtonItem()
	}
	
    
	// MARK: - LoginViewControllerDelegate
    

    /// Set `loggedIn` flag to `true` and dismiss the `loginViewController`
	func didLoginSuccessfully() {
		DispatchQueue.main.async {
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: - UI Helper Functions
	

    /// Initialize the `KCFloatingActionButton` with a logout button and a refresh button
	func initializeButtonItem(){
        
        // Logout Button
		let logoutItem = KCFloatingActionButtonItem()
		logoutItem.title = "Logout"
		logoutItem.icon = UIImage(named: "logout")
		logoutItem.buttonColor = UIColor.clear
		logoutItem.backgroundColor = UIColor.clear
		logoutItem.itemBackgroundColor = UIColor.clear
		logoutItem.handler = { _ in self.logout() }
		fab.addItem(item: logoutItem)
		
        // Open in WebViewButton
        let webviewItem = KCFloatingActionButtonItem()
        webviewItem.title = "View on Web"
        webviewItem.icon = UIImage(named: "openInBrowser")
        webviewItem.buttonColor = UIColor.clear
        webviewItem.backgroundColor = UIColor.clear
        webviewItem.itemBackgroundColor = UIColor.clear
        webviewItem.handler = { _ in self.showWebView() }
        fab.addItem(item: webviewItem)
        
        // Refresh Button
		let refreshItem = KCFloatingActionButtonItem()
		refreshItem.title = "Refresh"
		refreshItem.icon = UIImage(named: "reload")
		refreshItem.buttonColor = UIColor.clear
		refreshItem.backgroundColor = UIColor.clear
		refreshItem.itemBackgroundColor = UIColor.clear
		refreshItem.handler = { _ in self.refresh() }
		fab.addItem(item: refreshItem)
        
	}
	
    func showWebView() {
        self.present(WebViewController(), animated: true, completion: nil)
    }
	
    /// Refresh data if active internet connection is present
	func refresh() {
		if isConnectedToNetwork() {
			SwiftSpinner.show("Getting Fresh Data...").addTapHandler({ 
				SwiftSpinner.hide()
			}, subtitle: "Tap to Cancel")
			updateLabels()
		} else {
			showAlert(target: self, title: "No Active Connection to Internet", message: "Please connect to the internet and try again")
		}
	}
	
    
    /// Logs out the user. Deletes data from UserDefaults, deletes cookies, and shows `LoginViewController`
	func logout() {
        
        // Check to see if a username is stored in UserDefaults, if it is,
        // Set the value to be nil, set the PIN to be nil if it exists,
        // and finally delete keychain data for the user if it exists
		
		self.dollarSignLabel.isHidden = true
		self.staticMessageLabel.isHidden = true
        self.dailyBalanceLabel.isHidden = true
		self.dollarAmountLabel.text = ""
		self.centsLabel.text = ""
        self.dailyBalanceLabel.text = ""
		
		let cookieStorage: HTTPCookieStorage = HTTPCookieStorage.shared
		let cookies = cookieStorage.cookies(for: URL(string: "zagweb.gonzaga.edu")!)
		
		if let cookies = cookies {
			for cookie in cookies {
				cookieStorage.deleteCookie(cookie as HTTPCookie)
			}
		}
		
        let logoutSuccess = Authentication.deleteCredentials()
        if logoutSuccess {
            showLoginPage(animated: true)
        } else {
            // This should never happen, but it is good to handle the error just in case.
            showAlert(target: self, title: "Houston we have a problem!", message: "Logout failed. Please try again.")
        }
        
        
	}
	
    /// Instantiates and shows `LoginViewController`
    func showLoginPage(animated: Bool) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
		vc.delegate = self
        self.present(vc, animated: animated, completion: nil)
	}
	
    /// Updates the `dollarAmountLabel` & `centsLabel` with the latest data from Zagweb
	func updateLabels() {
        guard let credentials = Authentication.getCredentials() else {
            self.logout()
            return
        }
		client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (result) -> Void in
            
            // Get the result and then break it up into dollars and cents
			let array = result.components(separatedBy: ".")
            
            self.dollarAmountLabel.text = array[0]
            self.centsLabel.text = array[1]
            
            let currentBalance = Double(result)!
            let weeksUntilEndOfSchoolYear = NSDate().weeks(to: self.lastDayOfSemester)
            if weeksUntilEndOfSchoolYear > 0 {
                let dailyBalance = currentBalance / Double(weeksUntilEndOfSchoolYear)
                self.dailyBalanceLabel.text = String(format: "That's $%.2f left per week", dailyBalance)
                self.dailyBalanceLabel.isHidden = false
            }
			
			
			self.dollarSignLabel.isHidden = false
			self.staticMessageLabel.isHidden = false
            
            // Reset number of failed attempts to 0
			self.failedAttempts = 0
			
			SwiftSpinner.hide()
            
			}.catch { (error) in
				if let error = error as? ClientError {
					switch error {
					case .invalidCredentials:
						self.failedAttempts += 1
						if self.failedAttempts >= 3 {
							let action = UIAlertAction(title: "Logout", style: .default, handler: { (_) in
								self.logout()
							})
							SwiftSpinner.hide()
							showAlert(target: self, title: "Too Many Failed Attempts", message: "It is possible that your PIN has changed. Logout and Try Again", actionList: [action])
						} else if self.failedAttempts > 1 {
							SwiftSpinner.hide()
							showAlert(target: self, title: "Error", message: error.domain())
						} else {
							self.refresh()
						}
					default:
						SwiftSpinner.hide()
						showAlert(target: self, title: "Error", message: error.domain())
					}
				} else {
					SwiftSpinner.hide()
					showAlert(target: self, title: "Error", message: error.localizedDescription)
				}
				
		}
	}
	
}
