//
//  InterfaceController.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import WatchKit
import Foundation
import RealmSwift


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
    
    var realm: Realm!
    
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        realm = try! Realm()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        // Configure interface objects here.
		setupNotificationCenter()
    }
    
    override func didAppear() {
        
        // Check to see if there is a balance stored in memory, if it cannot be found, update the display with new data
        
        guard let lastBalance = realm.objects(Balance.self).sorted(byKeyPath: "date", ascending: true).last else {
            updateDisplay()
            return
        }
        
        
        // Check to see if it has been 60 minutes from the last update,
        if NSDate().minutes(fromDate: lastBalance.date as NSDate) > 60 {
            // If it has been, then update
            updateDisplay()
        } else {
            // If not, update the label with the last balance
            
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimeOfLastUpdate), userInfo: nil, repeats: true)
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
                    
                    let newBalance = Balance()
                    let date = NSDate()
                    newBalance.amount = amount
                    newBalance.date = date as Date
                    DispatchQueue.main.async {
                        let realm = try! Realm()
                        try! realm.write ({
                            realm.add(newBalance)
                        })
                    }
                    
                    
                    

                    self.footerLabel.setText("Updated: \(date.timeAgoInWords)")
                    self.loadingGroup.setHidden(true)
                    self.detailGroup.setHidden(false)
                    self.updateComplication()
                    }.catch { (_) in
                        self.showError(msg: "Trouble Getting Data")
                    }
                
            } else {
                self.showError()
                self.updateComplication()
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
        realm = try! Realm()
        
        if let timeOfLastUpdate = realm.objects(Balance.self).sorted(byKeyPath: "date", ascending: true).last?.date as NSDate? {
            DispatchQueue.main.async {
                self.footerLabel.setText("Updated: \(timeOfLastUpdate.timeAgoInWords)")
            }
        } else {
            print("Getting time of last update failed")
        }
    }
    
    func updateComplication() {
        let server = CLKComplicationServer.sharedInstance()
        guard let complications = server.activeComplications,
            complications.count > 0 else { return }
        
        for complication in complications  {
            print("Complication Reloaded")
            server.extendTimeline(for: complication)
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
                // Delete all objects from the realm
                self.realm = try! Realm()
                try! self.realm.write {
                    self.realm.deleteAll()
                }

                self.updateDisplay()
            }
            
        }
    }

}
