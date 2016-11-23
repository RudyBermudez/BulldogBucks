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
	
	
	let client = APIClient()
	var username: String!
	var password: String!
	var loginErrors = 0
	
	var loggedIn: Bool = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "username") != nil && UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "password") != nil
	
	// MARK: - UIViewController
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if !loggedIn {
			showLoginPage()
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if loggedIn {
			refresh()
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
	func didLoginSuccessfully() {
		loggedIn = true
		DispatchQueue.main.async {
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: - UI Helper Functions
	
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
	
	
	func refresh() {
		if Reachability.isConnectedToNetwork() {
			SwiftSpinner.show("Getting Fresh Data...").addTapHandler({ 
				SwiftSpinner.hide()
			}, subtitle: "Tap to Cancel")
			
			updateRemainderTextLabel()
		} else {
			showAlert(target: self, title: "No Active Connection to Internet", message: "Please connect to the internet and try again")
		}
	}
	
	func logout() {
		UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "username")
		UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "password")
		
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
	
	func showLoginPage() {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
		vc.delegate = self
		self.show(vc, sender: self)
	}
	
	func updateRemainderTextLabel() {
		checkCredentials()
		client.getBulldogBucks(withStudentID: username, withPIN: password).then { (result) -> Void in
			let array = result.replacingOccurrences(of: "$", with: "").components(separatedBy: ".")
			self.dollarSignLabel.isHidden = false
			self.staticMessageLabel.isHidden = false
			self.loginErrors = 0
			self.dollarAmountLabel.text = array[0]
			self.centsLabel.text = array[1]
			SwiftSpinner.hide()
			}.catch { (error) in
				if let error = error as? ClientError {
					switch error {
					case .invalidCredentials:
						self.loginErrors += 1
						if self.loginErrors >= 3 {
							let action = UIAlertAction(title: "Logout", style: .default, handler: { (_) in
								self.logout()
							})
							SwiftSpinner.hide()
							showAlert(target: self, title: "Too Many Failed Attempts", message: "It is possible that your password has changed. Logout and Try Again", actionList: [action])
						} else if self.loginErrors > 1 {
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
	
	func checkCredentials() {
		if let username = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "username"), let password = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "password") {
			self.username = username
			self.password = password
		} else {
			logout()
		}
	}
	
}
