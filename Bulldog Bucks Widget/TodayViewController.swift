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
	
	@IBOutlet weak var remainderTextField: UILabel!
	@IBOutlet weak var timeUpdatedLabel: UILabel!
	@IBOutlet weak var errorMessageLabel: UILabel!
	@IBOutlet weak var staticTextLabel: UILabel!
	
	let client = APIClient()
	
	var loggedIn: Bool = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "username") != nil && UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "password") != nil
	
	var username: String!
	var password: String!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		update()
	}
	
	func showErrorMessage(_ enabled: Bool, withText: String = "Please Open the App to Login") {
		errorMessageLabel.text = withText
		errorMessageLabel.isHidden = !enabled
		remainderTextField.isHidden = enabled
		timeUpdatedLabel.isHidden = enabled
		staticTextLabel.isHidden = enabled
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func checkCredentials() {
		if let username = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "username"), let password = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "password") {
			self.username = username
			self.password = password
			print(username,password)
		} else {
			showErrorMessage(true)
			print("couldnt get user and pass")
		}
	}
	
	func updateRemainderTextLabel() {
		client.getBulldogBucks(withStudentID: username, withPIN: password).then { (result) -> Void in
			self.showErrorMessage(false)
			self.remainderTextField.text = result
			let date = NSDate()
			self.timeUpdatedLabel.text = "Updated: \(date.timeAgoInWords)"
			print(result)
			}.catch { (error) in
				print(error)
		}
	}
	
	func update() {
		if !loggedIn {
			checkCredentials()
			showErrorMessage(true)
		} else {
			if Reachability.isConnectedToNetwork() {
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
	
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
		update()
		completionHandler(NCUpdateResult.newData)
	}
	
}
