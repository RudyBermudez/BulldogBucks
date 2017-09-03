//
//  ExtensionDelegate.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        NSLog("Watch App finished launching")
        setupWatchConnectivity()
        scheduleBackgroundFetch()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        
        NSLog("ExtensionDelegate: Application is now Backgrounded")
    }


    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        
        for task : WKRefreshBackgroundTask in backgroundTasks {
            NSLog("received background task: \(task)")
            
            if WKExtension.shared().applicationState == .background {
                if task is WKApplicationRefreshBackgroundTask {
                    NSLog("Application Refresh Background Task Started")
                    downloadData()
                }
            } else {
                NSLog("Application not in background. Not downloading new data")
                scheduleBackgroundFetch(inMinutes: 5)
            }
            
            task.setTaskCompleted()
        }
        
    }
    
        func downloadData() {
            guard let credentials = keychain.getCredentials() else {
                NSLog("Background: User is not logged in")
                updateComplication()
                scheduleBackgroundFetch()
                return
            }
            NSLog("Background: User is logged in, attempting to connect to zagweb")
            client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (amount, _, _, _) -> Void in
                
                let date = Date()
                NSLog("Background: Data Successfully downloaded in background. \(amount) at \(date.description)")
                let newBalance = Balance(amount: amount, date: date)
                BalanceListManager.addBalance(balance: newBalance)
                self.updateComplication()
                self.scheduleBackgroundFetch()
            }.catch { (error) in
                NSLog(error.localizedDescription)
                self.scheduleBackgroundFetch(inMinutes: 5)
            }
        }
        
    func updateComplication() {
        NSLog("Background: Requested Complication Update")
        let complicationController = ComplicationController()
        complicationController.reloadOrExtendData()
    }
    
    
    func scheduleBackgroundFetch(inMinutes: Double = 30) {
        // Update Every Half-Hour
        let fireDate = Date(timeIntervalSinceNow: inMinutes * 60)
        let userInfo = ["lastActiveDate" : Date(),
                        "reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                NSLog("successfully scheduled background task in \(inMinutes) minutes")
            } else {
                print("Error while scheduling background task")
                self.scheduleBackgroundFetch(inMinutes: 2)
            }
        }
    }
    

}

extension ExtensionDelegate: WCSessionDelegate {
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session  = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith
        activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: " + "\(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: " + "\(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let studentID = userInfo[KeychainKey.studentID.rawValue] as? String, let PIN = userInfo[KeychainKey.pin.rawValue] as? String {
            let _ = keychain.addCredentials(studentID: studentID, PIN: PIN)
            notificationCenter.post(name: Notification.Name(InterfaceController.UserLoggedInNotificaiton), object: nil)
            print("Credentials Added to Watch")
        }
        if let shouldLogout = userInfo["logout"] as? Bool{
            if shouldLogout {
                let _ = keychain.deleteCredentials()
                BalanceListManager.purgeBalanceList()
                self.notificationCenter.post(name: Notification.Name(InterfaceController.UserLoggedOutNotification), object: nil)
                self.updateComplication()
                print("Credentials Removed from Watch")
            }
        }
    }

}





