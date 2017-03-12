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
	
	let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    let userDefaults = UserDefaults.standard
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		
		
		
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
        updateDisplay()

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateDisplay() {
        DispatchQueue.main.async {
            self.loadingGroup.setHidden(false)
            if let credentials = self.keychain.getCredentials() {
                
                self.client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (balance) -> Void in
                    self.loadingGroup.setHidden(true)
                    self.errorLabel.setHidden(true)
                    self.amountLabel.setText("$\(balance)")
                    self.amountLabel.setHidden(false)
                    let date = NSDate()
                    self.userDefaults.set(date, forKey: "timeOfLastUpdate")
                    self.footerLabel.setText("Updated: \(date.timeAgoInWords)")
                    self.headerLabel.setHidden(false)
                    self.footerLabel.setHidden(false)
                    
                    }.catch(execute: { (_) in
                        self.showError(msg: "Trouble Getting Data")
                    })
                
            } else {
                self.loadingGroup.setHidden(true)
                self.showError()
                
            }
        }
    }
    
    func showError(msg: String = "Open App to Update") {
        amountLabel.setHidden(true)
        headerLabel.setHidden(true)
        footerLabel.setHidden(true)
        errorLabel.setHidden(false)
        errorLabel.setText(msg)
    }
    
    func updateTimeOfLastUpdate() {
        if let timeOfLastUpdate = userDefaults.object(forKey: "timeOfLastUpdate") as? NSDate {
            footerLabel.setText("Updated: \(timeOfLastUpdate.timeAgoInWords)")
        }
    }

}
