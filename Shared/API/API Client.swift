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

enum ClientError: Error {
	case noHeadersReturned
	case invalidCredentials
	case htmlCouldNotBeParsed
	
	func domain() -> String {
		switch self {
		case .invalidCredentials:
			return "Incorrect Student ID or PIN"
		default: return ""
		}
	}
}


class APIClient {
	
	func authenticate(withStudentID: String, withPIN: String) -> Promise<[HTTPCookie]> {
		return Promise { fulfill, reject in
			var cookieFound = false
			let urlString = "https://zagweb.gonzaga.edu/pls/gonz/twbkwbis.P_ValLogin?sid=\(withStudentID)&PIN=\(withPIN)"
			Alamofire.request(urlString, method: .post).validate().response(completionHandler: { (response) in
				guard let headerFields = response.response?.allHeaderFields as? [String:String], let url = response.request?.url else {
					reject(ClientError.noHeadersReturned)
					return
				}
				let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
				for cookie in cookies {
					if cookie.name == "SESSID" && !cookie.value.isEmpty{
						NSLog("SESSID Cookie Exists")
						cookieFound = true
					}
				}
				// If SESSID Cookie is not found, then credentials must be wrong
				if !cookieFound {
					reject(ClientError.invalidCredentials)
				} else {
					fulfill(cookies)
				}
			})
		}
	}
	
	private func downloadHTML(withCookies: [HTTPCookie]) -> Promise<String> {
		return Promise { fulfill, reject in
			let url = URL(string: "https://zagweb.gonzaga.edu/pls/gonz/hwgwcard.transactions")!
			Alamofire.request(url, method: .post).validate().responseString(completionHandler: { (response) in
				switch response.result {
				case .success(let html):
					guard let bulldogBucksRemaining = self.parseHTML(html: html) else {
						reject(ClientError.htmlCouldNotBeParsed)
						return
					}
					fulfill(bulldogBucksRemaining)
				case .failure(let error): reject(error); print("Error in Download HTML")
				}
				
			})
			
		}
	}
	
	private func parseHTML(html: String) -> String? {
		
		if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8){
			for name in doc.css("td, pllabel") {
				if let text = name.text {
					if text.contains("$") {
						// I return immediately because it should always be the first occurance
						return text.replacingOccurrences(of: " ", with: "")
					}
				}
			}
		}
		return nil
	}
	
	func getBulldogBucks(withStudentID: String, withPIN: String) -> Promise<String> {
		return Promise { fulfill, reject in
			authenticate(withStudentID: withStudentID, withPIN: withPIN)
				.then { (cookies) -> Promise<String> in
					return self.downloadHTML(withCookies: cookies)
				}.then { (result) in
					fulfill(result)
				}.catch { (error) in
					reject(error)
			}
		}
	}
	
}

