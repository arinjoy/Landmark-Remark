//
//  LandmarksViewModel.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Parse

/// The protocol definiton for LandmarkViewModel delegate, implemented by the Landmarks view-controller
public protocol LandmarksViewModelDelegate: class {
    func logoutSuccess()
    func landmarkSaveOrDeleteWithSuccess(_ message: String)
    func getAllLandmarkWithSuccess(_ count: Int)
    func operationFailureWithErrorMessage(_ title: String, message: String)
    func reloadAnnotations()
}

/**
 Utility enum-structure to represent the radius selection boundary by the user
 */
enum BoundaryRange: Double {
    
    case one_KM = 1.0, ten_KM = 10.0, hundred_KM = 100.0, entire_PLANET = 9999.00
}


/// The view-model for the Landmarks view-controller
open class LandmarksViewModel: NSObject {
    
    // view-model private proerties
    
    // To represent the current logged-in user (Parse backend provided class and manged by Parse itself)
    fileprivate var user: PFUser? = nil

    // The delgate of the view-model to call back / pass back information to the view-controller
    open weak var delegate: LandmarksViewModelDelegate?
    
    // reference to the necessary services
    fileprivate let authenticationService: UserAuthenticationService
    fileprivate let landmarkRemarkService: LandmarkRemarkService
    
    // public properties accessed/altered by the view-controller to maintain the UI state
    
    // child view-models
    var landmarkAnnotations: [AnnotationViewModel] = []
    var filteredLandmarkAnnotations: [AnnotationViewModel] = []

    // view-controller will constantly update the location and update this
    var latestUpdatedLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var currentUserName = ""
    
    // default selection boundary is the entire planet
    var selectedBoundary: BoundaryRange = BoundaryRange.entire_PLANET
    
    // new initializer
    public init(delegate: LandmarksViewModelDelegate) {
        self.delegate = delegate
        authenticationService = UserAuthenticationService()
        landmarkRemarkService = LandmarkRemarkService()
        
        // if the user is logged-in, get a reference to the Parse managed user and extract the username in a property directly accessed by the view-controller
        if PFUser.current() != nil {
            // should be always not nil at this point of time because user was already logged in
            user = PFUser.current()
            currentUserName = (PFUser.current()?.username)!
        }
    }
    
    
    
    //------------------------------------------------------------------------------------------------
    // MARK: - Core methods of the view-model, called by the view-controller based on the user actions
    //------------------------------------------------------------------------------------------------

