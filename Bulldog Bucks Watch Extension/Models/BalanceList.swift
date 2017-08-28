//
//  BalanceList.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 8/27/17.
//
//

import Foundation


final class BalanceListManager {
    
    static var balances: [Balance] {
        get {
            return BalanceList.loadBalances()
        }
    }
    
    static func addBalance(balance: Balance) {
        var tmpBalances = balances
        tmpBalances.append(balance)
        BalanceList.saveBalances(tmpBalances)
    }
    
    static func purgeBalanceList() {
        BalanceList.saveBalances([])
    }
    
    
}

fileprivate final class BalanceList: NSObject {
    
    let balances: [Balance]
    
    init(balances: [Balance]) {
        self.balances = balances
        super.init()
    }
    
}


// MARK: Persistance
extension BalanceList {
    
    private static var storePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docPath = paths.first!
        return (docPath as NSString).appendingPathComponent("SavedBalances")
    }
    
    static func loadBalances() -> [Balance] {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: storePath)) {
            let savedBalances = NSKeyedUnarchiver.unarchiveObject(with: data) as! BalanceList
            return savedBalances.balances
        } else {
            // Default
            return []
        }
    }
    
    static func saveBalances(_ balances: [Balance]) -> Void {
        
        NSKeyedArchiver.archiveRootObject(BalanceList(balances: balances), toFile: storePath)
    }
}

// MARK: NSCoding
extension BalanceList: NSCoding {
    
    private struct CodingKeys {
        static let balances = "balances"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let balances = aDecoder.decodeObject(forKey: CodingKeys.balances) as! [Balance]
        self.init(balances: balances)
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(balances, forKey: CodingKeys.balances)
    }
}

