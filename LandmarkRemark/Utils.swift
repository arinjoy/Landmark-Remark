//
//  Utils.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit


/**
  An enum list for identifying various iOS devices with distinct screen sizes
 */
public enum DeviceType : Int {
    case iPhone4 = 0, iPhone5 = 1 , iPhone6 = 2, iPhone6Plus = 3, iPad = 4, iPadPro = 5
}


//---------------------------------
// MARK: - UIDevice Extension 
//---------------------------------

public extension UIDevice {
    
    /**
     To check whether the current device is an iPad
     */
    func isDeviceiPad() -> Bool {
        return UIDevice.current.model.range(of: "iPad") != nil
    }
    

    /**
     To get the type of the current device depending on its screen size proerties
     */
    func getDeviceType() -> DeviceType {
        
        let screenHeight = UIScreen.main.bounds.height
        
        if self.isDeviceiPad() == false {
            
            if screenHeight == 480 { // iPhone 4s
                return DeviceType.iPhone4
            } else if screenHeight == 568 { // iPhone 5
                return DeviceType.iPhone5
            } else if screenHeight == 667 { // iPhone 6
                return DeviceType.iPhone6
            } else if screenHeight == 768 { // iPhone 6 plus
                return DeviceType.iPhone6Plus
            } else { // if future bigger iPhone
                return DeviceType.iPhone6Plus
            }
        } else {
            if screenHeight == 1024 {
                return DeviceType.iPad
            } else if screenHeight == 1366 { // iPad Pro
                return DeviceType.iPadPro
            } else { //any future bigger iPad
                return DeviceType.iPadPro
            }
        }
    }
}

//-------------------------------
// MARK: - The String Exntension
//-------------------------------
extension String
{
    /**
     To trim while spaces from left and right of a string
     */
    func trim() -> String
    {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    /**
     To condense while spaces wihtin the string
     */
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: CharacterSet.whitespaces)
        let filtered = components.filter({!$0.isEmpty})
        return filtered.joined(separator: " ")
    }
    
}



//-------------------------------
// MARK: - The Utilty class
//-------------------------------

/**
 An utility class that is being used as a factory for genric utilities required throughout the project
 */
open class Utils {
    
    /**
     To execute a block of code within main thread after a specific delay in seconds
     
     - parameter delay:   delay amount in seconds
     - parameter closure: closure / block of coe to run after the delay
     */
    class func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    
    /**
     To generate a customized UIAlertController instance with custom fonts on title and message
     
     - parameter title:   The title that needs to be styled
     - parameter message: The message that needs to be styled
     
     - returns: The customised alert controller instance in default alert style
     */
    class func createCustomAlert(_ title: String, message: String) -> UIAlertController {
        
        let titleFont: UIFont = Font.avenir20D!
        let messageFont: UIFont =  Font.avenir16M!
        
        let attributedTitle = NSAttributedString(string: title, attributes: [NSFontAttributeName :  titleFont, NSForegroundColorAttributeName : UIColor.darkGray])
        let attributedMessage = NSAttributedString(string: message, attributes: [NSFontAttributeName : messageFont, NSForegroundColorAttributeName : UIColor.darkGray])
        
        let alert = UIAlertController(title: "", message: "",  preferredStyle: .alert)
        
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        return alert
    }
    
    
    /**
      To generate a customized UIAlertController instance with custom fonts on title and message
     
     - parameter title:   The title that needs to be styled
     - parameter message: The message that needs to be styled
     
     - returns: The customised alert controller instance in action sheet style
     */
    class func createCustomActionSheetAlert(_ title: String, message: String) -> UIAlertController {
        
        let titleFont: UIFont = Font.avenir20D!
        let messageFont: UIFont = Font.avenir16M!
        
        let attributedTitle = NSAttributedString(string: title, attributes: [NSFontAttributeName :  titleFont, NSForegroundColorAttributeName : UIColor.darkGray])
        let attributedMessage = NSAttributedString(string: message, attributes: [NSFontAttributeName : messageFont, NSForegroundColorAttributeName : UIColor.darkGray])
        
        let alert = UIAlertController(title: "", message: "",  preferredStyle: .actionSheet)
        
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        return alert
    }
    
    
    /**
     To determine the table cell heights depeding on the device screen size
     
     - returns: The calculated height
     */
    
    class func determineTableCellHeight() -> CGFloat {
        
        let screenHeight = UIScreen.main.bounds.height
        
        if UIDevice.current.isDeviceiPad()
        {
            return max(180, (screenHeight - 110) / 4)
        }
        else
        {
            return max(170, (screenHeight - 110) / 6)
        }
    }
    
}
