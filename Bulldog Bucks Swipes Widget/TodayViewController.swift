//
//  TodayViewController.swift
//  Bulldog Bucks Swipes Widget
//
//  Created by Rudy Bermudez on 9/5/17.
//
//

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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /// Class Instance of ZagwebClient
    let client = ZagwebClient()
    
    let keychain = BDBKeychain.phoneKeychain
    
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func downloadData() {
        
        guard let credentials = keychain.getCredentials() else {
            self.showErrorMessage(true)
            return
        }
        
        client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (bucks, _, _, swipes) -> Void in
            self.showErrorMessage(false)
            
            let date = NSDate()
            let newDataSet = ZagwebDataSet(bucksRemaining: bucks, swipesRemaining: swipes, date: date as Date)
            ZagwebDataSetManager.add(dataSet: newDataSet)
            
            self.updateRemainderTextLabel()
            
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
                }
        }
    }
    
    /// Updates the `remainingBdbLabel` with the latest data from Zagweb
    func updateRemainderTextLabel() {
        
        
        guard let lastDataSet = ZagwebDataSetManager.dataSets.last else {
            downloadData()
            return
        }
        
        // Check to see if it has been 5 minutes from the last update,
        if NSDate().minutes(fromDate: lastDataSet.date as NSDate) > 5 {
            downloadData()
        } else {
            self.activityIndicator.stopAnimating()
            self.timeUpdatedLabel.text = "Updated: \((lastDataSet.date as NSDate).timeAgoInWords)"
            self.remainingBdbLabel.text = "\(lastDataSet.swipesRemaining) Swipes"
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
    
    
    /// Updates the `timeUpdatedLabel` with the amount of time that has passed since the last update
    func updateTimeOfLastUpdate() {
        
        if let timeOfLastUpdate = ZagwebDataSetManager.dataSets.last?.date as NSDate? {
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
