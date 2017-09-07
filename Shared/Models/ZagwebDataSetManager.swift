//
//  BalanceList.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 8/27/17.
//
//

import Foundation


final class ZagwebDataSetManager {
    
    static var dataSets: [ZagwebDataSet] {
        get {
            return ZagwebDataSetList.loadDataSets()
        }
    }

    static func add(dataSet: ZagwebDataSet) {
        var tmp = dataSets
        tmp.append(dataSet)
        ZagwebDataSetList.save(dataSets: tmp)
    }
    
    static func purgeDataSets() {
        ZagwebDataSetList.save(dataSets: [])
    }
    
    
}

fileprivate final class ZagwebDataSetList: NSObject {
    
    let dataSets: [ZagwebDataSet]
    
    init(dataSets: [ZagwebDataSet]) {
        self.dataSets = dataSets
        super.init()
    }
    
}


// MARK: Persistance
extension ZagwebDataSetList {
    
    private static var storePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docPath = paths.first!
        return (docPath as NSString).appendingPathComponent("SavedZagwebDataSets")
    }
    
    static func loadDataSets() -> [ZagwebDataSet] {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: storePath)),
            let savedDataSets = NSKeyedUnarchiver.unarchiveObject(with: data) as? ZagwebDataSetList {
            return savedDataSets.dataSets
        } else {
            // Default
            return []
        }
    }
    
    static func save(dataSets: [ZagwebDataSet]) -> Void {
        
        NSKeyedArchiver.archiveRootObject(ZagwebDataSetList(dataSets: dataSets), toFile: storePath)
    }
}

// MARK: NSCoding
extension ZagwebDataSetList: NSCoding {
    
    private struct CodingKeys {
        static let dataSets = "ZagwebDataSets"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let dataSets = aDecoder.decodeObject(forKey: CodingKeys.dataSets) as! [ZagwebDataSet]
        self.init(dataSets: dataSets)
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(dataSets, forKey: CodingKeys.dataSets)
    }
}

