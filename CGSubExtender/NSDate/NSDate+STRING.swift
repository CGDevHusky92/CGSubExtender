//
//  NSDate+STRING.swift
//  CGSubExtender
//
//  Created by Charles Gorectke on 11/18/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import Foundation

extension NSDate {
    
    class var dateFormatter: NSDateFormatter {
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
        NSDate.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateTemp = NSDate.dateFormatter.dateFromString(string)
        if let date = dateTemp {
            self.init(timeInterval: 0, sinceDate: date)
        } else {
            self.init()
        }
    }
    
    public func stringFromDateWithFormat(format: String) -> String {
        NSDate.dateFormatter.dateFormat = format
        return NSDate.dateFormatter.stringFromDate(self)
    }
    
    public func stringFromDate() -> String {
        NSDate.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return NSDate.dateFormatter.stringFromDate(self)
    }
    
    public func prettyDateString() -> String {
        NSDate.dateFormatter.dateFormat = "dd/MM/yyyy"
        return NSDate.dateFormatter.stringFromDate(self)
    }
    
    public func prettyTimeString() -> String {
        NSDate.dateFormatter.dateFormat = "HH:mm"
        return NSDate.dateFormatter.stringFromDate(self)
    }
    
    public func prettyDateAndTimeString() -> String {
        NSDate.dateFormatter.dateFormat = "h:mm a 'on' MM/dd/yyyy"
        return NSDate.dateFormatter.stringFromDate(self)
    }
    
    public class func year() -> String {
        NSDate.dateFormatter.dateFormat = "yyyy"
        return NSDate.dateFormatter.stringFromDate(NSDate())
    }
}
