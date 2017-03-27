//
//  InterfaceController.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

	@IBOutlet var headerLabel: WKInterfaceLabel!
	@IBOutlet var amountLabel: WKInterfaceLabel!
	@IBOutlet var errorLabel: WKInterfaceLabel!
	@IBOutlet var footerLabel: WKInterfaceLabel!
    @IBOutlet var loadingGroup: WKInterfaceGroup!
	@IBOutlet var detailGroup: WKInterfaceGroup!
	@IBOutlet var errorGroup: WKInterfaceGroup!
	
	@IBAction func reloadButton() {
		updateDisplay()
	}
	
	let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    let userDefaults = UserDefaults.standard
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		
    }
    
    override func didAppear() {
        
        // Check to see if there is a balance stored in memory, if it cannot be found, update the display with new data
        guard let timeOfLastUpdate = userDefaults.object(forKey: "timeOfLastUpdate") as? NSDate, let lastBalance = userDefaults.string(forKey: "lastBalance") else {
            updateDisplay()
            return
        }
        
        
        // Check to see if it has been 60 minutes from the last update,
        if NSDate().minutes(fromDate: timeOfLastUpdate) > 60 {
            // If it has been, then update
            updateDisplay()
        } else {
            // If not, update the label with the last balance
            
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
            amountLabel.setText("$\(lastBalance)")
            self.detailGroup.setHidden(false)
        }
    }
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateDisplay() {
        DispatchQueue.main.async {
            self.errorGroup.setHidden(true)
            self.detailGroup.setHidden(true)
            self.loadingGroup.setHidden(false)
            if let credentials = self.keychain.getCredentials() {
                
                self.client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (balance) -> Void in
    
                    
                    self.amountLabel.setText("$\(balance)")
                    let date = NSDate()
                    self.userDefaults.set(balance, forKey: "lastBalance")
                    self.userDefaults.set(date, forKey: "timeOfLastUpdate")
                    self.footerLabel.setText("Updated: \(date.timeAgoInWords)")
                    self.loadingGroup.setHidden(true)
                    self.detailGroup.setHidden(false)
                    
                    }.catch { (_) in
                        self.showError(msg: "Trouble Getting Data")
                    }
                
            } else {
                self.showError()
            }
        }
    }
    
    func showError(msg: String = "Open App to Update") {
        self.loadingGroup.setHidden(true)
        self.detailGroup.setHidden(true)
        self.errorGroup.setHidden(false)
        errorLabel.setText(msg)
    }
    
    func updateTimeOfLastUpdate() {
        if let timeOfLastUpdate = userDefaults.object(forKey: "timeOfLastUpdate") as? NSDate {
            DispatchQueue.main.async {
                self.footerLabel.setText("Updated: \(timeOfLastUpdate.timeAgoInWords)")
            }
            
        }
    }

}
