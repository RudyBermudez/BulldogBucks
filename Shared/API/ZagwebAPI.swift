//
//  API Client.swift
//  Bulldog Bucks Meter
//
//  Created by Rudy Bermudez on 11/18/16.
//
//

import Foundation
import Alamofire
import PromiseKit
import Kanna

/**
    Models the cases for potential errors in `ZagwebAPI`. Conforms to `Error` protocol
 
    - Cases:
        - **noHeadersReturned:** Occurs in `ZagwebAPI.authenticate()` when no header is returned in the request. This means no cookies exist and all other methods will fail
 
        - **invalidCredentials:** Occurs in `ZagwebAPI.authenticate()` when the `SESSID` cookie is not found in the request header or if the cookie value is empty.
 
        - **htmlCouldNotBeParsed:** Occurs in `ZagwebAPI.downloadHTML()` when the downloaded page html could not be parsed. This most likely means that the user is not authenticated
 */
enum ClientError: Error {
	case noHeadersReturned
	case invalidCredentials
	case htmlCouldNotBeParsed
	
    /// Returns a user-readable error message as `String`. For Example: `"Incorrect Student ID or PIN"`
    /// - Returns: User-readable error message as `String`
	func domain() -> String {
		switch self {
		case .invalidCredentials:
			return "Incorrect Student ID or PIN"
        case .noHeadersReturned:
            return "No headers were returned."
        case .htmlCouldNotBeParsed:
            return "Failed to parse data source."
		}
	}
}

/**
 Models all required functions to authenticate and communicate with [zagweb.gonzaga.edu](https://zagweb.gonzaga.edu)
 
 - Important: User must successfully authenticate before calling any other methods
 */
class ZagwebClient {
	
    
    func setupRequest() -> Promise<Void> {
        return Promise { fulfill, reject in
            
            // Fetch Request
            Alamofire.request("https://zagweb.gonzaga.edu/pls/gonz/twbkwbis.P_WWWLogin", method: .get)
                .validate()
                .response() { response in
                    
                    if (response.error == nil) {
                        print("Completed Setup Request")
                        fulfill()
                    } else {
                        reject(response.error!)
                    }
                }
                    
            }
        }

    
    /**
     Authenticates the user to the zagweb service.
     
     Checks to see if the authentication is successful by checking for the `SESSID` cookie.
     
     - Important: This method must be called and must succeed before any other method is called.
     
     - Note: Unfortunately, due to the poor Zagweb website. It is normal for the website to redirect to another URL on the first attempt to Post data. For that reason, the `ClientError.invalidCredentials` error is only 100% accurate after the second attempt. Most likely than not, the first attempt will fail
     
     - Parameters: 
        - withStudentID: The student ID of the user as a `String`
        - withPIN: The PIN of the user as a `String`
     
     - Throws: 
        - `ClientError.noHeadersReturned` when no header is returned in the request. This means no cookies exist and all other methods will fail
        - `ClientError.invalidCredentials` when the `SESSID` cookie is not found in the request header or if the cookie value is empty.
     
     - Returns: A fufilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fufilled and contain `[HTTPCookie]`. If the authenication fails, the `Promise` will be rejected and contain a `ClientError`. The possible `ClientError` is noted in the `Throws` Section of documentaion.
     
     */
	func authenticationHelper(withStudentID: String, withPIN: String) -> Promise<Void> {
        
		return Promise { fulfill, reject in
            
			var cookieFound = false
			let urlString = "https://zagweb.gonzaga.edu/pls/gonz/twbkwbis.P_ValLogin?sid=\(withStudentID)&PIN=\(withPIN)"
			Alamofire.request(urlString, method: .post).validate().response(){ (response) in
				guard let headerFields = response.response?.allHeaderFields as? [String:String], let url = response.request?.url else {
					reject(ClientError.noHeadersReturned)
					return
				}
				let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
				for cookie in cookies {
					if cookie.name == "SESSID" && !cookie.value.isEmpty{
						cookieFound = true
					}
				}
				// If SESSID Cookie is not found, then credentials must be wrong
				if !cookieFound {
                    print("Authentication Failed")
					reject(ClientError.invalidCredentials)
				} else {
                    print("Authentication Successful")
					fulfill()
				}
			}
		}
	}
    
