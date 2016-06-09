//
//  LandmarksViewController.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 6/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


// The view controller for the main page with the map view
class LandmarksViewController: UIViewController, LandmarksViewModelDelegate {
    
    // outlet connections from storyboard
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var searchControllerHolderView: UIView!

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    @IBOutlet weak var currentLocationToggleButton: UIButton!
    
    @IBOutlet weak var boundarySegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    
    // location manger to cotantly update user location
    var locationManager: CLLocationManager!
    
    // to indicate whether currently updating location
    var currentlyUpdatingLocation: Bool = true
    
    // activity spinner
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    // search controller for searching landmarks
    let searchController = UISearchController(searchResultsController: nil)
    
    // the view-model
    var viewModel: LandmarksViewModel!
    
    
    //------------------------------------------------------------------------------------------------
    // MARK: - View controller life cycle methods
    //------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameLabel.alpha = 0.0
        self.extendedLayoutIncludesOpaqueBars = true
        self.definesPresentationContext = true
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the search bar
        searchController.searchBar.scopeButtonTitles = ["All", "Mine", "Others"]
        searchController.searchBar.searchBarStyle = .Prominent
        searchController.searchBar.barTintColor = Color.veryLightGreenColor
        searchController.searchBar.keyboardType = .Default
        searchController.searchBar.autocorrectionType = .No
        searchController.searchBar.autocapitalizationType = .None
        
        // add the search controller to its holding view
        searchControllerHolderView.addSubview(self.searchController.searchBar)
        
        
        // check for device type and adjust the UI to make it adaptive for all iOS devices (iPhone /iPad)
        if UIDevice.currentDevice().getDeviceType() == .iPhone4 {
            mapViewHeightConstraint.constant = -20.0
        }
        else if UIDevice.currentDevice().getDeviceType() == .iPhone5 {
            mapViewHeightConstraint.constant = 25.0
        }
        else if UIDevice.currentDevice().getDeviceType() == .iPhone6 {
            mapViewHeightConstraint.constant = 70.0
        }
        else {
            mapViewHeightConstraint.constant = 100.0
        }
        if UIDevice.currentDevice().isDeviceiPad() {
            mapViewHeightConstraint.constant = 200.0
        }
        
        // setting up the location manager to constatnly update location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // by deafult location is always being updated and the blue arrow button is enabled to indicate this
        currentlyUpdatingLocation = true
        currentLocationToggleButton.setImage(Icon.updateLocationEnabledImage, forState: UIControlState.Normal)
        
        // setting up mapview delegate
        mapView.delegate = self
        
        // intialize the view-model
        viewModel = LandmarksViewModel(delegate: self)
        
        
        
        /* Checking whether user has changed bounadry selection preference previously.
         By default the entire planet is being searched for landmarks and they are sorted geo-spatially from the nearest to farthest.
         
         Therefore, if a user searches for a landmarks based on keywords, the reesult set would have all matchig landmarks based on the text in user name or note. 
         An Australian user may see results from American users too. This could be inconvenient to zoom out and zoom in to another country and that might not be necessary at all.
         If the user is only concerend with landmarks within a sepcific boundary, he can choose either 1km, 10km, 100km radius. In that case, the geo-spatial searches would
         checking for that boundary only to help/guide the user with relevant landamarks only (not too many irrelevant ones which are too far from the user)
         */
        
        let preferences = NSUserDefaults.standardUserDefaults()
        if preferences.objectForKey("BOUNDARY_PREFERENCE") == nil {
            // default search strategy is the entire planet
            boundarySegmentedControl.selectedSegmentIndex = 3
            preferences.setInteger(2, forKey: "BOUNDARY_PREFERENCE")
            preferences.synchronize()
        }
        else {
            let savedValue = preferences.integerForKey("BOUNDARY_PREFERENCE")
            boundarySegmentedControl.selectedSegmentIndex = savedValue
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // display the logged-in user name at the bottom of the UI
        userNameLabel.text = viewModel.currentUserName
        
        switch boundarySegmentedControl.selectedSegmentIndex {
            case 0: viewModel.selectedBoundary = .ONE_KM
            case 1: viewModel.selectedBoundary = .TEN_KM
            case 2: viewModel.selectedBoundary = .HUNDRED_KM
            case 3: viewModel.selectedBoundary = .ENTIRE_PLANET
            default: break
        }
        
        // if for some reason location service setting was turned off (denied) by the user from the app settings, prompt the user that the usgae of location service is manadatory
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.NotDetermined &&
            (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Restricted) {
            let alert = Utils.createCustomAlert("Warning", message: "Access to Location Service has been denied or restricted. Please go to settings and change permission.")
            let settingsAction: UIAlertAction = UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            alert.addAction(settingsAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        // animate the alpha value of user name hint
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.userNameLabel.alpha = 1.0
            }, completion: nil)
        
    }
    
