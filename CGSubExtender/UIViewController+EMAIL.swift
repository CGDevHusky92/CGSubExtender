//
//  UIViewController+EMAIL.swift
//  CGSubExtender
//
//  Created by Charles Gorectke on 12/17/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit
import MessageUI

// Error Codes
// -10 : The device can't send email
// -11 : User cancelled sending the email

extension UIViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    public func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        switch result.value {
        case MFMailComposeResultCancelled.value:
            let userInfo = [ NSLocalizedDescriptionKey : "Failed To Compose Email", NSLocalizedFailureReasonErrorKey : "The user cancelled the operation." ]
            let error = NSError(domain: "UIViewController+EMAIL", code: -11, userInfo: userInfo)
            self.viewControllerDidFailToComposeEmailWithError(error)
        case MFMailComposeResultSaved.value:
            break
        case MFMailComposeResultSent.value:
            self.viewControllerDidSendEmail()
            break
        case MFMailComposeResultFailed.value:
            self.viewControllerDidFailToSendEmailWithError(error)
        default:
            break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public func viewControllerComposeEmailWithSubject(subject: String, andMessage message: String, toRecipients recipients: [String], withAttachments attachments: [CGEmailAttachment]?) {
        // Ensure this device is able to send mail
        if MFMailComposeViewController.canSendMail() {
            // Set up mail controller
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                mailController.modalPresentationStyle = .FormSheet
            }
            
            // Attach files
            if let a = attachments {
                for item in a {
                    mailController.addAttachmentData(item.data, mimeType: item.mimeType, fileName: item.fileName)
                }
            }
            
            // Set email components
            mailController.setToRecipients(recipients)
            mailController.setSubject(subject)
            mailController.setMessageBody(message, isHTML: false)
            
            // Display email view
            self.presentViewController(mailController, animated: true, completion: nil)
        } else {
            let userInfo = [ NSLocalizedDescriptionKey : "Failed To Compose Email", NSLocalizedFailureReasonErrorKey : "The device is unable to send email." ]
            let error = NSError(domain: "UIViewController+EMAIL", code: -10, userInfo: userInfo)
            self.viewControllerDidFailToComposeEmailWithError(error)
        }
    }
    
    public func viewControllerDidFailToComposeEmailWithError(error: NSError!) { }
    
    public func viewControllerDidFailToSendEmailWithError(error: NSError!) { }
    
    public func viewControllerDidSendEmail() { }
}

public class CGEmailAttachment {
    var fileName: String
    var mimeType: String
    var data: NSData
    
    public init(_fileName: String, withMimeType _mimeType: String, andData _data: NSData) {
        fileName = _fileName
        mimeType = _mimeType
        data = _data
    }
}