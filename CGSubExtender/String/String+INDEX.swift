//
//  String+INDEX.swift
//  CGSubExtender
//
//  Created by Chase Gorectke on 1/25/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import Foundation

extension String {
    public var length: Int { get { return count(self) } }
    
    public func contains(s: String) -> Bool {
        return (self.rangeOfString(s) != nil) ? true : false
    }
    
    public func replace(target: String, withString: String) -> String {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    public subscript (i: Int) -> Character {
        get {
            let index = advance(startIndex, i)
            return self[index]
        }
    }
    
    public subscript (r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(self.startIndex, r.endIndex - 1)
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
    
    public func subString(startIndex: Int, length: Int) -> String {
        var start = advance(self.startIndex, startIndex)
        var end = advance(self.startIndex, startIndex + length)
        return self.substringWithRange(Range<String.Index>(start: start, end: end))
    }
    
    public func indexOf(target: String) -> Int {
        var range = self.rangeOfString(target)
        if let range = range {
            return distance(self.startIndex, range.startIndex)
        } else {
            return -1
        }
    }
    
    public func indexOf(target: String, startIndex: Int) -> Int {
        var startRange = advance(self.startIndex, startIndex)
        var range = self.rangeOfString(target, options: NSStringCompareOptions.LiteralSearch, range: Range<String.Index>(start: startRange, end: self.endIndex))
        
        if let range = range {
            return distance(self.startIndex, range.startIndex)
        } else {
            return -1
        }
    }
    
    public func lastIndexOf(target: String) -> Int {
        var index = -1
        var stepIndex = self.indexOf(target)
        while stepIndex > -1 {
            index = stepIndex
            if stepIndex + target.length < self.length {
                stepIndex = indexOf(target, startIndex: stepIndex + target.length)
            } else {
                stepIndex = -1
            }
        }
        return index
    }
    
    public func isMatch(regex: String, options: NSRegularExpressionOptions) -> Bool {
        var error: NSError?
        var expTemp = NSRegularExpression(pattern: regex, options: options, error: &error)
        if let e = error {
            println(e.description)
        } else {
            if let exp = expTemp {
                var matchCount = exp.numberOfMatchesInString(self, options: nil, range: NSMakeRange(0, self.length))
                return matchCount > 0
            }
        }
        return false
    }
    
    public func getMatches(regex: String, options: NSRegularExpressionOptions) -> [NSTextCheckingResult]? {
        var error: NSError?
        var expTemp = NSRegularExpression(pattern: regex, options: options, error: &error)
        if let e = error {
            println(e.description)
        } else {
            if let exp = expTemp {
                let matches = exp.matchesInString(self, options: nil, range: NSMakeRange(0, self.length)) as! [NSTextCheckingResult]
                return matches
            }
        }
        return nil
    }
    
    private var vowels: [String] { get { return ["a", "e", "i", "o", "u"] } }
    private var consonants: [String] { get { return ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"] } }
    
    /*
    public func pluralize(count: Int) -> String {
        if count == 1 {
            return self
        } else {
            var lastChar = self.subString(self.length - 1, length: 1)
            var secondToLastChar = self.subString(self.length - 2, length: 1)
            var prefix = "", suffix = ""
            
            if lastChar.lowercaseString == "y" && vowels.filter({x in x == secondToLastChar}).count == 0 {
                prefix = self[0...self.length - 1]
                suffix = "ies"
            } else if lastChar.lowercaseString == "s" || (lastChar.lowercaseString == "o" && consonants.filter({x in x == secondToLastChar}).count > 0) {
                prefix = self[0...self.length]
                suffix = "es"
            } else {
                prefix = self[0...self.length]
                suffix = "s"
            }
            
            return prefix + (lastChar != lastChar.uppercaseString ? suffix : suffix.uppercaseString)
        }
    }*/
}
