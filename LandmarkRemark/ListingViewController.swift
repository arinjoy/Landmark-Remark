//
//  ListingViewController.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 8/06/2016.
//  Copyright © 2016 Arinjoy Biswas. All rights reserved.
//

import UIKit
import MapKit
import Contacts


// The view controller for the second tab page with the list of landmarks
class ListingViewController: UITableViewController, ListingViewModelDelegate {
    
    // outlet connections from storyboard
    @IBOutlet weak var refeshControl: UIRefreshControl!
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    // the view model
    var viewModel: ListingViewModel!
    
    // template cell for table view
    fileprivate var templateCell: UITableViewCell?
    
    // activity spinner
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    // search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    //------------------------------------------------------------------------------------------------
    // MARK: - View controller life cycle methods
    //------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.definesPresentationContext = true
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the search bar
        searchController.searchBar.scopeButtonTitles = ["All", "Mine", "Others"]
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.barTintColor = Color.veryLightGreenColor
        searchController.searchBar.keyboardType = .default
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        
        // add the search bar to the table view's header view
        self.tableView.tableHeaderView = searchController.searchBar
        
        // intilaize the nib for custome table view cell
        let nib = UINib(nibName: "LandmarkCustomCell", bundle: nil)
        
        // create an instance of the template cell and register with the table view
        templateCell = nib.instantiate(withOwner: nil, options: nil)[0] as? UITableViewCell
        self.tableView.register(nib, forCellReuseIdentifier: templateCell!.reuseIdentifier!)
        
        // intialize the view-model
        viewModel = ListingViewModel(delegate: self)
        
        // listen for any changes in location updates from the other map view controller
         NotificationCenter.default.addObserver(self, selector: #selector(ListingViewController.locationUpdated), name: NSNotification.Name(rawValue: "UpdateLocation"), object: nil)
        
        // wait a moent to receive at least some current location update and then call the view model to load all the landmarks
        // distance hints could be calculated based on the current location update (if received any)
        Utils.delay(0.5) {
            self.showActivityLoader()
            Utils.delay(1.0) {
                self.viewModel.getAllLandmarks()
            }
        }
    }
    
    
    // Mark: - Selector action when a notification received with name "UpdateLocation"
    func locationUpdated(_ notification: Notification) {
        // extract the location from the notification and save to its own view model
        // the current location is being passed from the map page view conntrollers always, and both of their view models have latest location update
        // and they are alsways in sync
        guard let object = notification.object else {
            return
        }
        if object is CLLocation {
            viewModel.latestUpdatedLocation = (object as! CLLocation)
        }
    }
    

