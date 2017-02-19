//
//  ServiceHelper.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Parse


/// A helper class to convert a Parse objects into simpler dictionary structure
class ServiceHelper {
    
    /**
     Converts a Parse landmark object into data model object
     
     - parameter object: The Parse object
     
     - returns: The dictionary object
     */
    class func convertLandmarkObjectToDictionary(_ object: AnyObject) -> [String : AnyObject] {
        
        var landmark = [String: AnyObject]()
        
        let object = object as! PFObject
        
        // The object must have at least 4 keys
        // A safety check only in case a column is deleted from Parse by accident
        if object.allKeys.count >= 4 {
            
            landmark["landmarkId"] = object.objectId as AnyObject?
            landmark["note"] = object["note"] as? String as AnyObject?
            landmark["location"] = object["location"] as? PFGeoPoint
            landmark["savedByUserName"] = nil
            if let user = object["savedBy"] as? PFUser {
                 landmark["savedByUserName"] = user["username"] as? String as AnyObject?
            }
        }
        return landmark
    }
}
