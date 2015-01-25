//
//  CGAttributedTableView.swift
//  CGAttributeEditor
//
//  Created by Chase Gorectke on 11/11/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit

@objc public protocol CGAttributedTableViewDelegate {
    
    func attributedTableView(tableView: CGAttributedTableView, updateDescriptionAtIndexPath indexPath: NSIndexPath, withData data: AnyObject)
    func attributedTableView(tableView: CGAttributedTableView, buttonPressedAtIndexPath indexPath: NSIndexPath)
    
}

@objc public protocol CGAttributedTableViewDataSource {
    
    func numberOfSectionsInAttributedTableView(tableView: CGAttributedTableView) -> Int
    func attributedTableView(tableView: CGAttributedTableView, numberOfRowsInSection section: Int) -> Int
    
    func attributedTableView(tableView: CGAttributedTableView, cellDescriptionForRowAtIndexPath indexPath: NSIndexPath) -> CGAttributedTableViewCellDescription
    
    optional func attributedTableView(tableView: CGAttributedTableView, titleForHeaderInSection section: Int) -> String?
    
}

public class CGAttributedTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    public var attributedDelegate: CGAttributedTableViewDelegate?
    public var attributedDataSource: CGAttributedTableViewDataSource?
    
    var _singleEditingMode: Bool = false
    public var singleEditingMode: Bool {
        get { return _singleEditingMode }
    }
    
    var _editingModeEnabled: Bool = false
    public var editingModeEnabled: Bool {
        get { return _editingModeEnabled }
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
        dataSource = self
        
        self.registerClass(CGTextFieldTableViewCell.self, forCellReuseIdentifier: "CGAttributedTextFieldCell")
        self.registerClass(CGAutoCompleteTableViewCell.self, forCellReuseIdentifier: "CGAttributedAutoCompleteCell")
        self.registerClass(CGTextViewTableViewCell.self, forCellReuseIdentifier: "CGAttributedTextViewCell")
        self.registerClass(CGPickerTableViewCell.self, forCellReuseIdentifier: "CGAttributedPickerCell")
        self.registerClass(CGDatePickerTableViewCell.self, forCellReuseIdentifier: "CGAttributedDatePickerCell")
        self.registerClass(CGSwitchTableViewCell.self, forCellReuseIdentifier: "CGAttributedSwitchCell")
        self.registerClass(CGButtonTableViewCell.self, forCellReuseIdentifier: "CGAttributedButtonCell")
    }
    
    public func toggleEditingMode() {
        _editingModeEnabled = !_editingModeEnabled
        self.reloadData()
    }
    
    /* Table View Data Source */
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let dataSrc = attributedDataSource {
            return dataSrc.numberOfSectionsInAttributedTableView(self)
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let dataSrc = attributedDataSource {
            return dataSrc.attributedTableView?(self, titleForHeaderInSection: section)
        }
        return nil
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dataSrc = attributedDataSource {
            return dataSrc.attributedTableView(self, numberOfRowsInSection: section)
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var prop: String = ""
        var descTemp: String?
        var pHolderTemp: String?
        var pHolderDataTemp: [String]?
        var type: CGAttributedTableViewCellType = CGAttributedTableViewCellType.None
        
        if let dataSrc = attributedDataSource {
            let cellDescription = dataSrc.attributedTableView(self, cellDescriptionForRowAtIndexPath: indexPath)
            type = cellDescription.cellType
            prop = cellDescription.property
            descTemp = cellDescription.descriptionText
            pHolderTemp = cellDescription.placeHolder
            pHolderDataTemp = cellDescription.placeHolderData
        }
        
        let cell: CGAttributedTableViewCell = tableView.dequeueReusableCellWithIdentifier(type.simpleDescription(), forIndexPath: indexPath) as CGAttributedTableViewCell
        cell.delegate = attributedDelegate
        cell.tableView = self
        cell.keyboardType = type.keyboardType()
        cell.propertyText = prop
        
        if let pHolder = pHolderTemp {
            cell.placeholderText = pHolder
        }
        
        if let pHolderData = pHolderDataTemp {
            cell.placeholderData = pHolderData
        }
        
        if let desc = descTemp {
            cell.descriptionText = desc
        }
        
        if cell.reuseIdentifier != CGAttributedTableViewCellType.Button.simpleDescription() {
            if _singleEditingMode {
                if selectedCell == nil && cell.editMode {
                    cell.toggleEditingProperty()
                }
            } else {
                if _editingModeEnabled && !cell.editMode {
                    cell.toggleEditingProperty()
                } else if !_editingModeEnabled && cell.editMode {
                    cell.toggleEditingProperty()
                }
            }
        } else {
            cell.descriptionText = prop
        }
        
        return cell
    }
    
    /* Table View Delegate */
    
    var selectedCell: CGAttributedTableViewCell?
    var selectedIndexPath: NSIndexPath?
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let cell: CGAttributedTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as CGAttributedTableViewCell
        if _singleEditingMode {
            if cell.editMode {
                selectedCell = nil
                selectedIndexPath = nil
                cell.toggleEditingProperty()
            } else {
                if let sCell = selectedCell {
                    sCell.toggleEditingProperty()
                }
                selectedCell = cell
                selectedIndexPath = indexPath
                cell.toggleEditingProperty()
            }
        } else {
            if cell.reuseIdentifier == CGAttributedTableViewCellType.Button.simpleDescription() {
                cell.toggleEditingProperty()
            } else {
                cell.assignFirstResponder()
            }
        }
    }
    
    /* ScrollView Delegate */
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let sView = self.superview {
            sView.endEditing(true)
        }
    }

    /* CGAttributedTableViewCell Delegate */
    
    public func attributedCell(tableViewCell: CGAttributedTableViewCell, updateIndexPath indexPath: NSIndexPath, withData data: AnyObject) {
        if let del = attributedDelegate {
            del.attributedTableView(self, updateDescriptionAtIndexPath: indexPath, withData: data)
        }
    }
    
    public func attributedCell(tableViewCell: CGAttributedTableViewCell, buttonPressedAtIndexPath indexPath: NSIndexPath) {
        if let del = attributedDelegate {
            del.attributedTableView(self, buttonPressedAtIndexPath: indexPath)
        }
    }
    
    /* Remove Ambigous Row Height Warning */
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let dataSrc = attributedDataSource {
            let cellType = dataSrc.attributedTableView(self, cellDescriptionForRowAtIndexPath: indexPath).cellType
            if cellType == CGAttributedTableViewCellType.TextView {
                return 60.0
            } else if cellType == CGAttributedTableViewCellType.Picker || cellType == CGAttributedTableViewCellType.DatePicker {
                if _singleEditingMode {
                    if let sCell = selectedCell { if sCell.editMode { if let s = selectedIndexPath { if indexPath == s { return 162.0 } } } }
                } else { if _editingModeEnabled { return 162.0 } }
            }
        }
        return 44.0
    }
    
    public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let dataSrc = attributedDataSource {
            let cellType = dataSrc.attributedTableView(self, cellDescriptionForRowAtIndexPath: indexPath).cellType
            if cellType == CGAttributedTableViewCellType.TextView {
                return 60.0
            } else if cellType == CGAttributedTableViewCellType.Picker || cellType == CGAttributedTableViewCellType.DatePicker {
                if _singleEditingMode {
                    if let sCell = selectedCell { if sCell.editMode { if let s = selectedIndexPath { if indexPath == s { return 162.0 } } } }
                } else { if _editingModeEnabled { return 162.0 } }
            }
        }
        return 44.0
    }
}