    /**
     To retrieve te list of landmarks and pass back the results to the view-controller
     */
    open func getAllLandmarks() {
        
        // determine the type geo-spatial query necessary by the service layer depending on the user preference
        // by default the entire planet is searched, until the user changes the preference
        let targetDistance: Double? = (selectedBoundary == .entire_PLANET) ? nil : selectedBoundary.rawValue
        
        // call the service layer
        // passing unowned self and weak delegate to break the retain cycle if any (for safety)
        // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html
        
        self.landmarkRemarkService.retrieveAllLandmarks(currentLocation: latestUpdatedLocation, withinDistance: targetDistance) {
            [unowned self, weak delegate = self.delegate!] (landmarks, error) in
            
            if error == nil {
                self.landmarkAnnotations = []
                for landmark in landmarks {
                    // create a child annotation view-model from the data-model and pass back current username (necessary to color code the annotation)
                    let annotation = AnnotationViewModel(landmark: landmark, currentLogedInUsername: self.currentUserName)
                    self.landmarkAnnotations.append(annotation)
                }
                delegate?.getAllLandmarkWithSuccess(landmarks.count)
            }
            else {
                delegate?.operationFailureWithErrorMessage("Error Occurred", message: (error?.localizedDescription)!)
            }
        }
    }
    
    
    /**
     To create and save a landmark object
     
     - parameter note: The remark/note enetered by the user
     */
    open func saveLandmarkWithRemark(_ note: String) {
        
        if user == nil { // this would never happen
            delegate?.operationFailureWithErrorMessage("Error", message: "Cannot save landmark because user login session has been expired or some unknown error occurred.")
        }
        else {
            // call the service layer
            // passing unowned self and weak delegate to break the retain cycle if any (for safety)
            self.landmarkRemarkService.createLandmark(user!, note: note, location: latestUpdatedLocation.coordinate) {
                [unowned self, weak delegate = self.delegate!] (landmark, error) in
                
                if landmark != nil {
                    let annotation = AnnotationViewModel(landmark: landmark!, currentLogedInUsername: self.currentUserName)
                    // add the new annotation for this landmark
                    self.landmarkAnnotations.append(annotation)
                    
                    // tell the view controller to refresh the UI
                    delegate?.reloadAnnotations()
                    delegate?.landmarkSaveOrDeleteWithSuccess("You have just added a landmark.")
                }
                else {
                    var title = "Error Occurred"
                    var message = "Some unknown error occurred. Please try again."
                    
                    if error != nil {
                        if error?.code == 100 {
                            title = "No Internet Connection"
                            message = "Internet connection appears to be offine. Could not save the landmark."
                        }
                        else {
                            title = "Could not Save"
                            message = (error?.localizedDescription)!
                        }
                    }
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            }
        }
    }
    
    
    /**
     To update a landmark, i.e. the remark/note by the user who create it it first
     
     - parameter landmarkId: The Id of the landmark
     - parameter newNote:    The new note content
     */
    open func updateRemarkForLandmark(_ landmarkId: String, newNote: String) {
        
        if user == nil { // this would never happen
            delegate?.operationFailureWithErrorMessage("Error", message: "Cannot update landmark because user login session has been expired or some unknown error occurred.")
        }
        else {
            // call the service layer
            // passing unowned self and weak delegate to break the retain cycle if any (for safety)
            landmarkRemarkService.updateLandmark(landmarkId, newNote: newNote, currentLocation: latestUpdatedLocation ,completionHandler: {
                [unowned self, weak delegate = self.delegate!] (landmark, error) in
                
                if landmark != nil {
                    let updatedAnnotation = AnnotationViewModel(landmark: landmark!, currentLogedInUsername: self.currentUserName)
                    
                    // after updting, create a new child view-model object and update the the array with the modified item
                    var foundIndex = -1
                    for (index, item) in self.landmarkAnnotations.enumerated() {
                        if item.landmarkId == landmarkId {
                            foundIndex = index
                            break
                        }
                    }
                    if foundIndex >= 0 {
                        self.landmarkAnnotations.insert(updatedAnnotation, at: foundIndex)
                        self.landmarkAnnotations.remove(at: foundIndex+1)
                        delegate?.reloadAnnotations()
                    }
                    // pass back message to the view-controller
                    delegate?.landmarkSaveOrDeleteWithSuccess("The landmark was updated with new remark.")
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
                            message = "Landmark information was not found on the server. So could not update."
                        }
                        else {
                            title = "Could not Save"
                            message = (error?.localizedDescription)!
                        }
                    }
                    // pass back message to the view-controller
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            })
        }
    }
    
    
    /**
     To delete a landmark by the owner/creator of the landmark
     
     - parameter landmarkId: The landmark id of teh landmark to be deleted by its ownner
     */
    open func deleteLandmark(_ landmarkId: String) {
        if user == nil { // this would never happen
            delegate?.operationFailureWithErrorMessage("Error", message: "Cannot delete landmark because user login session has been expired or some unknown error occurred.")
        }
        else {
            // call the service layer
            // passing unowned self and weak delegate to break the retain cycle if any (for safety)
            landmarkRemarkService.deleteLandmark(landmarkId, completionHanlder: {
                [unowned self, weak delegate = self.delegate!] (success, error) in
                
                if success {
                    // after deleting, find the child view model and remove from aray so that UI can be updated
                    var foundIndex = -1
                    for (index, item) in self.landmarkAnnotations.enumerated() {
                        if item.landmarkId == landmarkId {
                            foundIndex = index
                            break
                        }
                    }
                    if foundIndex >= 0 {
                        self.landmarkAnnotations.remove(at: foundIndex)
                        delegate?.reloadAnnotations()
                    }
                    // pass back message to the view-controller
                    delegate?.landmarkSaveOrDeleteWithSuccess("The landark was deleted.")
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
                            message = "Landmark information was not found on the server. So could not delete."
                        }
                        else {
                            title = "Could not Delete"
                            message = (error?.localizedDescription)!
                        }
                    }
                    // pass back message to the view-controller
                    delegate?.operationFailureWithErrorMessage(title, message: message)
                }
            })
        }
    }
    
    
    /**
     To log out the user
     */
    open func logout() {
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
    open func filterContentForSearchTextAndScope(_ searchText: String, scope: String = "All") {
        
        // clean up the search text and make it lowercase to perform case insensitive search
        let cleanSearchText = searchText.trim().condenseWhitespace().lowercased()
        
        // save the seach result in a filtered array which is accessed by the view-controller
        filteredLandmarkAnnotations = landmarkAnnotations.filter({ (annotation) -> Bool in
            
            if cleanSearchText != "" {
                
                // default scope is "All", otherwise look for user selected scope
                let scopeMatch = (scope == "All") || (annotation.scope == scope)
                
                if scopeMatch {
                    // if scope is matched, search for text within username and note field
                    if ((annotation.title?.trim().condenseWhitespace().lowercased().contains(cleanSearchText))!
                        || (annotation.subtitle?.trim().condenseWhitespace().lowercased().contains(cleanSearchText))!) {
                        return true
                    }
                }
                return false
                
            } else {
                // if empty text on the search field, still look for scope selection by the user
                return (scope == "All") || (annotation.scope == scope)
            }
            
        })
        // pass back info to the view controller to refresh the UI
        delegate?.reloadAnnotations()
    }
}
