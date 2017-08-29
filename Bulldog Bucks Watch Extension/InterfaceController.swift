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
    
    /// `String` constant for `NSNotification.Name() for when the user logs out of the application`
    public static let UserLoggedOutNotification = "UserLoggedOut"
    
    /// `String` constant for `NSNotification.Name() for when the user logs into the application`
    public static let UserLoggedInNotificaiton = "UserLoggedIn"
	
	let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		setupNotificationCenter()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
    }
    
    override func didAppear() {
        
        // Check to see if there is a balance stored in memory, if it cannot be found, update the display with new data
        
        guard let lastBalance = BalanceListManager.balances.last else {
            updateDisplay()
            return
        }
        
        
        // Check to see if it has been 30 minutes from the last update,
        if NSDate().minutes(fromDate: lastBalance.date as NSDate) > 30 {
            // If it has been, then update
            updateDisplay()
        } else {
            // If not, update the label with the last balance
            
            amountLabel.setText("$\(lastBalance.amount)")
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
                
                self.client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (amount) -> Void in
    
                    
                    self.amountLabel.setText("$\(amount)")
                    let date = NSDate()
                    
                    DispatchQueue.main.async {
                        let newBalance = Balance(amount: amount, date: date as Date)
                        BalanceListManager.addBalance(balance: newBalance)
                    }
                    
                    self.footerLabel.setText("Updated: \(date.timeAgoInWords)")
                    self.loadingGroup.setHidden(true)
                    self.detailGroup.setHidden(false)
                    self.reloadOrExtendData()
                    }.catch { (_) in
                        self.showError(msg: "Trouble Getting Data.\nForce touch to try again.")
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
    
    @objc func updateTimeOfLastUpdate() {
        
        if let timeOfLastUpdate = BalanceListManager.balances.last?.date as NSDate? {
            DispatchQueue.main.async {
                self.footerLabel.setText("Updated: \(timeOfLastUpdate.timeAgoInWords)")
            }
        } else {
            print("Getting time of last update failed")
        }
    }
    
    func reloadOrExtendData() {
        
        let server = CLKComplicationServer.sharedInstance()
        
        guard let complications = server.activeComplications,
            complications.count > 0 else { return }
        
        if BalanceListManager.balances.last?.date.compare(server.latestTimeTravelDate) == .orderedDescending {
            for complication in complications {
                server.extendTimeline(for: complication)
            }
        } else {
            
            for complication in complications  {
                server.reloadTimeline(for: complication)
            }
        }
        
    }
    
    // MARK: - Notification Center
    
    private func setupNotificationCenter() {
        notificationCenter.addObserver(forName: NSNotification.Name(InterfaceController.UserLoggedInNotificaiton), object: nil, queue: nil) { (_) -> Void in
            DispatchQueue.main.async {
                self.updateDisplay()
            }
        }
        notificationCenter.addObserver(forName: NSNotification.Name(InterfaceController.UserLoggedOutNotification), object: nil, queue: nil) { (_) -> Void
            in
            DispatchQueue.main.async {
                BalanceListManager.purgeBalanceList()
                self.updateDisplay()
            }
            
        }
    }

}