public enum CGAttributedTableViewCellType: Int {
    case TextField = 1
    case TextFieldNumber, TextFieldPhone, TextFieldEmail, AutoComplete
    case TextView, Picker, DatePicker, Switch, Button, None
    
    func simpleDescription() -> String {
        switch self {
        case .TextField, .TextFieldNumber, .TextFieldPhone, .TextFieldEmail:
            return "CGAttributedTextFieldCell"
        case .AutoComplete:
            return "CGAttributedAutoCompleteCell"
        case .TextView:
            return "CGAttributedTextViewCell"
        case .Picker:
            return "CGAttributedPickerCell"
        case .DatePicker:
            return "CGAttributedDatePickerCell"
        case .Switch:
            return "CGAttributedSwitchCell"
        case .Button:
            return "CGAttributedButtonCell"
        default:
            return "CGAttributedCellNone"
        }
    }
    
    func keyboardType() -> UIKeyboardType {
        switch self {
        case .TextField:
            return UIKeyboardType.Default
        case .TextFieldNumber:
            return UIKeyboardType.NumberPad
        case .TextFieldPhone:
            return UIKeyboardType.PhonePad
        case .TextFieldEmail:
            return UIKeyboardType.EmailAddress
        case .TextView:
            return UIKeyboardType.Default
        default:
            return UIKeyboardType.Default
        }
    }
}