    // --------------------------------------------
    // MARK :- Misclaneous view controller methods
    // --------------------------------------------
    
    // status bar preference
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    

    
    // -------------------------------
    // MARK :- user Actions on the UI
    // -------------------------------

    @IBAction func refreshLandmarksAction(sender: AnyObject) {
        showActivityLoader()
        
        // ask the view-model to load the landmarks
        viewModel.getAllLandmarks()
    }
    
    @IBAction func logoutAction(sender: AnyObject) {
        let alertMenu = Utils.createCustomActionSheetAlert("", message: "Are you sure that you want to log out?")
        let okAction = UIAlertAction(title: "Confirm", style: .Destructive) {
            (action: UIAlertAction!) -> Void in
            self.showActivityLoader()
            self.viewModel.logout()
        }
        alertMenu.addAction(okAction)
        alertMenu.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        if UIDevice.currentDevice().isDeviceiPad() {
            alertMenu.popoverPresentationController?.barButtonItem = logoutButton
        }
        self.presentViewController(alertMenu, animated: true, completion: nil)
    }
    
    
    // user can temporarily turn off location update to be able to zoom in the search results, becuase cosntant location update always zoom out the map
    // to 500 m ter boundary, and user might feel difficulty while he is not static and onteh move but also trying to zoom in some section of the map
    // the blue arrorw head o the bottom-right side of the map is used for this purpose
    
    @IBAction func toggleUpdateCurrentLocation(sender: AnyObject) {
        currentlyUpdatingLocation = !self.currentlyUpdatingLocation
        if currentlyUpdatingLocation {
            startUpdatingCurrentLocation()
        }
        else {
            stopUpdatingCurrentLocation()
        }
    }
    
    @IBAction func boundaryChangeAction(sender: AnyObject) {
        // user is chnaging boundary preference
        switch self.boundarySegmentedControl.selectedSegmentIndex {
            case 0 : viewModel.selectedBoundary = BoundaryRange.ONE_KM
            case 1 : viewModel.selectedBoundary = BoundaryRange.TEN_KM
            case 2 : viewModel.selectedBoundary = BoundaryRange.HUNDRED_KM
            case 3 : viewModel.selectedBoundary = BoundaryRange.ENTIRE_PLANET
            default: break
        }
        
        // save the user preference, see comment above at teh bottom of the viewDidLoad mehtod
        let preferences = NSUserDefaults.standardUserDefaults()
        preferences.setInteger(self.boundarySegmentedControl.selectedSegmentIndex, forKey: "BOUNDARY_PREFERENCE")
        preferences.synchronize()
        self.displayAlert("Information", message: "Landmarks data will be confined within your selected boundary radius when you perform a network refresh using the top-left refresh button.")
    }
    
    
    @IBAction func saveLandmarkAction(sender: AnyObject) {
        self.performSaveLandmarkWithAlert("Saving a Landmark?", message: "\nYou're going to add a landmark at your current location. \n\nPlease enter a short note.", isUpdating: false)
    }
    
    
    
    // ------------------------------------
    // MARK :- Helper methods
    // ------------------------------------
    
    func stopUpdatingCurrentLocation() {
        currentlyUpdatingLocation = false
        currentLocationToggleButton.setImage(Icon.updateLocationDisabledImage, forState: UIControlState.Normal)
        locationManager.stopUpdatingLocation()
        mapView.showsUserLocation = false
    }
    
