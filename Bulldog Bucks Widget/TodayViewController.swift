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
	
    /// Class Instance of ZagwebClient
    let client = ZagwebClient()
    
    /// User's Student ID as a String
    var studentID: String!
    
    /// User's PIN as a String
    var PIN: String!
	
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
        setFontColor()
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
			let date = NSDate()
			self.timeUpdatedLabel.text = "Updated: \(date.timeAgoInWords)"
			print(result)
			}.catch { (error) in
                if let error = error as? ClientError {
                    switch error {
                    case .invalidCredentials:
                        self.failedAttempts += 1
                        if self.failedAttempts > 2 {
                            self.showErrorMessage(true, withText: "Invalid Credentials")
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
        }
        if #available(iOS 10, *) {
            self.staticTextLabel.textColor = UIColor.black
            self.timeUpdatedLabel.textColor = UIColor.black
            self.errorMessageLabel.textColor = UIColor.black
            self.remainingBdbLabel.textColor = UIColor.black
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
		} else {
			if isConnectedToNetwork() {
				checkCredentials()
				updateRemainderTextLabel()
			} else {
				showErrorMessage(true, withText: "No Active Connection to Internet")
			}
		}
	}
	
    // MARK: - NCWidgetProviding
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
		update()
		completionHandler(NCUpdateResult.newData)
	}
	
}
