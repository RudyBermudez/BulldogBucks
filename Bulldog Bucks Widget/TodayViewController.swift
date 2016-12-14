//
//  TodayViewController.swift
//  Bulldog Bucks Widget
//
//  Created by Rudy Bermudez on 9/26/16.
//
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
	
    // MARK: - Properties
	
	@IBOutlet weak var remainingBdbLabel: UILabel!
	@IBOutlet weak var timeUpdatedLabel: UILabel!
	@IBOutlet weak var errorMessageLabel: UILabel!
	@IBOutlet weak var staticTextLabel: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
    /// Class Instance of ZagwebClient
    let client = ZagwebClient()
    
    /// User's Student ID as a String
    var studentID: String!
    
    /// User's PIN as a String
    var PIN: String!
	
    
    let userDefaults = UserDefaults(suiteName: "group.bdbMeter")!
    
    /// Check UserDefaults to see if `studentID` and `PIN` exist and are not nil
	var loggedIn: Bool = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID") != nil && UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") != nil
    
    /**
     The number of times `ClientError.invalidCredentials` occurs.
     
     - Note: Unfortunately, due to the poor Zagweb website. It is normal for the website to redirect the connection to another url the first time the user connects, for that reason, if there is a saved username and password; the invalidCredentials error will only be shown when there are 2 or more failed attempts.
     */
    var failedAttempts = 0
	
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: self.view.bounds.width, height: 100.0)
        setFontColor()
        if loggedIn {
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
        }
		update()
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
    // MARK: - UI Helper Functions
    
    /**
     If enabled, hides all labels except for `errorMessageLabel` and sets `errorMessageLabel` with message `withText`. Else, hides `errorMessageLabel`
     
     - Note: If `withText` is left blank, default will be "Please Open the App to Login"
     */
    func showErrorMessage(_ enabled: Bool, withText: String = "Please Open the App to Login") {
        errorMessageLabel.text = withText
        errorMessageLabel.isHidden = !enabled
        remainingBdbLabel.isHidden = enabled
        timeUpdatedLabel.isHidden = enabled
        staticTextLabel.isHidden = enabled
    }
	
    /// Updates the `remainingBdbLabel` with the latest data from Zagweb
	func updateRemainderTextLabel() {
		client.getBulldogBucks(withStudentID: studentID, withPIN: PIN).then { (result) -> Void in
            self.failedAttempts = 0
			self.showErrorMessage(false)
			self.remainingBdbLabel.text = result
            self.activityIndicator.stopAnimating()
			let date = NSDate()
            self.userDefaults.set(date, forKey: "timeOfLastUpdate")
			self.timeUpdatedLabel.text = "Updated: \(date.timeAgoInWords)"
			print(result)
			}.catch { (error) in
                if let error = error as? ClientError {
                    switch error {
                    case .invalidCredentials:
                        self.failedAttempts += 1
                        if self.failedAttempts > 2 {
                            self.showErrorMessage(true, withText: "Invalid Credentials")
                            self.activityIndicator.stopAnimating()
                        } else {
                            let deadlineTime = DispatchTime.now() + .seconds(3)
                            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                                self.update()
                            }
                        }
                    default: break
                
                    }
                }
				print(error)
		}
	}
    /// Sets labels `textColor = UIColor.white` if User is using iOS 9 and black if on iOS 10
    func setFontColor() {
        if #available(iOS 9, *) {
            self.staticTextLabel.textColor = UIColor.white
            self.timeUpdatedLabel.textColor = UIColor.white
            self.errorMessageLabel.textColor = UIColor.white
            self.remainingBdbLabel.textColor = UIColor.white
            self.activityIndicator.color = UIColor.white
        }
        if #available(iOS 10, *) {
            self.staticTextLabel.textColor = UIColor.black
            self.timeUpdatedLabel.textColor = UIColor.black
            self.errorMessageLabel.textColor = UIColor.black
            self.remainingBdbLabel.textColor = UIColor.black
            self.activityIndicator.color = UIColor.gray
        }
    }
    
    /// Updates the `timeUpdatedLabel` with the amount of time that has passed since the last update
    func updateTimeOfLastUpdate() {
        if let timeOfLastUpdate = userDefaults.object(forKey: "timeOfLastUpdate") as? NSDate {
            self.timeUpdatedLabel.text = "Updated: \(timeOfLastUpdate.timeAgoInWords)"
        } else {
            self.timeUpdatedLabel.text = "Updated: Never"
        }
    }
	
    /// Launches the Main App only when user taps error message that shows "Please Open the App to Login"
	@IBAction func openMainApp() {
		if !errorMessageLabel.isHidden && errorMessageLabel.text == "Please Open the App to Login" {
			let url = URL(string: "bdb://")!
			extensionContext?.open(url, completionHandler: nil)
		}
	}
	
	
    // MARK: - ZagwebAPI Helpers
    
    /// Checks to see if credentials exist, else calls `self.showErrorMessage(true)`
    func checkCredentials() {
        if let studentID = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID"), let PIN = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") {
            self.studentID = studentID
            self.PIN = PIN
        } else {
            showErrorMessage(true)
        }
    }
	
    /// Essentially the main function of the ViewController.
	func update() {
		if !loggedIn {
			checkCredentials()
			showErrorMessage(true)
            self.userDefaults.set(nil, forKey: "timeOfLastUpdate")
		} else {
			if isConnectedToNetwork() {
                activityIndicator.startAnimating()
				checkCredentials()
				updateRemainderTextLabel()
			} else {
				showErrorMessage(true, withText: "No Active Connection to Internet")
			}
		}
	}
	
    // MARK: - NCWidgetProviding
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        if loggedIn {
            self.updateTimeOfLastUpdate()
        }
		update()
		completionHandler(NCUpdateResult.newData)
	}
	
}
