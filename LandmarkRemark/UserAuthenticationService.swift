//
//  UserAuthenticationService.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Parse


/// User authetication service to provide login, logout and signup features using the Parse backend
class UserAuthenticationService {
    
    /**
     To signup a user with Parse backend (simple signup without email verification)
     
     - parameter username:          The username chosen by the user
     - parameter password:          The password chosen by the user
     - parameter completionHandler: The completion block after asynchronous network call - to indicate success or failure with reasons
     */
    func signupUser(username: String, password: String, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        // create an isntance of a new PFUser
        let user = PFUser()
        user.username = username
        user.password = password
        
        // sign up using Parse SDK method
        user.signUpInBackgroundWithBlock { (success, error) -> Void in
            completionHandler(success: success, error: error)
        }
    }
    
    
    /**
     To login a user with Parse backend and to manage the session token within device by Parse itself
     
     - parameter username:          The username provided by user
     - parameter password:          The password provided ny user
     - parameter completionHandler: The completion block after asynchronous network call - to either return the user object or failure with reasons
     */
    func loginUser(username: String, password: String, completionHandler: (user: PFUser?, error: NSError?) -> Void) {
        
        // Login a user and try to retrieve the the user object from Parse if successful
        PFUser.logInWithUsernameInBackground(username, password: password,  block: { (user, error) -> Void in
            
            completionHandler(user: user, error: error)
        })
    }
    
    
    /**
     To log out the user and clear the session token from device
     
     - parameter completionHandler: The completion block after the asynchronous network call - to indicate success or failure with reasons
     */
    func logoutUser(completionHandler: (error: NSError?) -> Void) {
        
        // logout the current Parse user
        PFUser.logOutInBackgroundWithBlock { (error) in
            completionHandler(error: error)
        }
    }
    
}


