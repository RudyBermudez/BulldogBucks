//
//  ComplicationController.swift
//  Bulldog Buck Balance Extension
//
//  Created by Rudy Bermudez on 3/11/17.
//
//

import ClockKit


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
        // Call the handler with the current timeline entry
        handler(nil)
        guard let credentials = keychain.getCredentials() else {
            handler(nil)
            return
        }
        
        
        self.client.getBulldogBucks(withStudentID: credentials.studentID, withPIN: credentials.PIN).then { (balance) -> Void in
            
            print("Complication Updated")
            
            switch complication.family {
            case .modularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
                modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(balance)")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
                handler(timelineEntry)
            case .modularLarge:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
                modularTemplate.textProvider = CLKSimpleTextProvider(text: "$\(balance)")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: modularTemplate)
                handler(timelineEntry)
            case .utilitarianSmall:
                handler(nil)
            case .utilitarianSmallFlat:
                let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
                utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "\(balance)")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
                handler(timelineEntry)
            case .utilitarianLarge:
                let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
                utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "$\(balance)")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: utilitarianTemplate)
                handler(timelineEntry)
            case .circularSmall:
                let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
                circularTemplate.textProvider = CLKSimpleTextProvider(text: "\(balance)")
                let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: circularTemplate)
                handler(timelineEntry)
            case .extraLarge:
                handler(nil)
            }
            
            }.catch(execute: { (_) in
                handler(nil)
            })
        
        
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
        handler(nil)
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .utilitarianSmall:
            template = nil
        case .utilitarianSmallFlat:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = utilitarianTemplate
        case .utilitarianLarge:
            let utilitarianTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = utilitarianTemplate
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            circularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = circularTemplate
        case .extraLarge:
            template = nil
        }
        handler(template)
    }
    
}