    func startUpdatingCurrentLocation() {
        currentlyUpdatingLocation = true
        currentLocationToggleButton.setImage(Icon.updateLocationEnabledImage, forState: UIControlState.Normal)
        locationManager.startUpdatingLocation()
        // as soon as location update is happening zoom into the region
        setMapRegion(viewModel.latestUpdatedLocation.coordinate, distance: 500)
        mapView.showsUserLocation = true
    }
    
    func setMapRegion(location: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let region:MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(location, distance, distance)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

    /**
     To show an alert with user input field for saving/editing a landmark
     
     - parameter title:              The title of the alert
     - parameter message:            The message to show in the alert
     - parameter isUpdating:         To indicate whther it is an update
     - parameter updatinglandMarkId: If being updated, the landmark Id is necessary
     */
    func performSaveLandmarkWithAlert(title: String, message: String, isUpdating: Bool = false, updatinglandMarkId: String = "") {
        
        // inactivate the search controller UI
        searchController.searchBar.resignFirstResponder()
        searchController.searchBar.selectedScopeButtonIndex = 0
        searchController.active = false
        
        let alertController = Utils.createCustomAlert(title, message: message)
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (_) in
            let noteTextField = alertController.textFields![0] as UITextField
            self.showActivityLoader()
            if isUpdating {
                self.viewModel.updateRemarkForLandmark(updatinglandMarkId, newNote: (noteTextField.text?.trim().condenseWhitespace())!)
            }
            else {
                self.viewModel.saveLandmarkWithRemark((noteTextField.text?.trim().condenseWhitespace())!)
            }
        }
        // by default save button action is disbaled util the user types 3 or kore characters
        saveAction.enabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            // customize the text field
            textField.placeholder = isUpdating ? "Update your note here..." : "Type your note here..."
            textField.keyboardType = .Default
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.returnKeyType = .Done
            textField.clearButtonMode = .WhileEditing
            
            // bind the text chnage observer and enable the action abutton
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                saveAction.enabled = textField.text!.trim().condenseWhitespace().characters.count >= 3
            }
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showActivityLoader() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
        activityIndicator.center = CGPointMake(self.view.center.x, (self.view.center.y - 0))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        self.view.addSubview(activityIndicator)
        self.view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func stopActivityLoader() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    
    func displayAlert(title:String, message:String) {
        let alert = Utils.createCustomAlert(title, message: message)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    /**
     To calculate the recently updated current user human icon annotation
     */
    func calculateRecentlyUpdatedHumanAnnotation() -> [MKAnnotation] {
        // filter out the human indicator
        let recentlyAddedHumanAnnotations = mapView.annotations.filter({ (item) -> Bool in
            if item is MKUserLocation {
                return false
            }
            else {
                let annotation = item as! AnnotationViewModel
                return annotation.isCurrentUserIndicator && item.coordinate.latitude == viewModel.latestUpdatedLocation.coordinate.latitude && item.coordinate.longitude == viewModel.latestUpdatedLocation.coordinate.longitude
            }
        })
        return recentlyAddedHumanAnnotations
    }
    
    /**
     To calculate all te real annotations saved from netowrk. i.e. everything except for current user Dot and human indicator
     */
    func calculateAllNetworkSavedAnnotations() -> [MKAnnotation] {
        // filter out any abnnotation that is not teh Dot or the human indicator
        return mapView.annotations.filter({ (item) -> Bool in
            if item is MKUserLocation {
                return false
            }
            else {
                let annotation = item as! AnnotationViewModel
                if annotation.isCurrentUserIndicator && item.coordinate.latitude == viewModel.latestUpdatedLocation.coordinate.latitude && item.coordinate.longitude == viewModel.latestUpdatedLocation.coordinate.longitude {
                    return false
                }
                else {
                    return true
                }
            }
        })
    }
    

    
    // -----------------------------------------------------------------------------------------------------
    // MARK :- LandmarksViewModelDelegate method implementation, called by the view-model to notify anything
    // -----------------------------------------------------------------------------------------------------

    func logoutSuccess() {
        Utils.delay(1.5) {
            self.stopActivityLoader()
            self.navigationController?.navigationBar.hidden = true
            self.performSegueWithIdentifier("backToLoginScreenFromMapSegue", sender: self)
        }
    }
    
    func landmarkSaveOrDeleteWithSuccess(message: String) {
        Utils.delay(1.5) {
            self.stopActivityLoader()
            self.displayAlert("Success", message: message)
            self.startUpdatingCurrentLocation()
        }
    }
    
    func getAllLandmarkWithSuccess(count: Int) {
        Utils.delay(1.5) {
            self.stopActivityLoader()
            // showing user a message about how many landmarks located based on the boundary preference
            let countVal: String = count > 0 ? "\(count)" : "No"
            var message = "\(countVal) landmarks located after searching globally everywhere."
            if self.viewModel.selectedBoundary != .ENTIRE_PLANET {
                var distance = "1 km"
                switch self.viewModel.selectedBoundary {
                    case .ONE_KM : distance = "1 km"
                    case .TEN_KM : distance = "10 km"
                    case .HUNDRED_KM : distance = "100 km"
                    default: break
                }
                message = "\(countVal) landmarks located after searching \(distance) radius from your current location."
            }
            self.displayAlert("Information", message: message)
            if count > 0 {
                self.searchController.active = false
                self.searchController.searchBar.text = ""
                self.reloadAnnotations()
            }
        }
    }
    
    func operationFailureWithErrorMessage(title: String, message: String) {
        Utils.delay(1.5) {
            self.stopActivityLoader()
            self.displayAlert(title, message: message)
        }
    }
    
    func reloadAnnotations() {
        if searchController.active {
            stopUpdatingCurrentLocation()
        }
        // remove existing annotations
        mapView.removeAnnotations(calculateAllNetworkSavedAnnotations())
        
        // add back the annotations back taking into consideration of any search
        let targetAnnotations =  searchController.active  ? viewModel.filteredLandmarkAnnotations : viewModel.landmarkAnnotations
        mapView.addAnnotations(targetAnnotations)
        
        // setting the map region 500 meters around the first search result, searched geo-spatially from the nearest to farthest
        if targetAnnotations.count > 0 {
            setMapRegion(targetAnnotations[0].coordinate, distance: 500)
        }
    }
    
}

//----------------------------------------------
// MARK: - CLLocationManagerDelegate
//----------------------------------------------

extension LandmarksViewController: CLLocationManagerDelegate {
   
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]

