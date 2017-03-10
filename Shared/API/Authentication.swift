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

protocol AuthenticationStateDelegate {
    func didLoginSuccessfully(animated: Bool)
    func didLogoutSuccessfully()
}

enum KeychainKey: String {
    case studentID = "studentID"
    case pin = "PIN"
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
        return keychain[KeychainKey.studentID.rawValue] != nil && keychain[KeychainKey.pin.rawValue] != nil
    }
    
    /**
     Saves user's credentials to an instance of `keychain`
     - Parameters:
     - studentID: `String` representation of the User's StudentID
     - PIN: `String` representation of the User's PIN
     */
    static func addCredentials(studentID: String, PIN: String) -> Bool {
        do {
            try keychain.set(studentID, key: KeychainKey.studentID.rawValue)
            try keychain.set(PIN, key: KeychainKey.pin.rawValue)
            return true
        }
        catch let error {
            print(error)
            return false
        }
    }
    
    /// Loads credentials to memory if they exist, else returns nil
    static func getCredentials() -> (studentID: String, PIN: String)? {
        if isLoggedIn() {
            return (keychain[KeychainKey.studentID.rawValue]!, keychain[KeychainKey.pin.rawValue]!)
        } else {
            return nil
        }
    }
    
    /// Deletes credentials from instance of `keychain`
    static func deleteCredentials() -> Bool {
        do {
            try keychain.removeAll()
            return true
        } catch let error {
            print("error: \(error.localizedDescription)")
            return false
        }
    }
}
