//
//  CGLoginViewController.swift
//  REPO
//
//  Created by Chase Gorectke on 12/11/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit

public let kLoginUserAuthenticated = "kLoginUserAuthenticated"

public class CGLoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet public var usernameField: UITextField!
    @IBOutlet public var passwordField: UITextField!
    @IBOutlet public var loginButton: UIButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loginButton.addTarget(self, action: "loginButtonPressed:", forControlEvents: .TouchUpInside)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func loginButtonPressed(sender: AnyObject!) {
        let alert = UIAlertController(title: "Warning!", message: "A Warning", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        
        if usernameField.text == "" && passwordField.text == "" {
            alert.message = "Username and Password Required!"
            usernameField.becomeFirstResponder()
            self.presentViewController(alert, animated: true, completion: nil)
            self.loginFailed()
        } else if usernameField.text == "" {
            alert.message = "Username Required!"
            usernameField.becomeFirstResponder()
            self.presentViewController(alert, animated: true, completion: nil)
            self.loginFailed()
        } else if passwordField.text == "" {
            alert.message = "Password Required!"
            passwordField.becomeFirstResponder()
            self.presentViewController(alert, animated: true, completion: nil)
            self.loginFailed()
        } else {
            self.loginSuccessful()
        }
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
            return false
        } else if textField == passwordField {
            self.view.endEditing(true)
            self.loginButtonPressed(self)
        }
        return true
    }
    
    public func loginSuccessful() { }
    
    public func loginFailed() { }
}
