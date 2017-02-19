//
//  AnnotationViewModel.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import Foundation
import MapKit
import Contacts


/// A view-model/custom view object combined into one class to represent an annotation on map
// This is basically a subclass of MKAnnotation to customise the annotation properties, but also treated as a child view-model to be bused y its parent parent view-model
// Note: This a deviation from pure MVVM pattern where view and view-model are combined in one place to keep it simple and convenient

class AnnotationViewModel: NSObject, MKAnnotation {
    
    // By default MKAnnotation provides title and subtitle proerties to display on the annotation call-out
    // But some addtional proerties added to represnt the landmark object from the data model
    let title: String?
    let userName: String
    let isCurrentUserIndicator: Bool
    let coordinate: CLLocationCoordinate2D
    let landmarkId: String?
    let scope: String
    let distanceInfo: String?
    
    // convenience intilizer to create an annotation to show the current location human icon as an indicator
    init(message: String, username: String, location: CLLocationCoordinate2D, currentUserIndicator: Bool = false, currentLogedInUsername: String = "") {
        title = message
        userName = username
        coordinate = location
        isCurrentUserIndicator = currentUserIndicator
        scope = currentLogedInUsername == userName ? "Mine" : "Others"
        landmarkId = ""
        distanceInfo = ""
        
        super.init()
    }
    
    // new intilazer that takes a data-model object and also currently logged-in username to determine 
    // scope of this annotation (to color code the pin, also faciliate scope based search)
    init(landmark: Landmark, currentLogedInUsername: String) {
        title = landmark.note
        userName = landmark.savedByUserName
        coordinate = CLLocationCoordinate2D(latitude: landmark.location.latitude, longitude: landmark.location.longitude)
        isCurrentUserIndicator = false
        scope = currentLogedInUsername == userName ? "Mine" : "Others"
        landmarkId = landmark.landmarkId
        distanceInfo = landmark.distanceInfo
        
        super.init()
    }
    
    // MKAnnotation needs subtitle to display in the callout
    var subtitle: String? {
        // show the username in the second line of the call-out under the bold font header
        return userName
    }
    
    // Annotation callout opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        let addressDict = [String(CNPostalAddressStreetKey): subtitle as AnyObject]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        
        return mapItem
    }
    
}
