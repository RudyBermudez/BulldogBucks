//
//  Transaction.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 9/2/17.
//
//

import Foundation


enum TransactionType: String {
    case sale
    case deposit
}

struct Transaction {
    
    let date: Date
    
    let venue: String
    
    let amount: Double
    
    fileprivate let type: TransactionType
    
    
    init?(date: String, venue: String, amount: String, type: String) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm:ss a"
        
        guard let amountDouble = Double(amount
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            ),
            let formattedDate = dateFormatter.date(from: date),
            let transactionType = TransactionType(rawValue: type) else {
            return nil
        }
        
        self.amount = amountDouble
        self.venue = venue
        self.date = formattedDate
        self.type = transactionType
    }
    
}

extension Transaction: CustomStringConvertible {
    var description: String {
        return "\n\(prettyDate)  \(venue)  \(prettyAmount)"
    }
    
    var prettyDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy hh:mm a"
        return dateFormatter.string(from: date)
    }
    
    var prettyAmount: String {
        switch type {
        case .deposit:
            return String(format: "+$%.2f", amount)
        case .sale:
            return String(format: "-$%.2f", amount)
        }
    }
}
