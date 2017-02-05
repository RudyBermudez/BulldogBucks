//
//  Authentication.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 2/5/17.
//
//

import Foundation
import Locksmith


class Authentication {
    
    /// Check UserDefaults to see if `studentID` and `PIN` exist and are not nil
    static func isLoggedIn() -> Bool {
        guard let username = UserDefaults(suiteName: "group.bdbMeter")?.string(forKey: "studentID"), let _ = Locksmith.loadDataForUserAccount(userAccount: username, inService: "co.rudybermudez.Bulldog-Bucks")?["password"] as? String else {
            return false
        }
        
        return true
    }
    
    /// Loads credentials to memory if they exist, else calls `self.logout()`
    static func loadCredentials() -> (studentID: String, PIN: String)? {
        if isLoggedIn() {
            let studentID = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID")!
            let PIN = Locksmith.loadDataForUserAccount(userAccount: studentID, inService: "co.rudybermudez.Bulldog-Bucks")?["password"] as! String
            return (studentID, PIN)
        } else {
            return nil
        }
    }
    
    static func deleteCredentials() {
        if let username = UserDefaults(suiteName: "group.bdbMeter")?.string(forKey: "studentID") {
            do {
                UserDefaults(suiteName: "group.bdbMeter")?.set(nil, forKey: "studentID")
                if UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") != nil {
                    UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "PIN")
                }
                try Locksmith.deleteDataForUserAccount(userAccount: username)
                
            } catch let error {
                UserDefaults(suiteName: "group.bdbMeter")?.set(nil, forKey: "studentID")
                print(error.localizedDescription)
            }
        }
    }
}
