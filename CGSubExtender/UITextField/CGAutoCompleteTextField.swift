//
//  CGAutocompleteTextField.swift
//  CGSubExtender
//
//  Created by Chase Gorectke on 1/25/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import UIKit

@objc public protocol CGAutoCompleteTextFieldDelegate: UITextFieldDelegate {
    func autoCompleteTextField(textField: CGAutoCompleteTextField, autoCompleteMatchFoundForTextField text: String)
    func autoCompleteTextField(textField: CGAutoCompleteTextField, dismissingAutoTextFieldWithFinalText text: String)
}

@objc public protocol CGAutoCompletePopoverDelegate {
    func currentAutoFieldText() -> String
    func initialAutoStrings() -> [String]
    func currentSelectionInPicker(selected: String)
    func returnSelectedString(selected: String)
}

@objc public class CGAutoCompleteTextField: UITextField, CGAutoCompletePopoverDelegate {
    
    public var autoController: CGAutoCompleteViewController!
    public var autoPopController: UIPopoverController!
    public var autoCompleteDictionary: [String]!
    
    var inputTemp: String = ""
    var outputTemp: String = ""
    
    public override func resignFirstResponder() -> Bool {
        autoPopController.dismissPopoverAnimated(true)
        return super.resignFirstResponder()
    }
    
    /* Auto Complete Protocol */
    
    public func startAutoCompleteWithDictionary(autoDict: [String], withPickerView pEnabled: Bool = false) {
        autoCompleteDictionary = autoDict
        self.addTarget(self, action: "autoComplete", forControlEvents: .EditingChanged)
        
        if pEnabled && autoCompleteDictionary.count > 0 && UIDevice.currentDevice().userInterfaceIdiom != .Phone {
            self.addTarget(self, action: "displayPopover", forControlEvents: .EditingDidBegin)
            autoController = CGAutoCompleteViewController(selectables: autoCompleteDictionary)
            autoController.delegate = self
            autoPopController = UIPopoverController(contentViewController: autoController)
            autoPopController.popoverContentSize = autoController.view.frame.size
        }
    }
    
    public func startAutoCompleteWithFile(fileName: String, withPickerView pEnabled: Bool = false) {
        let filePathTemp = NSBundle.mainBundle().pathForResource(fileName, ofType: "csv")
        if let filePath = filePathTemp {
            var error: NSError?
            let csvContentsTemp = NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding, error: &error)
            if let csvContents = csvContentsTemp {
                let fileContents = csvContents.componentsSeparatedByString(",") as [String]
            } else {
                if let e = error {
                    println("Error: \(e.description)")
                }
            }
        }
    }
    
    public func displayPopover() {
        if let s = superview { autoPopController.presentPopoverFromRect(frame, inView: s, permittedArrowDirections: .Any, animated: true) }
    }
    
    public func autoComplete() {
        let backspaced = inputTemp.hasPrefix(text)
        inputTemp = text
        
        if !backspaced && text.utf16Count > 0 {
            outputTemp = text
            var foundMatch = false
            
            //Try to find a match in list of majors
            for curMajor in autoCompleteDictionary {
                let options: NSStringCompareOptions = .CaseInsensitiveSearch | .AnchoredSearch
                let range = curMajor.rangeOfString(inputTemp, options: options)
                
                if let r = range {
                    inputTemp = curMajor.substringWithRange(r) //Since case may change
                    outputTemp = curMajor
                    autoController.completeAutoSelection(curMajor)
                    foundMatch = true
                    break
                }
            }
        
            // Set the text to output (will hold the matching major, or what was typed if no match found)
            // then select the portion of the string that was completed
            if let sTextRange = self.selectedTextRange {
                let start = sTextRange.start
                text = outputTemp
                let end = sTextRange.start
                let selectRange = self.textRangeFromPosition(start, toPosition: end)
                self.selectedTextRange = selectRange
            }
            
            // If a match was found in the majors list (and the popover is initialized), select that row in the popover
            if foundMatch {
                if let del = delegate {
                    let d = del as CGAutoCompleteTextFieldDelegate
                    d.autoCompleteTextField(self, autoCompleteMatchFoundForTextField: text)
                }
            }
        }
    }
    
    /* AutoCompletePopover Delegate */
    
    public func currentAutoFieldText() -> String {
        return self.text
    }
    
    public func initialAutoStrings() -> [String] {
        return autoCompleteDictionary
    }
    
    public func currentSelectionInPicker(selected: String) {
        self.text = selected
        self.inputTemp = selected
    }
    
    public func returnSelectedString(selected: String) {
        self.currentSelectionInPicker(selected)
        if let delTemp = delegate {
            let d = delTemp as CGAutoCompleteTextFieldDelegate
            d.autoCompleteTextField(self, dismissingAutoTextFieldWithFinalText: self.text)
        }
//        self.resignFirstResponder()
    }
}

@objc public class CGAutoCompleteViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    public var delegate: CGAutoCompletePopoverDelegate?
    
    public var autoPicker: UIPickerView!
    
    public var autoStrings: [String]
    public var selectedText: String = ""
    
    public required init(coder aDecoder: NSCoder) {
        autoStrings = [String]()
        super.init(coder: aDecoder)
    }
    
    public init(selectables: [String]) {
        autoStrings = selectables
        super.init()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        var width: CGFloat = 0.0
        if autoStrings.count > 0 {
            var lIndex = 0
            for (i, s) in enumerate(autoStrings) {
                if s.utf16Count > autoStrings[lIndex].utf16Count { lIndex = i }
            }
            width = self.generateWidthFromAttributesAndText(autoStrings[lIndex]) + (2 * 20.0)
        } else { width = 500.0 }
        if let appDel = UIApplication.sharedApplication().delegate {
            if let wT = appDel.window {
                if let w = wT { if width > w.frame.size.width { width = w.frame.size.width } }
            }
        }
        
        let frame = CGRectMake(0.0, 0.0, width, 216.0)
        view.frame = frame
        
        autoPicker = UIPickerView(frame: frame)
        autoPicker.delegate = self
        autoPicker.dataSource = self
        view.addSubview(autoPicker)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let d = delegate {
            selectedText = d.currentAutoFieldText()
            autoStrings = d.initialAutoStrings()
            if selectedText != "" { self.completeAutoSelection(selectedText) }
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        // Set the selected major back in the parent
        if let d = delegate {
            selectedText = autoStrings[autoPicker.selectedRowInComponent(0)]
            d.returnSelectedString(selectedText)
        }
        super.viewWillDisappear(animated)
    }
    
    /* CGAutoPicker Delegate */
    
    public func completeAutoSelection(selectedText: String) {
        // Select the row for the current auto-completed major
        if let f = find(autoStrings, selectedText) { autoPicker.selectRow(f, inComponent: 0, animated: false) }
    }
    
    /* Picker View Delegate */
    
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return autoStrings.count
    }
    
    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return autoStrings[row]
    }
    
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let d = delegate { d.currentSelectionInPicker(autoStrings[row]) }
    }
    
    /* Text Size Generation */
    
    public func generateWidthFromCurrentAttributesAndText() -> CGFloat {
        return self.generateWidthFromAttributesAndText(autoStrings[autoPicker.selectedRowInComponent(0)])
    }
    
    public func generateWidthFromAttributesAndText(text: String) -> CGFloat {
        let nString = text as NSString
        return nString.sizeWithAttributes([NSFontAttributeName : UIFont.systemFontOfSize(23.5)]).width
    }
}
