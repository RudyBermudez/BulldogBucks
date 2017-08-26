//
//  ComplicationController.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import ClockKit
import WatchKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let keychain = BDBKeychain.watchKeychain
    let client = ZagwebClient()
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        print("Get Current Timeline Entry Did Begin")
        
        guard let balance = UserDefaults.standard.string(forKey: "lastBalance") else {
            
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
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
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
    
}
