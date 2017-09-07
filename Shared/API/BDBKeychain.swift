//
//  Authentication.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 2/5/17.
//
//

import Foundation
import KeychainAccess



protocol AuthenticationStateDelegate {
    func didLoginSuccessfully()
    func didLogoutSuccessfully()
}

/// Enum that models
enum BDBKeychain {
    
    /// Instance of Keychain used on the iOS target
    case phoneKeychain
    
    /// Instance of Keychain used on the watchOS target
    case watchKeychain
    
    
    /// Sets the keychain based off of the respected OS target
    private var keychain: Keychain {
        switch self {
        case .phoneKeychain:
            return Keychain(service: "co.rudybermudez.Bulldog-Bucks").accessibility(.afterFirstUnlock)
            
        case .watchKeychain:
            return Keychain(service: "co.rudybermudez.Bulldog-Bucks.watchkitapp.watchkitextension").accessibility(.afterFirstUnlock)
        }
    }
    
    /**
     Checks device Keychain to see if `studentID` and `PIN` exist and are not nil
     - Returns: Boolean representing whether the user is logged in
     */
    func isLoggedIn() -> Bool {
        return keychain[KeychainKey.studentID.rawValue] != nil && keychain[KeychainKey.pin.rawValue] != nil
    }
    
    /**
     Saves user's credentials to an instance of `keychain`
     - Parameters:
     - studentID: `String` representation of the User's StudentID
     - PIN: `String` representation of the User's PIN
     */
    func addCredentials(studentID: String, PIN: String) -> Bool {
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
    func getCredentials() -> (studentID: String, PIN: String)? {
        if isLoggedIn() {
            return (keychain[KeychainKey.studentID.rawValue]!, keychain[KeychainKey.pin.rawValue]!)
        } else {
            return nil
        }
    }
    
    /// Deletes credentials from instance of `keychain`
    func deleteCredentials() -> Bool {
        do {
            try keychain.removeAll()
            return true
        } catch let error {
            print("error: \(error.localizedDescription)")
            return false
        }
    }
}

/// Models Errors that can occur in the Keychain
enum KeychainError: Error {
    
    /// Error thrown when Credentials could not be saved to the keychain
    case DidNotSaveCredentials
}


/// Key Values for Keychain Access
///
/// These enums are used as the keyvalues used to access keychain data.
/// This is helpful to have because string constants reduce errors
///
/// - studentID: rawValue contains the string 'studentID'
/// - pin: rawValue contains the string 'PIN'
enum KeychainKey: String {
    case studentID = "studentID"
    case pin = "PIN"
}