        // ass soon as a location updated, pass this information to the other list view controller
        NSNotificationCenter.defaultCenter().postNotificationName("UpdateLocation", object: userLocation)
        
        // if a new location is received, update the location and relocate the human indicator
        if viewModel.latestUpdatedLocation.coordinate.latitude != userLocation.coordinate.latitude || viewModel.latestUpdatedLocation.coordinate.longitude != userLocation.coordinate.longitude {
            
            // set the region 500 meters
            if currentlyUpdatingLocation {
                setMapRegion(userLocation.coordinate, distance: 500)
            }
            
            // remove the existing human indicator
            mapView.removeAnnotations(calculateRecentlyUpdatedHumanAnnotation())
            
            // add the human indicator at the new location
            let annotation = AnnotationViewModel(message: "I am here now.", username: viewModel.currentUserName, location: userLocation.coordinate, currentUserIndicator: true, currentLogedInUsername: viewModel.currentUserName)
            mapView.addAnnotation(annotation)
            
            // if the location update is happening for the first time after view load, call the delegate to fetch all the landmarks from backend
            // by default (0, 0) location is used to start with before any location updates happen
            if viewModel.latestUpdatedLocation.coordinate.latitude == 0 && viewModel.latestUpdatedLocation.coordinate.longitude == 0
            {
                viewModel.latestUpdatedLocation = userLocation
                showActivityLoader()
                viewModel.getAllLandmarks()
            }
            
            // always update the new location into the view-model property
            viewModel.latestUpdatedLocation = userLocation
        }
    }
}



//---------------------------------------------------
// MARK: - UISearchBarDelegate
//---------------------------------------------------
extension LandmarksViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        // as soon as the scope button selection chnaged ("All", "Mine", "Others"), ask te view model to search
        viewModel.filterContentForSearchTextAndScope(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        
        // as soon as the search cancel button hit, chnage the scpe back to "All", and start uodating the user location just
        // in case user has turned it off to zoom into the map
        searchBar.selectedScopeButtonIndex = 0
        startUpdatingCurrentLocation()
    }
    
}



