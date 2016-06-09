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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // customizing UI elements appreance globally
        self.customizeAppAppearance()

        
        // setting up the configuration for Parse backend NodeJS Server on Heroku
        let configuration = ParseClientConfiguration {
            $0.applicationId =  "LANDMARK_REMARK_PARSE_SERVER"
            $0.clientKey = "abcd1234"
            $0.server = "https://landmark-remark-parse-server.herokuapp.com/parse"
        }
        
        // initialize the Parse configuration
        Parse.initializeWithConfiguration(configuration)
        
        let defaultACL = PFACL();
        defaultACL.publicReadAccess = true
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser:true)
        
        return true
    }

    


    // MARK: - Private Helpers
    
    private func customizeAppAppearance() {
        
        window?.tintColor =  Color.darkGreenColor
        
        // apply style on navigation bar
        UINavigationBar.appearance().barTintColor =  Color.darkGreenColor
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().tintAdjustmentMode = .Normal
        UINavigationBar.appearance().translucent = false
        
        // apply style on title and bar buttons
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: Font.avenir18M!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Font.avenir16M!], forState: .Normal)
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UINavigationBar.self]).tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barStyle = UIBarStyle.Black
        
        // apply color on the text fields
        UITextField.appearance().textColor = UIColor.darkGrayColor()
        UIButton.appearance().tintColor =  UIColor.whiteColor() 
        UIButton.appearance().tintAdjustmentMode = .Normal
        
        UITabBar.appearance().backgroundColor = UIColor.whiteColor()
        UITabBar.appearance().tintColor = Color.darkGreenColor
        UITabBar.appearance().translucent = true
        
    }

}