@objc public class CGAttributedTableViewCellDescription {
    public var cellType: CGAttributedTableViewCellType
    public var property: String
    public var descriptionText: String?
    public var placeHolder: String?
    public var placeHolderData: [String]?
    
    public var valid: Bool = true
    public var invalidDescription: String?
    
    public init(type: CGAttributedTableViewCellType = .None, withProperty prop: String = "", andDescription desc: String? = nil, withPlaceHolder plHolder: String? = nil, andPlaceHolderData plData: [String]? = nil) {
        cellType = type
        property = prop
        descriptionText = desc
        placeHolder = plHolder
        placeHolderData = plData
    }
}

public class CGAttributedTableViewCell: UITableViewCell {
    
    var propertyLabel: UILabel!
    var descriptionLabel: UILabel!
    
    var propertyWidthConstraint: NSLayoutConstraint!
    var descriptionWidthConstraint: NSLayoutConstraint!
    
    var delegate: CGAttributedTableViewDelegate?
    weak var tableView: CGAttributedTableView?
    
    var propertyText: String? {
        get {
            return propertyLabel.text
        }
        set(newPropertyText) {
            propertyLabel.text = newPropertyText
            self.propertyTextSet()
        }
    }
    
    var descriptionText: String? {
        get {
            return descriptionLabel.text
        }
        set(newDescriptionText) {
            descriptionLabel.text = newDescriptionText
            self.descriptionTextSet()
        }
    }
    
    var _keyboardType: UIKeyboardType?
    var keyboardType: UIKeyboardType? {
        get { return _keyboardType }
        set(newKeyboardType) {
            _keyboardType = newKeyboardType
            self.keyboardTypeSet()
        }
    }
    
    var _placeholderText: String?
    var placeholderText: String? {
        get {
            return _placeholderText
        }
        set(newPlaceHolder) {
            _placeholderText = newPlaceHolder
            self.placeHolderTextSet()
        }
    }
    
    var _placeholderData: [String]?
    var placeholderData: [String]? {
        get {
            return _placeholderData
        }
        set(newPlaceHolder) {
            _placeholderData = newPlaceHolder
            self.placeHolderDataSet()
        }
    }
    
    var editMode = false
    var viewProperties: [UIView]!
    var editProperties: [UIView]!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewProperties = [UIView]()
        editProperties = [UIView]()
        
        propertyLabel = UILabel()
        descriptionLabel = UILabel()
        
        propertyLabel.font = UIFont.systemFontOfSize(17.0)
        descriptionLabel.font = UIFont.systemFontOfSize(17.0)
        descriptionLabel.textAlignment = NSTextAlignment.Right
        
        propertyLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        descriptionLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.addSubview(propertyLabel)
        self.addSubview(descriptionLabel)
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(11.0)-[propertyLabel]-(10.0)-[descriptionLabel]-(8.0)-|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "propertyLabel" : self.propertyLabel, "descriptionLabel" : self.descriptionLabel ]))
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[propertyLabel(22.0)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "propertyLabel" : self.propertyLabel]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[descriptionLabel(22.0)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "descriptionLabel" : self.descriptionLabel]))
        
        if let windowFrame = UIApplication.sharedApplication().keyWindow?.frame {
            let propWidth: CGFloat = (windowFrame.width - 29.0) * 0.44
            let descWidth: CGFloat = (windowFrame.width - 29.0) * 0.56
            
            propertyWidthConstraint = NSLayoutConstraint(item: propertyLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: propWidth)
            propertyLabel.addConstraint(propertyWidthConstraint)
            
            descriptionWidthConstraint = NSLayoutConstraint(item: descriptionLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: descWidth)
            descriptionLabel.addConstraint(descriptionWidthConstraint)
        }
        
        let propYConstraint = NSLayoutConstraint(item: propertyLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let descYConstraint = NSLayoutConstraint(item: descriptionLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)
        self.addConstraint(propYConstraint)
        self.addConstraint(descYConstraint)
        
        viewProperties.append(descriptionLabel)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let windowFrame = UIApplication.sharedApplication().keyWindow?.frame {
            propertyWidthConstraint.constant = (windowFrame.width - 29.0) * 0.44
            descriptionWidthConstraint.constant = (windowFrame.width - 29.0) * 0.56
        }
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.None.simpleDescription() }
    }
    
    func toggleEditingProperty() {
        self.resignAllFirstResponders()
        for prop in editProperties {
            prop.hidden = editMode
        }
        editMode = !editMode
        for prop in viewProperties {
            prop.hidden = editMode
        }
    }
    
    func propertyTextSet() { }
    
    func descriptionTextSet() { }
    
    func keyboardTypeSet() { }
    
    func placeHolderTextSet() { }
    
    func placeHolderDataSet() { }
    
    func assignFirstResponder() { }
    
    func resignAllFirstResponders() { }
}

public class CGTextFieldTableViewCell: CGAttributedTableViewCell {
    
    var textField: UITextField!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textField = UITextField()
        textField.setTranslatesAutoresizingMaskIntoConstraints(false)
        textField.textAlignment = NSTextAlignment.Center
        textField.borderStyle = UITextBorderStyle.Bezel
        textField.hidden = true
        
        self.addSubview(textField)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[textField(30)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "textField" : self.textField ]))
        let widthConstraint = NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let xConstraint = NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        self.addConstraint(widthConstraint)
        self.addConstraint(xConstraint)
        self.addConstraint(yConstraint)
        
        editProperties.append(textField)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkForAndSaveChanges", name: UITextFieldTextDidEndEditingNotification, object: textField)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.TextField.simpleDescription() }
    }
    
    override func toggleEditingProperty() {
        super.toggleEditingProperty()
        if !editMode {
            if textField.text != "" {
                if let del = delegate {
                    if let tView = tableView {
                        let indexPathTemp = tView.indexPathForCell(self)
                        if let indexPath = indexPathTemp {
                            del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: textField.text)
                            textField.text = ""
                        }
                    }
                }
            }
        }
    }
    
    override func keyboardTypeSet() {
        if let k = keyboardType { textField.keyboardType = k }
    }
    
    override func descriptionTextSet() {
        if let d = descriptionText { textField.text = d }
    }
    
    override func placeHolderTextSet() {
        textField.placeholder = placeholderText
    }
    
    override func assignFirstResponder() {
        textField.becomeFirstResponder()
    }
    
    override func resignAllFirstResponders() {
        textField.resignFirstResponder()
    }
    
    /* Text Field Delegate */
    
    func checkForAndSaveChanges() {
        if textField.text != "" || textField.text != descriptionText {
            if let del = delegate {
                if let tView = tableView {
                    let indexPathTemp = tView.indexPathForCell(self)
                    if let indexPath = indexPathTemp {
                        del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: textField.text)
                    }
                }
            }
        }
    }
}

