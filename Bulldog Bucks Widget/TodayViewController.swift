//
//  TodayViewController.swift
//  Bulldog Bucks Widget
//
//  Created by Rudy Bermudez on 9/26/16.
//
//

import UIKit
import NotificationCenter
import RealmSwift

class TodayViewController: UIViewController, NCWidgetProviding {
	
    // MARK: - Properties
	
	@IBOutlet weak var remainingBdbLabel: UILabel!
	@IBOutlet weak var timeUpdatedLabel: UILabel!
	@IBOutlet weak var errorMessageLabel: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
    /// Class Instance of ZagwebClient
    let client = ZagwebClient()
    
    let keychain = BDBKeychain.phoneKeychain
    
    var realm: Realm!
    
    var balances: Results<Balance> {
        get {
            
            return realm.objects(Balance.self)
        }
    }
	
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Realm DB
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        realm = try! Realm()
        
        preferredContentSize = CGSize(width: self.view.bounds.width, height: 100.0)
        setFontColor()
        if keychain.isLoggedIn() {
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
        }
        
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
    }
	
    /// Updates the `remainingBdbLabel` with the latest data from Zagweb
    func updateRemainderTextLabel() {
        guard let credentials = keychain.getCredentials() else {
            self.showErrorMessage(true)
            return
        }
        client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (result, _, _) -> Void in
            self.showErrorMessage(false)
            
            self.remainingBdbLabel.attributedText = self.formatAmountLabel(withResult: result)
            
            self.activityIndicator.stopAnimating()
            let date = NSDate()
            let newBalance = Balance()
            newBalance.amount = result
            newBalance.date = date as Date
            try! self.realm.write({
                self.realm.add(newBalance)
     
            })
            
        
            self.timeUpdatedLabel.text = "Updated: \(date.timeAgoInWords)"
            }.catch { (error) in
                if let error = error as? ClientError {
                    switch error {
                    case .invalidCredentials:
                        self.showErrorMessage(true, withText: "Invalid Credentials")
                        self.activityIndicator.stopAnimating()
                    default:
                        self.showErrorMessage(true, withText: "An error occured while trying to update your balance. Please try again.")
                        self.activityIndicator.stopAnimating()
                        
                    }
                } else {
                    self.showErrorMessage(true, withText: "An error occured while trying to update your balance")
                    self.activityIndicator.stopAnimating()
                }
                print(error)
        }
        
    }
    /// Sets labels `textColor = UIColor.white` if User is using iOS 9 and black if on iOS 10
    func setFontColor() {
        if #available(iOS 9, *) {
            self.timeUpdatedLabel.textColor = UIColor.white
            self.errorMessageLabel.textColor = UIColor.white
            self.remainingBdbLabel.textColor = UIColor.white
            self.activityIndicator.color = UIColor.white
        }
        if #available(iOS 10, *) {
            self.timeUpdatedLabel.textColor = UIColor.black
            self.errorMessageLabel.textColor = UIColor.black
            self.remainingBdbLabel.textColor = UIColor.black
            self.activityIndicator.color = UIColor.gray
        }
    }
    
    func formatAmountLabel(withResult result: String) -> NSMutableAttributedString {
        
        let dollarSignAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 30, weight: UIFontWeightRegular)]
        let amountAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 50, weight: UIFontWeightRegular)]
        
        
        
        let dollarSignPart = NSMutableAttributedString(string: "$ ", attributes: dollarSignAttributes)
        let amountPart = NSMutableAttributedString(string: result, attributes: amountAttributes)
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(dollarSignPart)
        attributedString.append(amountPart)
        
        return attributedString
    }
    
    /// Updates the `timeUpdatedLabel` with the amount of time that has passed since the last update
    func updateTimeOfLastUpdate() {
        
        if let timeOfLastUpdate = balances.last?.date as NSDate? {
            self.timeUpdatedLabel.text = "Updated: \(timeOfLastUpdate.timeAgoInWords)"
        } else {
            self.timeUpdatedLabel.text = "Updated: Never"
        }
    }
	
    /// Launches the Main App only when user taps error message that shows "Please Open the App to Login"
	@IBAction func openMainApp() {
        let url = URL(string: "bdb://")!
        extensionContext?.open(url, completionHandler: nil)
	}
	
	
    // MARK: - ZagwebAPI Helpers
	
    /// Essentially the main function of the ViewController.
	func update() {
		if keychain.isLoggedIn() {
            if isConnectedToNetwork() {
                activityIndicator.startAnimating()
                updateRemainderTextLabel()
            } else {
                showErrorMessage(true, withText: "No Active Connection to Internet")
            }
		} else {
			showErrorMessage(true)
		}
	}
	
    // MARK: - NCWidgetProviding
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        update()
        completionHandler(.newData)
    }
	
}
