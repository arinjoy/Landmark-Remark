//
//  LoginSignupViewController.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit
import Parse


/// The view controller for login and signup process
class LoginSignupViewController: UIViewController, UITextFieldDelegate, LoginSignUpViewModelDelegate {

    // outlet connections from storyboard
    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    
    @IBOutlet weak var loginOrSignupButton: UIButton!
    
    @IBOutlet weak var logoTopContraint: NSLayoutConstraint!
    
    @IBOutlet weak var loginAreaTopConstraint: NSLayoutConstraint!
    
    // to toggle teh screen to act either as login or signup screen based on the user need
    var signupModeActivated: Bool = false
    
    // activity spinner
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    var viewsToAnimate: [UIView!]!
    var hideOffset: CGFloat = -220.0
    
    // the view-model
    var viewModel: LoginSignUpViewModel!
    
    
    //------------------------------------------------------------------------------------------------
    // MARK: - View controller life cycle methods
    //------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check for device type and adjust the UI to make it adaptive for all iOS devices (iPhone /iPad)
        if UIDevice.currentDevice().getDeviceType() == .iPhone4  {
            loginAreaTopConstraint.constant = 50.0
            hideOffset = -160.0
        }
        else if  UIDevice.currentDevice().getDeviceType() == .iPhone5 {
            loginAreaTopConstraint.constant = 70.0
            hideOffset = -180.0
        }
        else if UIDevice.currentDevice().getDeviceType() == .iPhone6 {
            hideOffset = -200.0
            loginAreaTopConstraint.constant = 110.0
        }
        else {  // for 6Plus or bigger phone
            hideOffset = -220.0
            loginAreaTopConstraint.constant = 110.0
        }
        
        if UIDevice.currentDevice().isDeviceiPad() {
            hideOffset = -320.0
            logoTopContraint.constant = 100.0
            loginAreaTopConstraint.constant = 160.0
            if UIDevice.currentDevice().getDeviceType() == .iPadPro {
                hideOffset = -420.0
            }
        }
        
        // create an array of all the views to animate
        viewsToAnimate = [self.logoImageView, self.usernameTextField, self.passwordTextField, self.dontHaveAccountButton, self.loginOrSignupButton]
        
        setAlphaForViews(0.0)

        // setting the delegate on the text field inputs
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // intialize the view-model
        viewModel = LoginSignUpViewModel(delegate: self)
        
        // add listeners on the inout text to listen for editing chnage event
        usernameTextField.addTarget(self, action: #selector(LoginSignupViewController.userNameChanged), forControlEvents: UIControlEvents.EditingChanged)
        passwordTextField.addTarget(self, action: #selector(LoginSignupViewController.passwordChanged), forControlEvents: UIControlEvents.EditingChanged)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // if a current logged in user exists on the disk, the user is already logged in
        if PFUser.currentUser() != nil {
            self.performSegueWithIdentifier("loadMapPageSegue", sender: nil)
        }
        
        // animate te views to set their alpha to 1.0
        UIView.animateWithDuration(0.5, delay: 0.3, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.setAlphaForViews(1.0)
        }, completion: nil)
        
    }
    
    // --------------------------------------------
    // MARK :- Misclaneous view controller methods
    // --------------------------------------------
    
    // status bar preference
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    
    
    // -------------------------------
    // MARK :- user Actions on the UI
    // -------------------------------
    
