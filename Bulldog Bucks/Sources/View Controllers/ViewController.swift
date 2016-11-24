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
	@IBOutlet weak var fab: KCFloatingActionButton!
	
	/// Class Instance of ZagwebClient
	let client = ZagwebClient()
    
    /// User's Student ID as a String
	var studentID: String!
    
    /// User's PIN as a String
	var PIN: String!
    
    /**
     The number of times `ClientError.invalidCredentials` occurs. 
     
     - Note: Unfortunately, due to the poor Zagweb website. It is normal for the website to redirect the connection to another url the first time the user connects, for that reason, if there is a saved username and password; the invalidCredentials error will only be shown when there are 2 or more failed attempts.
     */
	var numOfFailedAttmps = 0
	
    /// Check UserDefaults to see if `studentID` and `PIN` exist and are not nil
	var loggedIn: Bool = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID") != nil && UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") != nil
	
	// MARK: - UIViewController
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if loggedIn {
			refresh()
        } else {
            showLoginPage()
        }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initializeButtonItem()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	// MARK: - LoginViewControllerDelegate
    

    /// Set `loggedIn` flag to `true` and dismiss the `loginViewController`
	func didLoginSuccessfully() {
		loggedIn = true
		DispatchQueue.main.async {
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: - UI Helper Functions
	

    /// Initialize the `KCFloatingActionButton` with a logout button and a refresh button
	func initializeButtonItem(){
		let logoutItem = KCFloatingActionButtonItem()
		logoutItem.title = "Logout"
		logoutItem.icon = UIImage(named: "logout")
		logoutItem.buttonColor = UIColor.clear
		logoutItem.backgroundColor = UIColor.clear
		logoutItem.itemBackgroundColor = UIColor.clear
		logoutItem.handler = { _ in self.logout() }
		fab.addItem(item: logoutItem)
		
		
		let refreshItem = KCFloatingActionButtonItem()
		refreshItem.title = "Refresh"
		refreshItem.icon = UIImage(named: "reload")
		refreshItem.buttonColor = UIColor.clear
		refreshItem.backgroundColor = UIColor.clear
		refreshItem.itemBackgroundColor = UIColor.clear
		refreshItem.handler = { _ in self.refresh() }
		fab.addItem(item: refreshItem)
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
		UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "studentID")
		UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "PIN")
		
		self.dollarSignLabel.isHidden = true
		self.staticMessageLabel.isHidden = true
		self.dollarAmountLabel.text = ""
		self.centsLabel.text = ""
		
		let cookieStorage: HTTPCookieStorage = HTTPCookieStorage.shared
		let cookies = cookieStorage.cookies(for: URL(string: "zagweb.gonzaga.edu")!)
		
		if let cookies = cookies {
			for cookie in cookies {
				cookieStorage.deleteCookie(cookie as HTTPCookie)
			}
		}
		
		showLoginPage()
	}
	
    /// Instantiates and shows `LoginViewController`
	func showLoginPage() {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
		vc.delegate = self
		self.show(vc, sender: self)
	}
	
    /// Updates the `dollarAmountLabel` & `centsLabel` with the latest data from Zagweb
	func updateLabels() {
		checkCredentials()
		client.getBulldogBucks(withStudentID: studentID, withPIN: PIN).then { (result) -> Void in
            
            // Get the result, Strip the "$", and then break it up into dollars and cents
			let array = result.replacingOccurrences(of: "$", with: "").components(separatedBy: ".")
            
            self.dollarAmountLabel.text = array[0]
            self.centsLabel.text = array[1]
            
			self.dollarSignLabel.isHidden = false
			self.staticMessageLabel.isHidden = false
            
            // Reset number of failed attempts to 0
			self.numOfFailedAttmps = 0
			
			SwiftSpinner.hide()
            
			}.catch { (error) in
				if let error = error as? ClientError {
					switch error {
					case .invalidCredentials:
						self.numOfFailedAttmps += 1
						if self.numOfFailedAttmps >= 3 {
							let action = UIAlertAction(title: "Logout", style: .default, handler: { (_) in
								self.logout()
							})
							SwiftSpinner.hide()
							showAlert(target: self, title: "Too Many Failed Attempts", message: "It is possible that your PIN has changed. Logout and Try Again", actionList: [action])
						} else if self.numOfFailedAttmps > 1 {
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
	
    /// Checks to see if credentials exist, else calls `self.logout()`
	func checkCredentials() {
		if let studentID = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID"), let PIN = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") {
			self.studentID = studentID
			self.PIN = PIN
		} else {
			logout()
		}
	}
	
}
