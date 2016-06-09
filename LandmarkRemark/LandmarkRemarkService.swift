//
//  LandmarkRemarkService.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Parse

/// The service to apply CRUD (Create/Read/Update/Delete) operations on landmark objects saved on Parse backend
class LandmarkRemarkService {
    
    /**
     To retrieve all the landmarks object saved by different users, loading from the Parse backend
     
     - parameter currentLocation:   The current geo-location of the device to calculate the distance information
     - parameter withinDistance:    The distance in kilometres to sarch for other landmarks from the current device location
     - parameter completionHandler: The completion block after asynchronous network call - to return the list of landmarks
     */
    func retrieveAllLandmarks(currentLocation currentLocation: CLLocation? = nil, withinDistance: Double? = nil, completionHandler: (landmarks: [Landmark], error: NSError?) -> Void) {
        
        var landmarkResults:[Landmark] = [Landmark]()
        
        let query = PFQuery(className: "Landmark")
        
        // Parse limit is 1000, so reduce the limit to 900
        query.limit = 900
        
        // Always try to load from network first and if not connected then from device cache
        query.cachePolicy = .NetworkElseCache
        
        // Inlcude the user objects who saved the landmark
        query.includeKey("savedBy")
        
        if currentLocation != nil {
            
            let currentPoint = PFGeoPoint(location: currentLocation)
            
            // If the current device location is specified, then check whther distance radius is also specified
            // Apply geo-spatial query supported by Parse
            if withinDistance != nil {
                query.whereKey("location", nearGeoPoint: currentPoint, withinKilometers: withinDistance!)
                
            } else {
                // search the entire planet with 360 degree in radian
                query.whereKey("location", nearGeoPoint: currentPoint, withinRadians: 6.28318)
            }
        }
        else {
            // by default order using the note text content, if no geo-spatial query is applied
            query.orderByAscending("note")
        }
        
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            if error == nil {
                if let landmarks = objects {
                    for landmark in landmarks {
                        var distanceText: String? = nil
                        let geoPoint = landmark["location"] as! PFGeoPoint
                        // if current location is known, calculate the distance info to display as a hint
                        if currentLocation != nil {
                            let distance = PFGeoPoint(location: currentLocation).distanceInKilometersTo(geoPoint)
                            distanceText = self.generateDistanceHint(distance)
                        }
                        // convert the Parse landmark object to the data model and then append that into the list
                        landmarkResults.append(Landmark(dict: ServiceHelper.convertLandmarkObjectToDictionary(landmark), distance: distanceText))
                    }
                }
                completionHandler(landmarks: landmarkResults, error: nil)
            }
            else {
                completionHandler(landmarks: landmarkResults, error: error)
            }
        }
    }
    
    
    /**
     To create a landmark object on the Parse backend
     
     - parameter user:              The user who is saving this landmark
     - parameter note:              The remark/note for the landmark
     - parameter location:          The geo-location whther landmark is being added by the user
     - parameter completionHandler: The completion block after asynchronous network call - to return the created landmark instance or failure with reasons
     */
    func createLandmark(user: PFUser, note: String, location: CLLocationCoordinate2D, completionHandler: (landmark: Landmark?, error: NSError?) -> Void) {
        
        let newlandmark = PFObject(className:"Landmark")
        newlandmark["savedBy"] = user
        newlandmark["note"] = note
        newlandmark["location"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
        
        newlandmark.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if success {
                // convert the Parse landmark object to data model
                let resultLandmark = Landmark(dict: ServiceHelper.convertLandmarkObjectToDictionary(newlandmark), distance: "0 m away")
                completionHandler(landmark: resultLandmark, error: nil)
            }
            else {
                completionHandler(landmark: nil, error: error)
            }
        }
    }
    
    
    /**
     To update a landmark object, i.e. to change the note text. Only the owner (who save it) can edit the note
     
     - parameter landmarkId:        <#landmarkId description#>
     - parameter newNote:           <#newNote description#>
     - parameter currentLocation:   <#currentLocation description#>
     - parameter completionHandler: <#completionHandler description#>
     */
    func updateLandmark(landmarkId: String, newNote: String, currentLocation: CLLocation?, completionHandler: (landmark: Landmark?, error: NSError?) -> Void) {
        
        let query = PFQuery(className: "Landmark")
        query.limit = 1
        query.cachePolicy = .NetworkElseCache
        // match the landmark object Id
        query.whereKey("objectId", equalTo: landmarkId)
        query.includeKey("savedBy")
        
        // find the object first
        query.findObjectsInBackgroundWithBlock { (objects, loadError) in
            if loadError == nil {
                if let objects = objects {
                    // must return a single object
                    if objects.count == 1 {
                        let targetLandmark = objects[0]
                        targetLandmark["note"] = newNote
                        
                        // saving back the new value
                        targetLandmark.saveInBackgroundWithBlock({ (success, error) in
                            if success {
                                var distanceText: String? = nil
                                // calculate the distance info
                                if currentLocation != nil {
                                    let geoPoint = targetLandmark["location"] as! PFGeoPoint
                                    let distance = PFGeoPoint(location: currentLocation).distanceInKilometersTo(geoPoint)
                                    distanceText = self.generateDistanceHint(distance)
                                }
                                let resultLandmark = Landmark(dict: ServiceHelper.convertLandmarkObjectToDictionary(targetLandmark), distance: distanceText)
                                completionHandler(landmark: resultLandmark, error: nil)
                            }
                            else {
                                 completionHandler(landmark: nil, error: error)
                            }
                        })
                    }
                    else {
                        // if no object was found and error is not nil either - this would never happen unless Parse gives incorrect structure
                        completionHandler(landmark: nil, error: NSError(domain: "Landmark.domain", code: 503, userInfo: nil))
                    }
                }
                else {
                    // if no object was found and error is not nil either - this would never happen unless Parse gives incorrect structure
                    completionHandler(landmark: nil, error: NSError(domain: "Landmark.domain", code: 503, userInfo: nil))
                }
            }
            else {
                completionHandler(landmark: nil, error: loadError)
            }
        }
    }
    
    
    /**
     To delete a lanmark object by its owner only
     
     - parameter landmarkId:        The object id of the landmark
     - parameter completionHanlder: The completion block after asynchronous network call - to indicate success or failure
     */
    func deleteLandmark(landmarkId: String, completionHanlder: (success: Bool, error: NSError?) -> Void) {
        
        let query = PFQuery(className: "Landmark")
        query.limit = 1
        query.cachePolicy = .NetworkElseCache
        
        // match the object using the object Id
        query.whereKey("objectId", equalTo: landmarkId)
        
        query.findObjectsInBackgroundWithBlock { (objects, loadError) in
            if loadError == nil {
                if let objects = objects {
                    if objects.count == 1 {
                        let targetLandmark = objects[0]
                        targetLandmark.deleteInBackgroundWithBlock({ (success, deleteError) in
                            completionHanlder(success: success, error: deleteError)
                        })
                    }
                    else {
                        // if no object was found and error is not nil either - this would never happen unless Parse gives incorrect structure
                        completionHanlder(success: false, error: NSError(domain: "Landmark.domain", code: 505, userInfo: nil))
                    }
                }
                else {
                    // if no object was found and error is not nil either - this would never happen unless Parse gives incorrect structure
                    completionHanlder(success: false, error: NSError(domain: "Landmark.domain", code: 505, userInfo: nil))
                }
            }
            else {
                completionHanlder(success: false, error: loadError)
            }
        }
    }
    
    
    
    
    //----------------------------
    // MARK: - Private Helpers
    //----------------------------
    /**
     A helper method to calcuate the ditance hint
     
     - parameter distance: The distance in kilometres
     
     - returns: The textual information to display in the UI
     */
    func generateDistanceHint(distance: Double) -> String {
    
        // if withing one km, check for less than 5m, 20m or 50m
        if distance < 1.0 {
            if distance * 1000 <= 5.0 {
                return "just here"
            }
            else if distance * 1000 <= 20.0 {
                return "less than 20 m away"
            }
            else if distance * 1000 <= 50.0 {
                return "less than 50 m away"
            }
            else {
                // if more than 50m, show the real distance
                return "\(Double(round(10 * distance * 1000) / 10)) m away"
            }
        }
        else {
            // show the km after rounding 2 deciamal points
            return "\(Double(round(100 * distance) / 100)) km away"
        }
    
    }

}