    func authenticate(withStudentID studentID: String, withPIN PIN: String) -> Promise <Void> {
        return Promise { fulfill, reject in
            
            setupRequest().then { (_) -> Promise<Void> in
                return self.authenticationHelper(withStudentID: studentID, withPIN: PIN)
                }.then { (result) in
                    fulfill()
                }.catch{ (error) in
                    reject(error)
            }
        }
    }
	
    /**
     Downloads the html from https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions for the authenticated user. Then calls `parseHTML()` to parse the HTML and return the amount of Bulldog Bucks remaining as a `String`.
     
     - Precondition: User must successfully authenticate before calling any other methods
     
     - Throws: `ClientError.htmlCouldNotBeParsed` when the downloaded page html could not be parsed. This most likely means that the user is not authenticated.
     
     - Returns: A fulfilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fulfilled and contain a `String` of the form "$235.32" that denotes the amount of Bulldog Bucks Remaining.  If the authentication fails, the `Promise` will be rejected and contain `ClientError.htmlCouldNotBeParsed`. The explanation of this `ClientError` is noted in the `Throws` Section of documentation.
     */
	private func downloadHTML() -> Promise<String> {
		return Promise { fulfill, reject in
			let url = URL(string: "https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions")!
			Alamofire.request(url, method: .post).validate().responseString(){ (response) in
				switch response.result {
				case .success(let html):
					guard let bulldogBucksRemaining = self.parseHTML(html: html) else {
						reject(ClientError.htmlCouldNotBeParsed)
						return
					}
                    print("HTML Parsed")
					fulfill(bulldogBucksRemaining)
				case .failure(let error): reject(error); print("Error in Download HTML")
				}
			}
			
		}
	}
	
    /**
     Parses HTML and looks for the first occurrence of a pllabel with a "$". The very first "$" on the page is the user's amount of Bulldog Bucks remaining. Method is called in `downloadHTML()`
     
     - Parameter html: HTML source from https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions as a String
     - Returns: If successful, the amount of Bulldog Bucks remaining as String with format "235.21". If fails, returns nil
     */
	private func parseHTML(html: String) -> String? {
		
		if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8){
			for name in doc.css("td, pllabel") {
				if let text = name.text {
					if text.contains("$") {
						// I return immediately because it should always be the first occurrence
						return text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "$", with: "")
					}
				}
			}
		}
		return nil
	}
	
    func logout() -> Promise<Void> {
        
        return Promise { fulfill, reject in
            
            // Fetch Request
            Alamofire.request("https://zagweb.gonzaga.edu/pls/gonz/twbkwbis.P_Logout", method: .post)
                .validate()
                .response() { response in
                    if (response.error == nil) {
                        print("Logout Complete")
                        fulfill()
                    } else {
                        reject(response.error!)
                    }
            }
        }
    }
    
    /**
     Authenticates the user, downloads & parses HTML, and returns the amount of Bulldog Bucks Remaining.
     
     - Note: This is a public accessible function that wraps the `authenticate()` and `downloadHTML()` to create a convenience method for the Developer
     
     - Parameters:
        - withStudentID: The student ID of the user as a `String`
        - withPIN: The PIN of the user as a `String`
     
     - Throws: 
        - `ClientError.noHeadersReturned` when no header is returned in the request. This means no cookies exist and all other methods will fail
        - `ClientError.invalidCredentials` when the `SESSID` cookie is not found in the request header or if the cookie value is empty.
        - `ClientError.htmlCouldNotBeParsed` when the downloaded page html could not be parsed. This most likely means that the user is not authenticated.
     
     - Returns: A fulfilled or rejected `Promise`. If successful, the amount of Bulldog Bucks remaining as String with format "235.21". If failed, a rejected `Promise` with a `ClientError`. The possible `ClientError` is noted in the `Throws` Section of documentation.
     */
    func getBulldogBucks(withStudentID: String, withPIN: String) -> Promise<String> {
        return Promise { fulfill, reject in
            
            firstly {
                self.authenticate(withStudentID: withStudentID, withPIN: withPIN)
                }
            .then { (_) -> Promise<String> in
                return self.downloadHTML()
                }
            .then { (result) -> Promise<(Void, String)> in
                let logout = self.logout()
                let result = Promise(value: result)
                return when(fulfilled: logout, result)
                }
            .then { (results) in
                fulfill(results.1)
                }
            .catch { (error) in
                reject(error)
                }
        }
    }
    
	
}

