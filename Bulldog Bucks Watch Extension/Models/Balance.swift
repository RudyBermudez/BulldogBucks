//
//  Balance.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 8/27/17.
//
//

import Foundation

final class Balance: NSObject {
    
    let amount: String
    let date: Date
    
    init(amount: String, date: Date) {
        self.amount = amount
        self.date = date
        super.init()
    }
    
}


// MARK: For Complication
extension Balance {
    
    var shortTextForComplication: String {
        return amount.components(separatedBy: ".")[0]
    }
    
    var longTextForComplication: String {
        return amount
    }
}

// MARK: NSCoding
extension Balance: NSCoding {
    
    private struct CodingKeys {
        static let amount = "amount"
        static let date = "date"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let date = aDecoder.decodeObject(forKey: CodingKeys.date) as! Date
        let amount = aDecoder.decodeObject(forKey: CodingKeys.amount) as! String
        self.init(amount: amount, date: date)
        
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(date, forKey: CodingKeys.date)
        encoder.encode(amount, forKey: CodingKeys.amount)
    }
}
