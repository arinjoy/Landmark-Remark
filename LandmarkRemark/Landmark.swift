//
//  Landmark.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//


import CoreLocation
import Parse

/**
 *  Data model structure to represent a Landmark object
 */
public struct Landmark {
    
    // the properties to represent a lanmark
    let landmarkId: String
    let location: CLLocationCoordinate2D
    let note: String
    let savedByUserName: String
    
    // optional distance info text required to display on some part of the UI
    let distanceInfo: String?
    
    // intializer that accepts a dictionary object and an optional distance info if necessary
    init(dict: Dictionary<String, AnyObject>, distance: String? = nil) {
        landmarkId = dict["landmarkId"] as! String
        note = dict["note"] as! String
        location = CLLocationCoordinate2D(latitude: dict["location"]!.latitude, longitude: dict["location"]!.longitude)
        savedByUserName = dict["savedByUserName"] as! String
        distanceInfo = distance
    }
}