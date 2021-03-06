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

typealias SwipesRemaining = String

/**
    Models the cases for potential errors in `ZagwebAPI`. Conforms to `Error` protocol
 
    - Cases:
        - **noHeadersReturned:** Occurs in `ZagwebAPI.authenticationHelper()` when no header is returned in the request. This means no cookies exist and all other methods will fail
 
        - **invalidCredentials:** Occurs in `ZagwebAPI.authenticationHelper()` when the `SESSID` cookie is not found in the request header or if the cookie value is empty.
 
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
            return "Unable to complete the request.\nNo headers were returned."
        case .htmlCouldNotBeParsed:
            return "Failed to parse data source."
		}
	}
}

/// The State of the User's ZagCard
enum CardState: String {
    case active
    case frozen
}

/// Models all required functions to authenticate and communicate with [zagweb.gonzaga.edu](https://zagweb.gonzaga.edu)
/// - Important: User must successfully authenticate before calling any other methods
final class ZagwebClient {

    /// Makes the inital request to Zagweb
    ///
    /// Note: This is required to initialize the cookies properly
    ///
    /// - Returns: A `Promise` with an associated Void value
    private static func setupRequest() -> Promise<Void> {
        return Promise { fulfill, reject in

            // Fetch Request
            Alamofire.request("https://zagweb.gonzaga.edu/prod/twbkwbis.P_WWWLogin", method: .get)
                .validate()
                .response { response in
                    guard let headerFields = response.response?.allHeaderFields as? [String: String], let url = response.request?.url else {
                        reject(ClientError.noHeadersReturned)
                        return
                    }
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                    HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)

                    if (response.error == nil) {
                        print("Completed Setup Request")
                        fulfill(())
                    } else {
                        reject(response.error!)
                    }
                }

            }
        }

    /**
     Authenticates the user to the zagweb service.
     
     Checks to see if the authentication is successful by checking for the `SESSID` cookie.
     
     - Important: The `setupRequest()` must be called before or else this method will fail.
     
     
     - Parameters:
     - withStudentID: The student ID of the user as a `String`
     - withPIN: The PIN of the user as a `String`
     
     - Throws:
     - `ClientError.noHeadersReturned` when no header is returned in the request. This means no cookies exist and all other methods will fail
     - `ClientError.invalidCredentials` when the `SESSID` cookie is not found in the request header or if the cookie value is empty.
     
     - Returns: A fufilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fufilled and contain `Void`. If the authenication fails, the `Promise` will be rejected and contain a `ClientError`. The possible `ClientError` is noted in the `Throws` Section of documentaion.
     
     */
	private static func authenticationHelper(withStudentID: String, withPIN: String) -> Promise<Void> {

		return Promise { fulfill, reject in

			var cookieFound = false
			let urlString = "https://zagweb.gonzaga.edu/prod/twbkwbis.P_ValLogin?sid=\(withStudentID)&PIN=\(withPIN)"
			Alamofire.request(urlString, method: .post).validate().response { (response) in
				guard let headerFields = response.response?.allHeaderFields as? [String: String], let url = response.request?.url else {
					reject(ClientError.noHeadersReturned)
					return
				}
				let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
				for cookie in cookies {
					if cookie.name == "SESSID" && !cookie.value.isEmpty {
						cookieFound = true
					}
				}
				// If SESSID Cookie is not found, then credentials must be wrong
				if !cookieFound {
                    print("Authentication Failed")
					reject(ClientError.invalidCredentials)
				} else {
                    print("Authentication Successful")
					fulfill(())
				}
			}
		}
	}

    /// Publc Authentication Wrapper Method
    ///
    /// Calls `setupRequest()` and then `authenticationHelper()`
    ///
    /// - Parameters:
    ///     - withStudentID: The student ID of the user as a `String`
    ///     - withPIN: The PIN of the user as a `String`
    /// - Returns: A fufilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fufilled and contain `Void`. If the authenication fails, the `Promise` will be rejected and contain a `ClientError`. The possible `ClientError` is noted in the `Throws` Section of documentaion.
    static func authenticate(withStudentID studentID: String, withPIN PIN: String) -> Promise <Void> {
        return Promise { fulfill, reject in

            setupRequest().then { (_) -> Promise<Void> in
                return self.authenticationHelper(withStudentID: studentID, withPIN: PIN)
                }.then { (_) in
                    fulfill(())
                }.catch { (error) in
                    reject(error)
            }
        }
    }

    /**
     Downloads the html from https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions for the authenticated user. Then calls `parseHTML()` to parse the HTML and return the amount of Bulldog Bucks remaining as a `String`.
     
     - Precondition: User must successfully authenticate before calling any other methods
     
     - Throws: `ClientError.htmlCouldNotBeParsed` when the downloaded page html could not be parsed. This most likely means that the user is not authenticated.
     
     - Returns: A fulfilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fulfilled and contain a `String` of the form "235.32" that denotes the amount of Bulldog Bucks Remaining.  If the authentication fails, the `Promise` will be rejected and contain `ClientError.htmlCouldNotBeParsed`. The explanation of this `ClientError` is noted in the `Throws` Section of documentation.
     */
	private static func downloadHTML() -> Promise<(Balance, [Transaction], CardState, SwipesRemaining)> {
		return Promise { fulfill, reject in
			let url = URL(string: "https://zagweb.gonzaga.edu/prod/hwgwcard.transactions")!
			Alamofire.request(url, method: .post).validate().responseString { (response) in
                guard let headerFields = response.response?.allHeaderFields as? [String: String], let url = response.request?.url else {
                    reject(ClientError.noHeadersReturned)
                    return
                }
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)

				switch response.result {
				case .success(let html):

                    var defaultSwipes = "0"
                    var defaultTransactions: [Transaction] = []

					guard let bulldogBucksRemaining = self.parseBalanceHTML(html: html) else {
						reject(ClientError.htmlCouldNotBeParsed)
						return
					}
                    print("Balance Parsed")

                    if let bulldogBuckTransactions = self.parseTransactionHTML(html: html) {
                        defaultTransactions = bulldogBuckTransactions
                        print("Transactions Parsed")
                    } else {
                        print("No Transactions Parsed. Using Default")
                    }

                    guard let zagcardState = self.parseCardStatusHTML(html: html) else {
                        reject(ClientError.htmlCouldNotBeParsed)
                        return
                    }
                    print("Card State Parsed")

                    if let swipesRemaining = self.parseSwipesRemainingHTML(html: html) {
                        defaultSwipes = swipesRemaining
                        print("Swipes Remaining Parsed")
                    } else {
                        print("Swipes Remaining Failed to Parse. Using Default")
                    }
                    fulfill((bulldogBucksRemaining, defaultTransactions, zagcardState, defaultSwipes))
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
	private static func parseBalanceHTML(html: String) -> Balance? {

		if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
			for name in doc.css("td, pllabel") {
				if let text = name.text {
					if text.contains("$") {
						// I return immediately because it should always be the first occurrence
						return Balance(rawBalance: text)
					}
				}
			}
		}
		return nil
	}

    /**
     Parses HTML and returns the user's zag card state.
     
     Note: This is not scientific at all. I am just looking for the word Active.
     This is an awful way of doing this, but it's the only way of doing it...
     
     - Parameter html: HTML source from https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions as a String
     - Returns: If successful, the user's `CardState` If fails, returns nil
     */
    private static func parseCardStatusHTML(html: String) -> CardState? {

        if let doc = try? Kanna.HTML(html: html, encoding: .utf8),
            let body = doc.body?.content {
            if body.contains("Active") {
                return CardState.active
            } else {
                return CardState.frozen
            }
        } else {
            return nil
        }
    }

    /**
     Parses HTML and returns an array of `Transaction`
     
     - Parameter html: HTML source from https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions as a String
     - Returns: If successful, an array of type `Transaction`. If fails, returns nil
     */
    private static func parseTransactionHTML(html: String) -> [Transaction]? {
        var transactions: [Transaction] = []

        if let doc = try? Kanna.HTML(html: html, encoding: .utf8) {

            // Get all the tables that contain the classname `plaintable`
            for table in doc.xpath("//table[contains(@class, 'plaintable')]") {

                // Look for the table that specifically has the text "Transaction Date"
                if (table.content?.contains("Transaction Date"))! {

                    // Get all of the rows in the table
                    let rows = table.css("tr")

                    for row in rows {
                        // For each row in the table, 
                        // 1. break the row up by '\n', 
                        // 2. filter out the empty strings,
                        // 3. trim out all the whitespace and new lines
                        let rowData: [String]? = row.text?.components(separatedBy: "\n")
                            .filter { $0 != "" }
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)}

                        // 1. See if the row data can be unwrapped
                        // 1. Check to see if the data has exactly 7 items in it, 
                        // 2. Neglect the first row because it solely has labels in it
                        // 3. See if the transaction can be parsed
                        if let rowData = rowData, rowData.count == 7, rowData[0] != "Transaction Date",
                            let transaction = Transaction(date: rowData[0], venue: rowData[1], amount: rowData[3], type: rowData[6]) {

                            // Assuming all checks pass, append the data
                            transactions.append(transaction)
                        }
                    }
                }
            }
        }
        if transactions.isEmpty {
            return nil
        } else {
            return transactions
        }
    }

    private static func parseSwipesRemainingHTML(html: String) -> SwipesRemaining? {
        var labelFound: Bool = false

        if let doc = try? Kanna.HTML(html: html, encoding: .utf8) {
            let labels = doc.xpath("//td[contains(@class, 'pllabel')]")
            for label in labels {
                if labelFound {
                    return label.content
                }
                if (label.content?.contains("Semester Remaining"))! {
                    labelFound = true
                }
            }
        }
        return nil
    }

    /// Un-authenticates the user from the zagweb service
    ///
    /// - Returns: A fufilled or rejected `Promise`. If the authentication is successful, the `Promise` will be fufilled and contain `Void`. If the authenication fails, the `Promise` will be rejected and contain a `ClientError`. The possible `ClientError` is noted in the `Throws` Section of documentaion.
    public static func logout() -> Promise<Void> {

        return Promise { fulfill, reject in

            // Fetch Request
            Alamofire.request("https://zagweb.gonzaga.edu/prod/twbkwbis.P_Logout", method: .post)
                .validate()
                .response { response in
                    guard let headerFields = response.response?.allHeaderFields as? [String: String], let url = response.request?.url else {
                        reject(ClientError.noHeadersReturned)
                        return
                    }
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                    HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)

                    if (response.error == nil) {
                        print("Logout Complete")
                        fulfill(())
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
    public static func getBulldogBucks(withStudentID: String, withPIN: String) -> Promise<(Balance, [Transaction], CardState, SwipesRemaining)> {
        return Promise { fulfill, reject in

            firstly {
                self.authenticate(withStudentID: withStudentID, withPIN: withPIN)
                }
            .then { (_) -> Promise<(Balance, [Transaction], CardState, SwipesRemaining)> in
                return self.downloadHTML()
                }
            .then { (balance, transactions, cardState, swipesRemaining) -> Void in
                _ = self.logout()
                fulfill((balance, transactions, cardState, swipesRemaining))
                }
            .catch { (error) in
                reject(error)
            }
        }
    }

    public static func freezeUnfreezeZagcard(withStudentID: String, withPIN: String, desiredCardState: CardState) -> Promise<Void> {
        return Promise { fulfill, reject in

            firstly {
                self.authenticate(withStudentID: withStudentID, withPIN: withPIN)
                }
                .then { (_) -> Void in

                    let headers = ["Content-Type": "application/x-www-form-urlencoded"]
                    var body: [String: String]!

                    switch desiredCardState {
                    case .frozen : body = ["p_freeze": "1"]
                    case .active: body = ["p_freeze": "0"]
                    }

                    Alamofire.request("https://zagweb.gonzaga.edu/prod/hwgwcard.transactions", method: .post, parameters: body, encoding: URLEncoding.default, headers: headers).validate().response { (response) in
                        if (response.error == nil) {
                            fulfill(())
                            switch desiredCardState {
                            case .frozen : print("Successfully Froze Zagcard")
                            case .active: print("Successfully Activated Zagcard")
                            }
                        } else {
                            reject(response.error!)
                        }
                    }

                }
                .catch { (error) in
                    reject(error)
            }
        }
    }

}
