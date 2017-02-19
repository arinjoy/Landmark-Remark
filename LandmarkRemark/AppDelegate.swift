//
//  AppDelegate.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    // Mark: - UiApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // customizing UI elements appreance globally
        self.customizeAppAppearance()

        
        // setting up the configuration for Parse backend NodeJS Server on Heroku
        let configuration = ParseClientConfiguration {
            $0.applicationId =  "LANDMARK_REMARK_PARSE_SERVER"
            $0.clientKey = "abcd1234"
            $0.server = "https://landmark-remark-parse-server.herokuapp.com/parse"
        }
        
        // initialize the Parse configuration
        Parse.initialize(with: configuration)
        
        let defaultACL = PFACL();
        defaultACL.getPublicReadAccess = true
        PFACL.setDefault(defaultACL, withAccessForCurrentUser:true)
        
        return true
    }

    


    // MARK: - Private Helpers
    
    fileprivate func customizeAppAppearance() {
        
        window?.tintColor =  Color.darkGreenColor
        
        // apply style on navigation bar
        UINavigationBar.appearance().barTintColor =  Color.darkGreenColor
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().tintAdjustmentMode = .normal
        UINavigationBar.appearance().isTranslucent = false
        
        // apply style on title and bar buttons
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: Font.avenir18M!, NSForegroundColorAttributeName: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Font.avenir16M!], for: UIControlState())
        UIBarButtonItem.appearance().tintColor = UIColor.white
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.white
        UINavigationBar.appearance().barStyle = UIBarStyle.black
        
        // apply color on the text fields
        UITextField.appearance().textColor = UIColor.darkGray
        UIButton.appearance().tintColor =  UIColor.white 
        UIButton.appearance().tintAdjustmentMode = .normal
        
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().tintColor = Color.darkGreenColor
        UITabBar.appearance().isTranslucent = true
        
    }

}

