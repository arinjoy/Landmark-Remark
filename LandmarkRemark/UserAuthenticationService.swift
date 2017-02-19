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
    func signupUser(_ username: String, password: String, completionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        // create an isntance of a new PFUser
        let user = PFUser()
        user.username = username
        user.password = password
        
        // sign up using Parse SDK method
        user.signUpInBackground { (success: Bool, error: Error?) -> Void in
            completionHandler(success, error as NSError?)
        }
        
    }
    
    
    /**
     To login a user with Parse backend and to manage the session token within device by Parse itself
     
     - parameter username:          The username provided by user
     - parameter password:          The password provided ny user
     - parameter completionHandler: The completion block after asynchronous network call - to either return the user object or failure with reasons
     */
    func loginUser(username: String, password: String, completionHandler: @escaping (_ user: PFUser?, _ error: NSError?) -> Void) {
        
        // Login a user and try to retrieve the the user object from Parse if successful
        
        PFUser.logInWithUsername(inBackground: username, password: password) {
            (user: PFUser?, error: Error?) -> Void in
            
            completionHandler(user, error as NSError?)
        }
    }
    
    
    /**
     To log out the user and clear the session token from device
     
     - parameter completionHandler: The completion block after the asynchronous network call - to indicate success or failure with reasons
     */
    func logoutUser(_ completionHandler: @escaping (_ error: NSError?) -> Void) {
        
        // logout the current Parse user        
        PFUser.logOutInBackground { (error: Error?) -> Void  in
            completionHandler(error as NSError?)
        }
        
    }
    
}