//---------------------------------------------------
// MARK: - UISearchResultsUpdating
//---------------------------------------------------
extension LandmarksViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        // as soon as tthe text chnages on the search bar, ask te view model to search
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        
        viewModel.filterContentForSearchTextAndScope(searchController.searchBar.text!, scope: scope)
    }
}



//---------------------------------------------------
// MARK: - MKMapViewDelegate
//---------------------------------------------------
extension LandmarksViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? AnnotationViewModel {
            
            // There could be three types of annotation image
            // - Current user location (human icon)
            // - A red baloon/pin to indicate landmarks saved by other users
            // - A purple baloon/pin to indicate the user's own landmark
            var identifier = ""
            var targetAnnotationImage: UIImage? = nil
            
            // determine the pin image based on the conditions
            // also calculate the right resuable view identifer depending on the pin type
            if annotation.isCurrentUserIndicator {
               identifier = "my_current_location"
               targetAnnotationImage = Icon.myCurrentLocationAnnotaionImage
            }
            else if annotation.userName == viewModel.currentUserName {
                identifier = "my_saved_landmark"
                targetAnnotationImage =   Icon.myLandmarkAnnotationImage
            }
            else {
                identifier = "others_saved_landmark"
                targetAnnotationImage =  Icon.othersLandmarkAnnotationImage
            }
            
            var view: MKAnnotationView
            // try to dequeue the view
            if let dequeuedView  = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)  {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: 0, y: -5)
                let disclosureButton = UIButton(frame: CGRectMake(0, 0, 40, 24))
                disclosureButton.setImage(Icon.detailDisclosure, forState: UIControlState.Normal)
                
                view.rightCalloutAccessoryView =   disclosureButton as UIView //UIButton(type: <#T##UIButtonType#>) //Icon.detailDisclosure as UIView //UIButton(type: .DetailDisclosure) as UIView
                view.rightCalloutAccessoryView?.tintColor = Color.darkGreenColor
                view.rightCalloutAccessoryView?.tintAdjustmentMode = .Normal
                view.centerOffset = CGPointMake(0, -25)
                
                // assign the correct annotation pin mage
                view.image = targetAnnotationImage
            }
            return view
        }
        return nil
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation as! AnnotationViewModel
        
        // show call-out accessory view only if it's a network saved landmark
        if annotation.isCurrentUserIndicator == false {
            
            let alertTitle = (annotation.userName == viewModel.currentUserName) ? "Your Landmark" : "saved by: \(annotation.userName)"
            
            let alertController = Utils.createCustomAlert(alertTitle, message: annotation.title!)
            
            // To open up the Apple's Maps app with the location
            let gotoMapAction = UIAlertAction(title: "Show in Maps", style: UIAlertActionStyle.Default) { (_) in
                // open the Maps app to get the driving directions
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                annotation.mapItem().openInMapsWithLaunchOptions(launchOptions)
            }
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil)
            alertController.addAction(gotoMapAction)
            alertController.addAction(cancelAction)
            
            // if this annotation/landmark is owned by the logged in user, then Edit & Delete options are enabled
            if annotation.userName == viewModel.currentUserName {
                
                // create the update action
                let updateAction = UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default) { (_) in
                    self.performSaveLandmarkWithAlert("Editing this landmark?", message: "Please change the existing note/remark.", isUpdating: true, updatinglandMarkId: annotation.landmarkId!)
                }
                alertController.addAction(updateAction)
                
                // create the delete action
                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive) { (_) in
                    self.searchController.searchBar.resignFirstResponder()
                    self.searchController.searchBar.selectedScopeButtonIndex = 0
                    self.searchController.active = false
                    self.showActivityLoader()
                    self.viewModel.deleteLandmark(annotation.landmarkId!)
                }
                alertController.addAction(deleteAction)
            }
            // show the controller when call-out was tapped
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        // apply some animation as soon as the annotation sare being added on the map
        // alpha value chnages and a little jump happens
        dispatch_async(dispatch_get_main_queue(), {
            for annView in views {
                let endFrame = annView.frame
                annView.alpha = 0.0
                annView.frame = CGRectOffset(endFrame, 0, -5)
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    annView.frame = endFrame
                    annView.alpha = 1.0
                    }, completion: nil)
            }
        })
    }
    
}


