//
//  LoginSignUpViewModel.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Parse

/// The protocol for LoginSignupViewModel delegate, implemented by the LoginSignup view-controller
public protocol LoginSignUpViewModelDelegate: class {
    func showInvalidUserName()
    func showInvalidPassword()
    func loginSuccessWithUser(user: PFUser)
    func signupSuccess()
    func operationFailureWithErrorMessage(title: String, message: String)
}


/// The view-model for the LoginSignup view-controller
public class LoginSignUpViewModel  {
    
    // public properties of the view-model exposed to its view-controller
    public var userName: String = ""
    public var  password: String = ""
    
    // The delgate of the view-model to call back / pass back information to the view-controller
    public weak var delegate: LoginSignUpViewModelDelegate?
    
    // reference to the Authentication service
    private let authenticationService: UserAuthenticationService
    
    // new initializer
    public init(delegate: LoginSignUpViewModelDelegate) {
        self.delegate = delegate
        authenticationService = UserAuthenticationService()
    }
    
    
    //------------------------------------------------------------------------------------------------
    // MARK: - Core methods of the view-model, called by the view-controller based on the user actions
    //------------------------------------------------------------------------------------------------
    
    /**
     The login mehtod
     */
    public func login() {
        
        // checking for valid username and password string, and inform the view-controller
        if !isValidUserName() {
            delegate?.showInvalidUserName()
        }
        else if !isValidPassword() {
            delegate?.showInvalidPassword()
        }
        else {
            // call to service layer
            // passing weak deleagte to break te retain cycle if any (for safety)
            // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html
            authenticationService.loginUser(userName, password: password, completionHandler: { [weak delegate = self.delegate!] (user, error) in
                
                if user != nil {
                    // communicate with the view-controller and send the new logged-in user object
                    delegate?.loginSuccessWithUser(user!)

                } else  {
                    // determine the error message and came from the backend side and send a user-friendly message back to the UI side
                    var title = "Error Occurred"
                    var message = "Some unknown error occurred. Please try again."

                    if error != nil {
                        if error?.code == 100 {
                            title = "No Internet Connection"
                            message = "Internet connection appears to be offine. Could not login."
                        }
                        if error?.code == 101 {
                            title = "Login Failed"
                            message = "You have entered invalid credentials. Please try again."
                        }
                        if error?.code == 401 {
                            title = "Login Failed"
                            message = "Could not succeed because access was denied."
                        }
                    }
                    // pass back the error information
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            })
        }
    }
    
    
    /**
     The signup method
     */
    public func signup() {
        
        // checking for valid username and password string, and inform the view-controller
        if !isValidUserName() {
            delegate?.showInvalidUserName()
        }
        else if !isValidPassword() {
            delegate?.showInvalidPassword()
        }
        else {
            // call the service layer
            authenticationService.signupUser(userName, password: password, completionHandler: { [weak delegate = self.delegate!] (success, error) in
           
            if error == nil {
                delegate?.signupSuccess()

            } else {
                // determine the error message and came from the backend side and send a user-friendly message back to the UI side
                var title = "Error Occurred"
                var message = "Some unknown error occurred. Please try again."

                if error?.code == 100 {
                    title = "No Internet Connection"
                    message = "Internet connection appears to be offine. Could not signup."
                }
                if error?.code == 202 || error?.code == 203 {
                    title = "Signup Failed"
                    message = "The username you have chosen has already been taken up by another user. Please choose a different one. "
                    
                }
                // pass back the error information
                delegate?.operationFailureWithErrorMessage(title, message: message)
            }
        })
     }
  }
    
    
    
    //------------------------------------------------------------------------------------------------
    // MARK: - private helper methods
    //------------------------------------------------------------------------------------------------
    
    /**
     To check for an acceptable username
     */
    private func isValidUserName() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[A-Za-z]+([A-Za-z0-9-_.]){2,15}$", options: .CaseInsensitive)
            return regex.firstMatchInString(userName, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, userName.characters.count)) != nil
        } catch {
            return false
        }
    }
    
    /**
     To check for an acceptable password
     */
    private func isValidPassword() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[A-Za-z0-9.!#$%&'*+/=?^_~-]{3,25}$", options: .CaseInsensitive)
            return regex.firstMatchInString(password, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, password.characters.count)) != nil
        } catch {
            return false
        }
    }


}


