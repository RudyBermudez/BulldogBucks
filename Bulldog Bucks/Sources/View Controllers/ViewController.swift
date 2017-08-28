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
import RealmSwift

class ViewController: UIViewController, LoginViewControllerDelegate {
	
	// MARK: - Properties
	
	@IBOutlet weak var dollarSignLabel: UILabel!
	@IBOutlet weak var dollarAmountLabel: UILabel!
	@IBOutlet weak var centsLabel: UILabel!
	@IBOutlet weak var staticMessageLabel: UILabel!
	@IBOutlet weak var dailyBalanceLabel: UILabel!
	@IBOutlet weak var fab: KCFloatingActionButton!
	@IBOutlet weak var errorMessageLabel: UILabel!
    
    
    /// Last Day of the Current of Semester in UNIX time
    /// This is used to calculate the amount of money remaining per week
    /// Updated for the 2017 - 2018 Academic School year
    let lastDayOfSemester = Date(timeIntervalSince1970: 1526169600)
	
	/// Class Instance of ZagwebClient
	private let client = ZagwebClient()
    
    private let keychain = BDBKeychain.phoneKeychain
    
    var realm: Realm!
    
    var realmToken: NotificationToken!
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    var balances: Results<Balance> {
        get {
            return realm.objects(Balance.self)
        }
    }
	
	// MARK: - UIViewController
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if keychain.isLoggedIn() {
            self.notificationCenter.post(name: Notification.Name(UserLoggedInNotificaiton), object: nil)
			refresh()
        } else {
            logout()
        }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initializeButtonItem()
        realm = try! Realm()
        realmToken = realm.addNotificationBlock { (note, realm2) in
            print(self.realm.objects(Balance.self))
        }
        print(Realm.Configuration.defaultConfiguration.fileURL!)
	}
	
    
	// MARK: - LoginViewControllerDelegate
    

    /// Set `loggedIn` flag to `true` and dismiss the `loginViewController`
	func didLoginSuccessfully() {
		DispatchQueue.main.async {
			self.dismiss(animated: true, completion: nil)
            self.notificationCenter.post(name: Notification.Name(UserLoggedInNotificaiton), object: nil)
		}
	}
	
	// MARK: - UI Helper Functions
	

    /// Initialize the `KCFloatingActionButton` with a logout button and a refresh button
	private func initializeButtonItem(){
        
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
	
    /// Presents Custom UIWebView
    private func showWebView() {
        guard let credentials = keychain.getCredentials() else {
            self.logout()
            return
        }
        
        let webVC = storyboard?.instantiateViewController(withIdentifier: WebViewController.storyboardIdentifier) as! WebViewController
        webVC.logoutFunc = { webView in
            webView.dismiss(animated: true, completion: nil)
            let _ = self.client.logout()
        }
        self.present(webVC, animated: true, completion: nil)
        
        client.authenticate(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (_) -> Void in
            DispatchQueue.main.async {
                webVC.loadWebView()
            }
            }.catch { (error) in
                DispatchQueue.main.async {
                    webVC.closeWebView()
                    showAlert(target: self, title: "Error", message: "We had some trouble authenticating while opening the WebView.\nPlease Try Again.")
                }
                
        }
        
    }
    
    /// Refresh data if active internet connection is present
	private func refresh() {
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
	private func logout() {
        
        // Check to see if a username is stored in UserDefaults, if it is,
        // Set the value to be nil, set the PIN to be nil if it exists,
        // and finally delete keychain data for the user if it exists
		
		self.dollarSignLabel.isHidden = true
		self.staticMessageLabel.isHidden = true
        self.dailyBalanceLabel.isHidden = true
		self.errorMessageLabel.isHidden = true
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
		
        client.logout().then { (_) -> Void in
            let logoutSuccess = self.keychain.deleteCredentials()
            if logoutSuccess {
                DispatchQueue.main.async {
                    self.showLoginPage(animated: true)
                    self.notificationCenter.post(name: Notification.Name(UserLoggedOutNotification), object: nil)
                    
                    // Delete all objects from the realm
                    try! self.realm.write {
                        self.realm.deleteAll()
                    }
                }
                
            } else {
                // This should never happen, but it is good to handle the error just in case.
                showAlert(target: self, title: "Houston we have a problem!", message: "Logout failed. Please try again.")
            }
        }.catch { (error) in
            showAlert(target: self, title: "Houston we have a problem!", message: "Logout failed. Please try again.")
        }
        
        
        
	}
	
    /// Instantiates and shows `LoginViewController`
    private func showLoginPage(animated: Bool) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
		vc.delegate = self
        self.present(vc, animated: animated, completion: nil)
	}
	
    /// Updates the `dollarAmountLabel` & `centsLabel` with the latest data from Zagweb
	private func updateLabels() {
        guard let credentials = keychain.getCredentials() else {
            self.logout()
            return
        }
		client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (result) -> Void in
            
            let date = Date()
            let newBalance = Balance()
            newBalance.amount = result
            newBalance.date = date
            
            DispatchQueue.main.async {
                try! self.realm.write {
                    self.realm.add(newBalance)
                }
            }
            
            
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
			
			self.errorMessageLabel.isHidden = true
			self.dollarSignLabel.isHidden = false
			self.staticMessageLabel.isHidden = false
            
			
			SwiftSpinner.hide()
            
			}.catch { (error) in
                self.errorMessageLabel.isHidden = false
				if let error = error as? ClientError {
					switch error {
					case .invalidCredentials:
                        SwiftSpinner.hide()
                        let action = UIAlertAction(title: "Logout", style: .default){ (_) in
                            self.logout()
                        }
                        showAlert(target: self, title: "Hold Up!", message: "It looks like you have changed your password. Logout and Try Again", actionList: [action])
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
