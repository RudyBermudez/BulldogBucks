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
	@IBOutlet var centerLabel: WKInterfaceLabel!
	@IBOutlet var footerLabel: WKInterfaceLabel!
	
	let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		
		
		
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        DispatchQueue.main.async {
            if let credentials = self.keychain.getCredentials() {
                print("ID: \(credentials.studentID), PIN: \(credentials.PIN)")
                
                self.client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (result) -> Void in
                    self.centerLabel.setText("$\(result)")
                    self.headerLabel.setHidden(false)
                    self.footerLabel.setHidden(false)
                    }.catch(execute: { (_) in
                        self.showError(msg: "Trouble Getting Data")
                    })
                
            } else {
                self.showError()
            }
        }

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func showError(msg: String = "Open App to Login") {
        centerLabel.setText(msg)
        headerLabel.setHidden(true)
        footerLabel.setHidden(true)
    }

}
