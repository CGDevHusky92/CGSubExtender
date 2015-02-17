//
//  NSDate+STRING.swift
//  CGSubExtender
//
//  Created by Charles Gorectke on 11/18/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import Foundation

extension NSDate {
    
    var dateFormatter: NSDateFormatter {
        struct dateFormatterInstance {
            static var onceToken : dispatch_once_t = 0
            static var instance : NSDateFormatter?
        }
        dispatch_once(&dateFormatterInstance.onceToken) {
            dateFormatterInstance.instance = NSDateFormatter()
            dateFormatterInstance.instance?.timeZone = NSTimeZone(name: "UTC")
            dateFormatterInstance.instance?.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatterInstance.instance?.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        }
        return dateFormatterInstance.instance!
    }
    
    
    public convenience init(string: String) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        let dateTemp = dateFormatter.dateFromString(string)
        if let date = dateTemp {
            self.init(timeInterval: 0, sinceDate: date)
        } else {
            self.init()
        }
    }
    
    public func stringFromDateWithFormat(format: String) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(self)
    }
    
    public func stringFromDate() -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.stringFromDate(self)
    }
    
    public func prettyDateString() -> String {
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.stringFromDate(self)
    }
    
    public func prettyTimeString() -> String {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.stringFromDate(self)
    }
    
    public func prettyDateAndTimeString() -> String {
        dateFormatter.dateFormat = "h:mm a 'on' MM/dd/yyyy"
        return dateFormatter.stringFromDate(self)
    }
    
    public class func year() -> String {
        let df = NSDateFormatter()
        df.timeZone = NSTimeZone(name: "UTC")
        df.dateFormat = "yyyy"
        return df.stringFromDate(NSDate())
    }
}