    @IBAction func noAccountClickedAction(sender: AnyObject) {
        
        if signupModeActivated == false {
            let alert = Utils.createCustomAlert("Not Signed up yet?", message: "It's very simple. Just choose a simple username and a password and then Signup.")
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        toggleSignUpMode()
    }
    
    @IBAction func loginOrSignupAction(sender: AnyObject) {
        performLoginOrSignupAction()
    }
    
    
    
    // ------------------------------------
    // MARK :- Helper methods
    // ------------------------------------
    
    // selector methods to bind the view model property with user input
    func userNameChanged() {
        viewModel.userName = usernameTextField.text!
    }
    func passwordChanged() {
        viewModel.password = passwordTextField.text!
    }
    
    private func performLoginOrSignupAction() {
        dissmissAnyKeyboard()
        showActivityLoader()
        if signupModeActivated {
            viewModel.signup()
        }
        else {
            viewModel.login()
        }
    }
    
    // to show an alert pop-up
    private func displayAlert(title:String, message:String) {
        let alert = Utils.createCustomAlert(title, message: message)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func showActivityLoader() {
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame);
        activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func stopActivityLoader() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    
    func setAlphaForViews(value: CGFloat) {
        dispatch_async(dispatch_get_main_queue(), {
            for view in self.viewsToAnimate {
                view.alpha = value
            }
        })
    }
    
    // to dissmss any keyboard
    func dissmissAnyKeyboard() {
        if usernameTextField.isFirstResponder() {
            usernameTextField.resignFirstResponder()
        }
        if passwordTextField.isFirstResponder() {
            passwordTextField.resignFirstResponder()
        }
    }
    
    // to toggle the login/signup mode and change the UI
    func toggleSignUpMode(){
        if signupModeActivated {
            signupModeActivated = false
            dispatch_async(dispatch_get_main_queue(), {
                self.dontHaveAccountButton.setImage(UIImage(named: "Dont have account"), forState: UIControlState.Normal)
                self.loginOrSignupButton.setImage(UIImage(named: "Login"), forState: UIControlState.Normal)
            })
        }
        else {
            signupModeActivated = true
            dispatch_async(dispatch_get_main_queue(), {
                self.dontHaveAccountButton.setImage(UIImage(named: "Already have account"), forState: UIControlState.Normal)
                self.loginOrSignupButton.setImage(UIImage(named: "Signup"), forState: UIControlState.Normal)
            })
        }
    }
    
    
    // ------------------------------------
    // MARK :- UITextFieldDelegate methods
    // ------------------------------------
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        // as soon as an user iuput is selected, jump up the user input area to avoid being hidden under keyboard
        dispatch_async(dispatch_get_main_queue(), {
            if textField == self.usernameTextField ||  textField == self.passwordTextField {
                self.setAlphaForViews(0.0)
                self.logoTopContraint.constant = self.hideOffset
                self.logoImageView.setNeedsUpdateConstraints()
                self.view!.setNeedsUpdateConstraints()
                
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    for view in self.viewsToAnimate {
                        view.layoutIfNeeded()
                    }
                    self.setAlphaForViews(1.0)
                    }, completion: { done in
                })
            }
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // beahviour of the return key button
        if textField == usernameTextField {
            textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
        }
        if textField == passwordTextField {
            textField.resignFirstResponder()
            if usernameTextField.text?.trim().characters.count >= 3 && passwordTextField.text?.trim().characters.count >= 3 {
                performLoginOrSignupAction()
                return true
            }
        }
        return false
    }
    
    
    
    // -------------------------------------------------------------------------------------------------------
    // MARK :- LoginSignUpViewModelDelegate method implementation, called by the view-model to notify anything
    // -------------------------------------------------------------------------------------------------------
    
    func showInvalidUserName() {
        stopActivityLoader()
        displayAlert("Invalid Username", message: "A username must be 3 or more characters in length. It should start with an alphabet and it can only have alphanumeric characters, hiphen, underscore or dot.")
        usernameTextField.becomeFirstResponder()
    }
    
    func showInvalidPassword() {
        stopActivityLoader()
        displayAlert("Invalid Password", message: "A password must be 3 or more characters in length.")
        passwordTextField.becomeFirstResponder()

    }
    
    func loginSuccessWithUser(user: PFUser) {
        stopActivityLoader()
        self.performSegueWithIdentifier("loadMapPageSegue", sender: nil)
    }
    
    func signupSuccess() {
        stopActivityLoader()
        displayAlert("Signup Successful", message: "You have been signed up. Please login now.")
        toggleSignUpMode()
        usernameTextField.becomeFirstResponder()
    }
    
    func operationFailureWithErrorMessage(title: String, message: String) {
        stopActivityLoader()
        displayAlert(title, message: message)
    }

}


