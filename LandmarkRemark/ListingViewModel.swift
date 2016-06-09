//
//  LoginSignUpViewModel.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 8/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Foundation
import Parse


/// The protocol definiton for ListingViewModel delegate, implemented by the Listing table-view-controller
public protocol ListingViewModelDelegate: class {
    func logoutSuccess()
    func getAllLandmarkWithSuccess(count: Int)
    func landmarkUpdateWithSuccess(message: String)
    func landmarDeleteWithSuccess(message: String, swipeDeleteIndex: Int)
    func operationFailureWithErrorMessage(title: String, message: String)
    func reloadLandmarks()
}


/// The view-model for the Listing table table-view-controller
public class ListingViewModel  {
    
    // view-model private proerties
    
    // To represent the current logged-in user (Parse backend provided class and manged by Parse itself)
    private var user: PFUser? = nil
    
    // The delgate of the view-model to call back / pass back information to the view-controller
    public weak var delegate: ListingViewModelDelegate?
    
    // reference to the necessary services
    private let authenticationService: UserAuthenticationService
    private let landmarkRemarkService: LandmarkRemarkService
    
    
    // public properties accessed/altered by the view-controller to maintain the UI state
    
    // child view-models
    var landmarks: [AnnotationViewModel] = []
    var filteredLandmarks: [AnnotationViewModel] = []
    
    // view-controller will constantly update the location and update this
    var latestUpdatedLocation: CLLocation? = nil
    var currentUserName = ""
    
    
    // new initializer
    public init(delegate: ListingViewModelDelegate) {
        self.delegate = delegate
        authenticationService = UserAuthenticationService()
        landmarkRemarkService = LandmarkRemarkService()
        
        // if the user is logged-in, get a reference to the Parse managed user and extract the username in a property directly accessed by the view-controller
        if PFUser.currentUser() != nil {
            // should be always not nil at this point of time because user was already logged in
            user = PFUser.currentUser()
            currentUserName = (PFUser.currentUser()?.username)!
        }
    }
    
   
    
    //------------------------------------------------------------------------------------------------
    // MARK: - Core methods of the view-model, called by the view-controller based on the user actions
    //------------------------------------------------------------------------------------------------
    