public class CGAutoCompleteTableViewCell: CGTextFieldTableViewCell, UITextFieldAutoDelegate {
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textField.delegate = self
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.AutoComplete.simpleDescription() }
    }
    
    override func placeHolderDataSet() {
        if let pData = placeholderData {
            if pData.count > 0 {
                textField.startAutoCompleteWithFile(pData[0], withPickerView: true)
            }
        }
    }
    
    public func textField(textField: UITextField!, autoCompleteMatchFoundForTextField text: String!) { }
    
    public func textField(textField: UITextField!, dismissingAutoTextFieldWithFinalText text: String!) {
        if textField.text != "" {
            if let del = delegate {
                if let tView = tableView {
                    let indexPathTemp = tView.indexPathForCell(self)
                    if let indexPath = indexPathTemp {
                        del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: textField.text)
                    }
                }
            }
        }
    }
}

public class CGTextViewTableViewCell: CGAttributedTableViewCell, UITextViewDelegate {
    
    var textView: UITextView!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewProperties.removeLast()
        descriptionLabel.hidden = true
        
        textView = UITextView()
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        textView.delegate = self
        textView.backgroundColor = UIColor.lightGrayColor()
        textView.editable = false
        
        self.addSubview(textView)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[textView(52)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "textView" : self.textView ]))
        let widthConstraint = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let xConstraint = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        self.addConstraint(widthConstraint)
        self.addConstraint(xConstraint)
        self.addConstraint(yConstraint)
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.TextView.simpleDescription() }
    }
    
    override func descriptionTextSet() {
        textView.text = descriptionText
    }
    
    override func assignFirstResponder() {
        textView.becomeFirstResponder()
    }
    
    override func resignAllFirstResponders() {
        textView.resignFirstResponder()
    }
    
    override func toggleEditingProperty() {
        textView.resignFirstResponder()
        super.toggleEditingProperty()
        if editMode {
            textView.editable = true
        } else {
            textView.editable = false
            if let del = delegate {
                if let tView = tableView {
                    let indexPathTemp = tView.indexPathForCell(self)
                    if let indexPath = indexPathTemp {
                        del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: textView.text)
                    }
                }
            }
        }
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        if let del = delegate {
            if let tView = tableView {
                let indexPathTemp = tView.indexPathForCell(self)
                if let indexPath = indexPathTemp {
                    del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: textView.text)
                }
            }
        }
    }
}

public class CGPickerTableViewCell: CGAttributedTableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var picker: UIPickerView!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        picker = UIPickerView()
        picker.setTranslatesAutoresizingMaskIntoConstraints(false)
        picker.delegate = self
        picker.dataSource = self
        picker.hidden = true
        
        self.addSubview(picker)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[picker(162)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "picker" : self.picker ]))
        let widthConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let xConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        self.addConstraint(widthConstraint)
        self.addConstraint(xConstraint)
        self.addConstraint(yConstraint)
        
        editProperties.append(picker)
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.Picker.simpleDescription() }
    }
    
    override func descriptionTextSet() {
        if let descText = descriptionText {
            if let pData = placeholderData {
                for (index, value) in enumerate(pData) {
                    if descText == value {
                        picker.selectRow(index, inComponent: 0, animated: false)
                        break
                    }
                }
            }
        }
    }
    
    /* Picker Data Source */
    
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let pData = placeholderData {
            return pData.count
        }
        return 0
    }
    
    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if let pData = placeholderData {
            return pData[row]
        }
        return ""
    }
    
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let del = delegate {
            if let tView = tableView {
                let indexPathTemp = tView.indexPathForCell(self)
                if let indexPath = indexPathTemp {
                    if let pData = placeholderData {
                        if pData.count > row {
                            del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: pData[row])
                        }
                    }
                }
            }
        }
    }
    
}

public class CGDatePickerTableViewCell: CGAttributedTableViewCell, UIPickerViewDelegate {
    
    var picker: UIDatePicker!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        picker = UIDatePicker()
        picker.setTranslatesAutoresizingMaskIntoConstraints(false)
        picker.hidden = true
        
