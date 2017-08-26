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
    
    let userDefaults = UserDefaults.standard
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        setupWatchConnectivity()
        scheduleBackgroundFetch()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        
        for task : WKRefreshBackgroundTask in backgroundTasks {
            print("received background task: ", task)
            
            if task is WKApplicationRefreshBackgroundTask {
                // this task is completed below, our app will then suspend while the download session runs
                print("Application task received")
                // Handle downloading latest info
                if let credentials = keychain.getCredentials() {
                    print("User is logged in, beginning network request")
                    let _ = client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (balance) -> Void in
                        self.userDefaults.set(balance, forKey: "lastBalance")
                        self.userDefaults.set(Date(), forKey: "timeOfLastUpdate")
                        print("Downloaded new data")
                        
                        self.updateComplication()
                        print("Complication update requested")
                        
                        self.scheduleBackgroundFetch()
                        print("Scheduled Next Background Fetch")
                    }
                } else {
                    print("User is not logged in")
                    self.updateComplication()
                    print("Complication update requested")
                    
                    self.scheduleBackgroundFetch()
                    print("Scheduled Next Background Fetch")
                }
                
                
            }
            print("Task Completed")
            task.setTaskCompleted()
        }
        
    }
    
    func updateComplication() {
        let server = CLKComplicationServer.sharedInstance()
        guard let complications = server.activeComplications,
            complications.count > 0 else { return }
        
        for complication in complications  {
            print("Complication Reloaded")
            server.reloadTimeline(for: complication)
        }
    }
    
    func scheduleBackgroundFetch() {
        // Update Every Hour
        let fireDate = Date(timeIntervalSinceNow: 60 * 60)
        let userInfo = ["lastActiveDate" : Date(),
                        "reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task.")
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
                self.userDefaults.set(nil, forKey: "lastBalance")
                self.userDefaults.set(nil, forKey: "timeOfLastUpdate")
                self.notificationCenter.post(name: Notification.Name(InterfaceController.UserLoggedOutNotification), object: nil)
                updateComplication()
                print("Credentials Removed from Watch")
            }
        }
    }

}