    /**
     To retrieve te list of landmarks and pass back the results to the view-controller
     */
    public func getAllLandmarks() {

        // call the service layer
        // passing unowned self and weak delegate to break any possible retain cycle (for safety)
        // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html

        self.landmarkRemarkService.retrieveAllLandmarks(currentLocation: latestUpdatedLocation, withinDistance: nil) {
            [unowned self, weak delegate = self.delegate!]  (landmarks, error) in
            if error == nil {
                self.landmarks = []
                for landmark in landmarks {
                    // create a child annotation view-model from the data-model and pass back current username (necessary to color code the annotation)
                    let annotation = AnnotationViewModel(landmark: landmark, currentLogedInUsername: self.currentUserName)
                    self.landmarks.append(annotation)
                }
                delegate?.getAllLandmarkWithSuccess(landmarks.count)
            }
            else {
                delegate?.operationFailureWithErrorMessage("Error Occurred", message: (error?.localizedDescription)!)
            }
        }
    }
    
    
    /**
     To update a landmark, i.e. the remark/note by the user who create it it first
     
     - parameter landmarkId: The Id of the landmark
     - parameter newNote:    The new note content
     */
    public func updateRemarkForLandmark(landmarkId: String, newNote: String) {
        if user == nil { // this would never happen
            delegate?.operationFailureWithErrorMessage("Error", message: "Cannot update landmark because user login session has been expired or some unknown error occurred.")
        }
        else {
            // call the service layer
            // passing unowned self and weak delegate to break any possible retain cycle (for safety)
            self.landmarkRemarkService.updateLandmark(landmarkId, newNote: newNote, currentLocation: latestUpdatedLocation, completionHandler: {
                [unowned self, weak delegate = self.delegate!] (landmark, error) in
                
                if landmark != nil {
                    // after updting, create a new child view-model object and update the the array with the modified item
                    let updatedAnnotation = AnnotationViewModel(landmark: landmark!, currentLogedInUsername: self.currentUserName)
                    
                    var foundIndex = -1
                    for (index, item) in self.landmarks.enumerate() {
                        if item.landmarkId == landmarkId {
                            foundIndex = index
                            break
                        }
                    }
                    if foundIndex >= 0 {
                        self.landmarks.insert(updatedAnnotation, atIndex: foundIndex)
                        self.landmarks.removeAtIndex(foundIndex+1)
                    }
                    delegate?.landmarkUpdateWithSuccess("The landmark was updated with new remark.")
                }
                else {
                    var title = "Error Occurred"
                    var message = "Some unknown error occurred. Please try again."
                    
                    if error != nil {
                        if error?.code == 100 {
                            title = "No Internet Connection"
                            message = "Internet connection appears to be offine. Could not update the landmark."
                        }
                        else if error?.code == 503 {
                            title = "Faliure"
                            message = "Landmark info was not found on the server. So could not update."
                        }
                        else {
                            title = "Could not Save"
                            message = (error?.localizedDescription)!
                        }
                    }
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            })
        }
    }
    
    
    /**
     To delete a landmark by the owner/creator of the landmark
     
     - parameter landmarkId: The landmark id of teh landmark to be deleted by its ownner
     - parameter swipeDeleteIndex: To indicate this delete action was taken by left swipe geture on the table view, if so the row number is necessary to pass back to the view controller
     */
    public func deleteLandmark(landmarkId: String, swipeDeleteIndex: Int = -1) {
        if user == nil { // this would never happen
            delegate?.operationFailureWithErrorMessage("Error", message: "Cannot delete landmark because user login session has been expired or some unknown error occurred.")
        }
        else {
            self.landmarkRemarkService.deleteLandmark(landmarkId, completionHanlder: {
                [unowned self, weak delegate = self.delegate!] (success, error) in
                
                if success {
                    // after deleting, find the child view model and remove from aray so that UI can be updated
                    var foundIndex = -1
                    for (index, item) in self.landmarks.enumerate() {
                        if item.landmarkId == landmarkId {
                            foundIndex = index
                            break
                        }
                    }
                    if foundIndex >= 0 {
                        self.landmarks.removeAtIndex(foundIndex)
                    }
                    delegate?.landmarDeleteWithSuccess("The landark was deleted.", swipeDeleteIndex: swipeDeleteIndex)
                }
                else {
                    var title = "Error Occurred"
                    var message = "Some unknown error occurred. Please try again."
                    if error != nil {
                        if error?.code == 100 {
                            title = "No Internet Connection"
                            message = "Internet connection appears to be offine. Could not delete the landmark."
                        }
                        else if error?.code == 505 {
                            title = "Faliure"
                            message = "Landmark info was not found on the server. So could not delete."
                        }
                        else {
                            title = "Could not Delete"
                            message = (error?.localizedDescription)!
                        }
                    }
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            })
        }
    }
    
    
    /**
     To log out the user
     */
    public func logout() {
        authenticationService.logoutUser { [weak delegate = self.delegate!] (error) in
            // pass back either success or error info back to the view-controller via the delegate
            if error == nil {
                delegate?.logoutSuccess()
            }
            else {
                delegate?.operationFailureWithErrorMessage("Failure", message: (error?.localizedDescription)!)
            }
        }
    }
    
    
    /**
     To search landmarks view models mathching the text of the note text or the username, and also scope selected by teh user
     
     - parameter searchText: The search text enetered by the user on the UI (passed from view-controller)
     - parameter scope:      The scope (segmented control) selected on the UI (passed from view-controller)
     */
    public func filterContentForSearchTextAndScope(searchText: String, scope: String = "All") {
        
        let cleanSearchText = searchText.trim().condenseWhitespace().lowercaseString
        
        filteredLandmarks = landmarks.filter({ (annotation) -> Bool in
            
            if cleanSearchText != "" {
                
                // if scope is matched, search for text within username and note field
                let scopeMatch = (scope == "All") || (annotation.scope == scope)
                
                if scopeMatch {
                    
                    if ((annotation.title?.trim().condenseWhitespace().lowercaseString.containsString(cleanSearchText))!
                        || (annotation.subtitle?.trim().condenseWhitespace().lowercaseString.containsString(cleanSearchText))!) {
                        return true
                    }
                }
                return false
            }
            else {
                return (scope == "All") || (annotation.scope == scope)
            }
            
        })
        // pass back info to the view controller to refresh the UI
        delegate?.reloadLandmarks()
    }
    
    

}