        self.addSubview(picker)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[picker(162)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "picker" : self.picker ]))
        let widthConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let xConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: picker, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: descriptionLabel, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        self.addConstraint(widthConstraint)
        self.addConstraint(xConstraint)
        self.addConstraint(yConstraint)
        
        editProperties.append(picker)
        picker.addTarget(self, action: "checkForAndSaveChanges", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.DatePicker.simpleDescription() }
    }
    
    override func descriptionTextSet() {
        if let descText = descriptionText {
            let date = NSDate(string: descText)
            picker.setDate(date, animated: false)
        }
    }
    
    func checkForAndSaveChanges() {
        if let del = delegate {
            if let tView = tableView {
                let indexPathTemp = tView.indexPathForCell(self)
                if let indexPath = indexPathTemp {
                    if let date = picker.date.stringFromDate() {
                        del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: date)
                    }
                }
            }
        }
    }
}

public class CGSwitchTableViewCell: CGAttributedTableViewCell {
    
    var switchView: UIView!
    var noLabel: UILabel!
    var yesLabel: UILabel!
    var switchControl: UISwitch!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switchView = UIView()
        noLabel = UILabel()
        yesLabel = UILabel()
        switchControl = UISwitch()
        
        switchView.setTranslatesAutoresizingMaskIntoConstraints(false)
        noLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        yesLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        switchControl.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        noLabel.text = "No"
        yesLabel.text = "Yes"
        switchControl.addTarget(self, action: "switchToggled", forControlEvents: UIControlEvents.ValueChanged)
        
        switchView.hidden = true
        switchView.addSubview(noLabel)
        switchView.addSubview(yesLabel)
        switchView.addSubview(switchControl)
        self.addSubview(switchView)
        
        switchView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(20)-[noLabel(30)]-(8)-[switchControl(51)]-(8)-[yesLabel(30)]-(>=1)-|", options: NSLayoutFormatOptions(0), metrics: nil,
            views: [ "switchControl" : self.switchControl, "noLabel" : self.noLabel, "yesLabel" : self.yesLabel ]))
        switchView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(12)-[noLabel(21)]-(>=1)-|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "noLabel" : self.noLabel ]))
        switchView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(6)-[switchControl(31)]-(>=1)-|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "switchControl" : self.switchControl ]))
        switchView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(12)-[yesLabel(21)]-(>=1)-|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "yesLabel" : self.yesLabel ]))
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[switchView(44.0)]", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "switchView" : self.switchView ]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[switchView(165.0)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "switchView" : self.switchView ]))
        
        editProperties.append(switchView)
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.Switch.simpleDescription() }
    }
    
    override func descriptionTextSet() {
        if descriptionText == "Yes" {
            switchControl.on = true
        } else {
            switchControl.on = false
        }
    }
    
    func switchToggled() {
        if let del = delegate {
            if let tView = tableView {
                let indexPathTemp = tView.indexPathForCell(self)
                if let indexPath = indexPathTemp {
                    let positionString = switchControl.on ? "Yes" : "No"
                    del.attributedTableView(tView, updateDescriptionAtIndexPath: indexPath, withData: positionString)
                }
            }
        }
    }
}

public class CGButtonTableViewCell: CGAttributedTableViewCell {
    
    var button: UIButton!
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        propertyLabel.hidden = true
        
        self.removeConstraints(self.constraints())
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[superview]-(<=1)-[descriptionLabel]", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: [ "superview" : self, "descriptionLabel" : self.descriptionLabel ]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[superview]-(<=1)-[descriptionLabel(22.0)]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: [ "superview" : self, "descriptionLabel" : self.descriptionLabel ]))
    }
    
    override public var reuseIdentifier: String? {
        get { return CGAttributedTableViewCellType.Button.simpleDescription() }
    }
    
    override func descriptionTextSet() {
        descriptionLabel.textColor = descriptionLabel.tintColor
    }
    
    override func toggleEditingProperty() {
        if let del = delegate {
            if let tView = tableView {
                let indexPathTemp = tView.indexPathForCell(self)
                if let indexPath = indexPathTemp {
                    del.attributedTableView(tView, buttonPressedAtIndexPath: indexPath)
                }
            }
        }
    }
}
