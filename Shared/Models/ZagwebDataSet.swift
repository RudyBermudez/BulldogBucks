//
//  Balance.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 8/27/17.
//
//

import Foundation

final class ZagwebDataSet: NSObject {
    
    let bucksRemaining: String
    let swipesRemaining: String
    let date: Date
    
    init(bucksRemaining: String, swipesRemaining: String,  date: Date) {
        self.bucksRemaining = bucksRemaining
        self.date = date
        self.swipesRemaining = swipesRemaining
        super.init()
    }
    
}


// MARK: For Complication
extension ZagwebDataSet {
    
    var shortTextBucksForComplication: String {
        return bucksRemaining.components(separatedBy: ".")[0]
    }
    
    var longTextBucksForComplication: String {
        return bucksRemaining
    }
}

// MARK: NSCoding
extension ZagwebDataSet: NSCoding {
    
    private struct CodingKeys {
        static let bucksRemaining = "bucksRemaining"
        static let swipesRemaining = "swipesRemaining"
        static let date = "date"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let date = aDecoder.decodeObject(forKey: CodingKeys.date) as! Date
        let bucksRemaining = aDecoder.decodeObject(forKey: CodingKeys.bucksRemaining) as! String
        let swipesRemaining = aDecoder.decodeObject(forKey: CodingKeys.swipesRemaining) as! String
        self.init(bucksRemaining: bucksRemaining, swipesRemaining: swipesRemaining, date: date)
        
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(date, forKey: CodingKeys.date)
        encoder.encode(bucksRemaining, forKey: CodingKeys.bucksRemaining)
        encoder.encode(swipesRemaining, forKey: CodingKeys.swipesRemaining)
    }
}
