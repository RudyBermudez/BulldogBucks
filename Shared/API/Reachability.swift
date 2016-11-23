//
//  Reachability.swift
//  Stratus
//
//  Created by Rudy Bermudez on 6/19/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import SystemConfiguration

public class Reachability {
	
	class func isConnectedToNetwork() -> Bool {
		
		var zeroAddress = sockaddr()
		zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
		zeroAddress.sa_family = sa_family_t(AF_INET)
		
		guard let defaultRouteReachability: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
			SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
		}) else { return false }
		
		
		var flags : SCNetworkReachabilityFlags = []
		if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
			return false
		}

		
		let isReachable = flags.contains(.reachable)
		let needsConnection = flags.contains(.connectionRequired)
		
		
		return (isReachable && !needsConnection)
	}
	
}
