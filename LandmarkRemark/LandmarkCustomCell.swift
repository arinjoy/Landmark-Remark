//
//  LandmarkCustomCell.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 7/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit
import MapKit

class LandmarkCustomCell: UITableViewCell, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var remarkLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    
    @IBOutlet weak var longitudeLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    // to let the view know about the current username
    var currentUserName = ""
    
    
    /**
     View life-cycle method
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView.delegate = self
        mapView.layer.cornerRadius = 10.0
        mapView.layer.masksToBounds = true
    }

    
    /**
     To bind the view-model properties with the cell view
     
     - parameter viewModel:       The view-model to bind
     - parameter currentUserName: The currently logged-in username to save as information to this class
     */
    func bindViewModel(_ viewModel: AnyObject, currentUserName: String) {
        
        self.currentUserName = currentUserName
        
        if let landmarkViewModel = viewModel as? AnnotationViewModel {
            
            DispatchQueue.main.async(execute: {
                
                let region:MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(landmarkViewModel.coordinate, 2000, 2000)
                
                self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                let annotation = AnnotationViewModel(message: landmarkViewModel.title!, username: landmarkViewModel.userName, location: landmarkViewModel.coordinate)
                self.mapView.addAnnotation(annotation)
                
                // binding the UI elements of the view with view model properties, and apply some formatting
                
                self.remarkLabel.text = landmarkViewModel.title!
                self.userNameLabel.text = "user: " + landmarkViewModel.userName
                self.latitudeLabel.text = "\(Double(round(100000 * viewModel.coordinate.latitude) / 100000))"
                self.longitudeLabel.text = "\(Double(round(100000 * viewModel.coordinate.longitude) / 100000))"
                
                // the view model might not have distance info, if the location was not updated yet
                self.distanceLabel.text = ""
                if let info = landmarkViewModel.distanceInfo  {
                    self.distanceLabel.text = info
                }
            })
        }
    }
    
    
    
    //-----------------------------------------------
    // MARK: - MKMapViewDelegate method
    //-----------------------------------------------
    
    /** Returns the view associated with the specified annotation object
     
     - parameter mapView:   The map view that requested the annotation view.
     - parameter annotation: The object representing the annotation that is about to be displayed.
     
     - returns: The annotation view to display for the specified annotation or nil if you want to display a standard annotation view.
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? AnnotationViewModel {
            // there could be two kinds of pin: current user landmark (purple) or other user landmark (red)
            var identifier = ""
            var targetAnnotationImage: UIImage? = nil

            if annotation.userName == currentUserName {
                identifier = "my_saved_landmark"
                targetAnnotationImage = Icon.myLandmarkAnnotationImage
            }
            else {
                identifier = "others_saved_landmark"
                targetAnnotationImage = Icon.othersLandmarkAnnotationImage
            }
            
            var view: MKAnnotationView
            
            // try to re-use and deque the view
            if let dequeuedView  = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)  {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: 0, y: -2)
                view.image = targetAnnotationImage
                view.centerOffset = CGPoint(x: 0, y: -15)
           }
            return view
        }
        
        return nil
    }
    
}
