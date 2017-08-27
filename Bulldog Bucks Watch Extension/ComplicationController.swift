//
//  ComplicationController.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import ClockKit
import WatchKit
import RealmSwift


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        let balances = realm.objects(Balance.self)
        
        guard let firstBalance = balances.first else {
            // No data is cached yet
            handler(nil)
            return
        }
        
        handler(firstBalance.date)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        let balances = realm.objects(Balance.self)
        
        guard let lastBalance = balances.last else {
            // No data is cached yet
            handler(nil)
            return
        }
        
        handler(lastBalance.date)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        print("Get Current Timeline Entry Did Begin")
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        let balances = realm.objects(Balance.self)
        
        guard let balance = balances.last?.amount else {
            
            // In case there is no current balance set arbitary text
            switch complication.family {
            case .modularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
                modularTemplate.textProvider = CLKSimpleTextProvider(text: "BDB")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
                handler(timelineEntry)
            case .modularLarge:
                let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
                modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Bulldog Bucks")
                modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "BDB")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
                handler(timelineEntry)
            case .utilitarianSmall:
                handler(nil)
            case .utilitarianSmallFlat:
                let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
                utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "BDB")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
                handler(timelineEntry)
            case .utilitarianLarge:
                let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
                utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "BDB")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
                handler(timelineEntry)
            case .circularSmall:
                let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
                circularTemplate.textProvider = CLKSimpleTextProvider(text: "BDB")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: circularTemplate)
                handler(timelineEntry)
            case .extraLarge:
                handler(nil)
            }

            return
        }
        
        
        let dollars = balance.components(separatedBy: ".")[0]
          
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
            handler(timelineEntry)
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Bulldog Bucks")
            modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "$ \(balance)")
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
            handler(timelineEntry)
        case .utilitarianSmall:
            handler(nil)
        case .utilitarianSmallFlat:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
            handler(timelineEntry)
        case .utilitarianLarge:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "$ \(balance)")
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
            handler(timelineEntry)
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            circularTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: circularTemplate)
            handler(timelineEntry)
        case .extraLarge:
            handler(nil)
        }
        print("Get Current Timeline Entry Did End")

    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        let balances = realm.objects(Balance.self)
        let balanceArray = Array(balances)
        
        var sortedBalances = balanceArray.filter {
            $0.date.compare(date) == .orderedAscending
        }
        
        if sortedBalances.count > limit {
            // Remove from the front
            let numberToRemove = sortedBalances.count - limit
            sortedBalances.removeSubrange(0..<numberToRemove)
        }
    
        let entries = sortedBalances.flatMap { balance in
            self.timelineEntryFor(balance, family: complication.family)
        }

        handler(entries)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bdbMeter")
        
        let realmPath = directory?.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        let balances = realm.objects(Balance.self)
        let balanceArray = Array(balances)
        
        var sortedBalances = balanceArray.filter {
            $0.date.compare(date) == .orderedDescending
        }
        
        if sortedBalances.count > limit {
            // Remove from the back
            sortedBalances.removeSubrange(limit..<sortedBalances.count)
        }
        
        let entries = sortedBalances.flatMap { balance in
            timelineEntryFor(balance, family: complication.family)
        }
        
        handler(entries)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        var template: CLKComplicationTemplate?
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Bulldog Bucks")
            modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "Updating...")
            modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
            template = modularTemplate
        case .utilitarianSmall:
            break
        case .utilitarianSmallFlat:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = utilitarianTemplate
        case .utilitarianLarge:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "Updating...")
            template = utilitarianTemplate
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            circularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = circularTemplate
        case .extraLarge:
            break
        }
        handler(template)
    }
    
    // MARK: Template Creation
    func timelineEntryFor(_ balance: Balance, family: CLKComplicationFamily) -> CLKComplicationTimelineEntry? {
        
        print(balance.amount)
        let dollars = balance.amount.components(separatedBy: ".")[0]
        
        switch family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            return CLKComplicationTimelineEntry(date: balance.date, complicationTemplate: modularTemplate)
            
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Bulldog Bucks")
            modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "$ \(balance)")
            return CLKComplicationTimelineEntry(date: balance.date, complicationTemplate: modularTemplate)
            
        case .utilitarianSmallFlat:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            return CLKComplicationTimelineEntry(date: balance.date, complicationTemplate: utilitarianTemplate)
            
        case .utilitarianLarge:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "$ \(balance)")
            return CLKComplicationTimelineEntry(date: balance.date, complicationTemplate: utilitarianTemplate)
            
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            circularTemplate.textProvider = CLKSimpleTextProvider(text: "$\(dollars)")
            return CLKComplicationTimelineEntry(date: balance.date, complicationTemplate: circularTemplate)
            
        default: return nil
            
        }
        
        
    }
    
}
