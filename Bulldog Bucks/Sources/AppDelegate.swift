//
//  AppDelegate.swift
//  Bulldog Bucks Meter
//
//  Created by Rudy Bermudez on 9/26/16.
//
//

import UIKit
import WatchConnectivity


/// `String` constant for `NSNotification.Name() for when the user logs out of the application`
public let UserLoggedOutNotification = "UserLoggedOut"

/// `String` constant for `NSNotification.Name() for when the user logs into the application`
public let UserLoggedInNotificaiton = "UserLoggedIn"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var storyboard: UIStoryboard?
    var navigationController: UINavigationController?
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        setupWatchConnectivity()
        setupNotificationCenter()
        
        if BDBKeychain.phoneKeychain.isLoggedIn() {
            sendUserLoginToWatch()
        } else {
            sendUserLogoutToWatch()
        }
        
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        navigationController = UINavigationController()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let loginVC = storyboard?.instantiateViewController(withIdentifier: LoginViewController.storyboardIdentifier) as! LoginViewController
        
        loginVC.delegate = self
        navigationController?.pushViewController(loginVC, animated: false)
        
        if BDBKeychain.phoneKeychain.isLoggedIn() {
            let transactionVC = storyboard?.instantiateViewController(withIdentifier: TransactionViewController.storyboardIdentifier) as! TransactionViewController
            transactionVC.delegate = self
            navigationController?.pushViewController(transactionVC, animated: false)
        }
        
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

    
    
    // MARK: - Notification Center
    
    private func setupNotificationCenter() {
        notificationCenter.addObserver(forName: NSNotification.Name(UserLoggedInNotificaiton), object: nil, queue: nil) { (_) -> Void in
            DispatchQueue.main.async {
                self.sendUserLoginToWatch()
            }
        }
        notificationCenter.addObserver(forName: NSNotification.Name(UserLoggedOutNotification), object: nil, queue: nil) { (_) -> Void
            in
            DispatchQueue.main.async {
                self.sendUserLogoutToWatch()
            }
            
        }
    }
}

// MARK : - Watch Delegate Methods
extension AppDelegate: WCSessionDelegate {
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WC Session did deactivate")
        WCSession.default().activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith
        activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: " +
                "\(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: " +
            "\(activationState.rawValue)")
    }
    
    func sendUserLoginToWatch() {
        
        if WCSession.isSupported() {
            if let credentials = BDBKeychain.phoneKeychain.getCredentials() {
                let session = WCSession.default()
                if session.isWatchAppInstalled {
                    let dictionary = [
                        KeychainKey.studentID.rawValue: credentials.studentID,
                        KeychainKey.pin.rawValue: credentials.PIN
                    ]
                    session.transferUserInfo(dictionary)
                    print("Credentials Send to Watch")
                }
            } else {
                let session = WCSession.default()
                if session.isWatchAppInstalled {
                    let dictionary = ["logout": true]
                    session.transferUserInfo(dictionary)
                    print("Credentials Not Sent to Watch")
                }
                
            }
        }
    }
    
    
    func sendUserLogoutToWatch() {
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            if session.isWatchAppInstalled {
                let dictionary = ["logout": true]
                session.transferUserInfo(dictionary)
                print("Logout Sent to Watch")
            }
        }
    }
    
    
}

extension AppDelegate: AuthenticationStateDelegate {
    
    func didLoginSuccessfully() {
        self.notificationCenter.post(name: Notification.Name(UserLoggedInNotificaiton), object: nil)
        let transactionsVC = storyboard?.instantiateViewController(withIdentifier: TransactionViewController.storyboardIdentifier) as! TransactionViewController
        
        transactionsVC.delegate = self
        navigationController?.pushViewController(transactionsVC, animated: true)
    }
    
    func didLogoutSuccessfully() {
        self.notificationCenter.post(name: Notification.Name(UserLoggedOutNotification), object: nil)
        let _ = navigationController?.popToRootViewController(animated: true)
    }
    
}