    //----------------------------------------------------------------------------------
    // MARK: - Table view data source
    //----------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // search conroller is active, look for data in the filtered list
        // otherwise, in the main list
        if viewModel != nil {
            if searchController.isActive  {
                return viewModel.filteredLandmarks.count
            }
            return viewModel.landmarks.count
        }
        else {
            // if view model has not been intialized yet, return 0 items
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // get the view model for the row
        var cellViewModel = viewModel.landmarks[indexPath.row]
        if searchController.isActive  {
            cellViewModel = viewModel.filteredLandmarks[indexPath.row]
        }
        
        // dequeue the cell using reuse identifer
        let cell = tableView.dequeueReusableCell(withIdentifier: templateCell!.reuseIdentifier!)!
        
        if let view = cell as? LandmarkCustomCell {
            // the cell is of type LandmarkCustomCell, bind the view-model to it
           view.bindViewModel(cellViewModel, currentUserName: viewModel.currentUserName)
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // calculate the table view cell height depening on the device screen size
        return Utils.determineTableCellHeight()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let annotation = viewModel.landmarks[indexPath.row]
            // when a selection happens on table row call, show an alert but customise the alert and its actions depending on the
            // owner/creator of that landmark
            let alertTitle = annotation.userName == viewModel.currentUserName ? "Your Landmark" : "saved by: \(annotation.userName)"
            let alertController = Utils.createCustomAlert(alertTitle, message: annotation.title!)
        
            // To open up the Apple's Maps app with the location
            let gotoMapAction = UIAlertAction(title: "Show in Maps", style: UIAlertActionStyle.default) { (_) in
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                annotation.mapItem().openInMaps(launchOptions: launchOptions)
            }
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil)            
            alertController.addAction(gotoMapAction)
            alertController.addAction(cancelAction)
        
            // if this landmark is owned by the logged in user, then Edit & Delete options are enabled
            if annotation.userName == viewModel.currentUserName {
                let updateAction = UIAlertAction(title: "Edit", style: UIAlertActionStyle.default) { (_) in
                    self.performEditLandmarkWithAlert(annotation.landmarkId!)
                }
                alertController.addAction(updateAction)
                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { (_) in
                    self.searchController.searchBar.resignFirstResponder()
                    self.searchController.searchBar.selectedScopeButtonIndex = 0
                    self.searchController.isActive = false
                    self.showActivityLoader()
                    self.viewModel.deleteLandmark(annotation.landmarkId!)
                }
                alertController.addAction(deleteAction)
            }
            // show the alert
            self.present(alertController, animated: true, completion: nil)
    }
 

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // left swipe delete is only enabled for user's own lanadmarks
        let annotation = viewModel.landmarks[indexPath.row]
        if annotation.userName == viewModel.currentUserName {
            return true
        }
        else {
            return false
        }
    }
 

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // left swipe delete is only enabled for user's own landmarks
        if editingStyle == .delete {
            // Delete the row from the data source
            let annotation = viewModel.landmarks[indexPath.row]
            
            showActivityLoader()
            
            // determine the landmark Id from the view model and tell the view model to delete the landmark
            viewModel.deleteLandmark(annotation.landmarkId!, swipeDeleteIndex: indexPath.row)
        }
    }
 

    // -------------------------------
    // MARK :- user Actions on the UI
    // -------------------------------

    /**
     Pull to refresh control always checks from the network
     */
    @IBAction func refreshFromNetowrk(_ sender: UIRefreshControl) {
        viewModel.getAllLandmarks()
    }


    @IBAction func logOutAction(_ sender: AnyObject) {
        
        let alertMenu = Utils.createCustomActionSheetAlert("", message: "Are you sure that you want to log out?")
        let okAction = UIAlertAction(title: "Confirm", style: .destructive) {
            (action: UIAlertAction!) -> Void in
            self.showActivityLoader()
            self.viewModel.logout()
        }
        alertMenu.addAction(okAction)
        alertMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if UIDevice.current.isDeviceiPad() {
            alertMenu.popoverPresentationController?.barButtonItem = self.logoutButton
        }
        self.present(alertMenu, animated: true, completion: nil)
        
    }

    
    
    // -----------------------------------------------------------------------------------------------------
    // MARK :- ListingViewModelDelegate method implementation, called by the view-model to notify anything
    // -----------------------------------------------------------------------------------------------------
    func logoutSuccess() {
        Utils.delay(1.5) {
            self.stopActivityLoader()
            self.navigationController?.navigationBar.isHidden = true
            self.performSegue(withIdentifier: "backToLoginScreenFromListSegue", sender: self)
        }
    }
    
    func getAllLandmarkWithSuccess(_ count: Int) {
        Utils.delay(1.0) {
            if self.activityIndicator.isAnimating {
                self.stopActivityLoader()
            }
            if self.refeshControl.isRefreshing {
                self.refeshControl.endRefreshing()
            }
            self.tableView.reloadData()
            self.searchController.isActive = false
            self.searchController.searchBar.text = ""
        }
    }
    
    
    func landmarkUpdateWithSuccess(_ message: String) {
        Utils.delay(1.0) {
            self.stopActivityLoader()
            self.tableView.reloadData()
        }
    }
    
    // swipe delete row index is passed and received back
    func landmarDeleteWithSuccess(_ message: String, swipeDeleteIndex: Int = -1) {
        // swipe delete index is used as -1 for non-swipe delete action, such as from the alert pop-up action
        if swipeDeleteIndex == -1 {
            Utils.delay(1.0) {
                self.stopActivityLoader()
                self.tableView.reloadData()
            }
        }
        else {
            self.stopActivityLoader()
            let indexPath = IndexPath(row: swipeDeleteIndex, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
    
    func operationFailureWithErrorMessage(_ title: String, message: String) {
        Utils.delay(1.0) {
            self.stopActivityLoader()
            self.displayAlert(title, message: message)
        }
    }
    
    func reloadLandmarks() {
        self.tableView.reloadData()
    }
    
    
    
    
    // ------------------------------------
    // MARK :- Helper methods
    // ------------------------------------
    
    func displayAlert(_ title:String, message:String) {
        let alert = Utils.createCustomAlert(title, message: message)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showActivityLoader() {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: -128, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: (self.view.center.y - 56))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        self.view.addSubview(activityIndicator)
        self.view.bringSubview(toFront: activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
    }
    
    func stopActivityLoader() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func performEditLandmarkWithAlert(_ updatinglandMarkId: String = "") {
        searchController.searchBar.resignFirstResponder()
        searchController.searchBar.selectedScopeButtonIndex = 0
        searchController.isActive = false
        
        let alertController = Utils.createCustomAlert("Editing this landmark?", message: "Please change the existing note/remark.")
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            let noteTextField = alertController.textFields![0] as UITextField
            self.showActivityLoader()
            self.viewModel.updateRemarkForLandmark(updatinglandMarkId, newNote: (noteTextField.text?.trim().condenseWhitespace())!)
        }
        
        saveAction.isEnabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "Update your note here..."
            textField.keyboardType = .default
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
            textField.returnKeyType = .done
            textField.clearButtonMode = .whileEditing
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                saveAction.isEnabled = textField.text!.trim().condenseWhitespace().characters.count >= 3
            }
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}



//---------------------------------------------------
// MARK: - UISearchBarDelegate
//---------------------------------------------------

extension ListingViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        // as soon as the scope button selection chnaged ("All", "Mine", "Others"), ask te view model to search
        viewModel.filterContentForSearchTextAndScope(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // as soon as the search cancel button hit, chnage the scope back to "All"        
        searchBar.selectedScopeButtonIndex = 0
    }
}



//---------------------------------------------------
// MARK: - UISearchResultsUpdating
//---------------------------------------------------

extension ListingViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // as soon as tthe text chnages on the search bar, ask te view model to search
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        viewModel.filterContentForSearchTextAndScope(searchController.searchBar.text!, scope: scope)
    }
}


