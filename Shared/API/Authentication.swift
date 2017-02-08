//
//  Authentication.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 2/5/17.
//
//

import Foundation
import KeychainAccess

enum AuthenticationError: Error {
    case DidNotSaveCredentials
}


/// Serves as the point of authentication for Bulldog Bucks App
class Authentication {
    
    /// App Static Keychain Service
    static let keychain = Keychain(service: "co.rudybermudez.Bulldog-Bucks").accessibility(.afterFirstUnlock)
    
    /**
     Check UserDefaults to see if `studentID` and `PIN` exist and are not nil
     - Returns: Boolean representing whether the user is logged in
     */
    static func isLoggedIn() -> Bool {
        guard let username = UserDefaults(suiteName: "group.bdbMeter")?.string(forKey: "studentID"), let _ = keychain[username] else {
            return false
        }
        
        return true
    }
    
    /**
     Saves user's credentials to an instance of `keychain`
     - Parameters:
        - studentID: `String` representation of the User's StudentID
        - PIN: `String` representation of the User's PIN
     */
    static func addCredentials(studentID: String, PIN: String) -> Bool {
        do {
            try keychain.set(PIN, key: studentID)
            return true
        }
        catch let error {
            print(error)
            return false
        }
    }
    
    /// Loads credentials to memory if they exist, else returns nil
    static func loadCredentials() -> (studentID: String, PIN: String)? {
        if isLoggedIn() {
            let studentID = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "studentID")!
            let PIN = keychain[studentID]
            return (studentID, PIN!)
        } else {
            return nil
        }
    }
    
    /// Deletes credentials from instance of `keychain`
    static func deleteCredentials() {
        if let username = UserDefaults(suiteName: "group.bdbMeter")?.string(forKey: "studentID") {
            do {
                UserDefaults(suiteName: "group.bdbMeter")?.set(nil, forKey: "studentID")
                if UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "PIN") != nil {
                    UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "PIN")
                }
                try keychain.remove(username)
                
            } catch let error {
                UserDefaults(suiteName: "group.bdbMeter")?.set(nil, forKey: "studentID")
                print(error.localizedDescription)
            }
        }
    }
}
