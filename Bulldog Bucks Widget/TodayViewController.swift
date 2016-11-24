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
	
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
			self.showErrorMessage(false)
			self.remainingBdbLabel.text = result
			let date = NSDate()
			self.timeUpdatedLabel.text = "Updated: \(date.timeAgoInWords)"
			print(result)
			}.catch { (error) in
				print(error)
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
				let deadlineTime = DispatchTime.now() + .seconds(3)
				DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
					self.updateRemainderTextLabel()
				}
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
