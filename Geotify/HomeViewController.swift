//
//  HomeViewController.swift
//  Geotify
//
//  Created by Jakub Josef on 04.05.15.
//  Copyright (c) 2015 Jakub Josef. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class HomeViewController: UITableViewController,AddGeotificationsViewControllerDelegate,CLLocationManagerDelegate{
  let kSavedItemsKey = "FENCES"
  let kBasicHeaderText = "Geotifications"
  @IBOutlet weak var navbarLabel: UINavigationItem!
  
  let locationManager = CLLocationManager()
  var geotifications = [Geotification]()
  var loggedUsername = ""
  // view functions
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(true)
    
    let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let isLoggedIn:Int = prefs.integerForKey("ISLOGGEDIN") as Int
    if (isLoggedIn != 1) {
      self.performSegueWithIdentifier("goto_login", sender: self)
    } else {
      loggedUsername = prefs.valueForKey("USERNAME") as! String
      refreshHeader()
    }
    //refresh all geotifications
    geotificationChanged(nil)
    
  }
  override func viewDidLoad() {
    
    super.viewDidLoad()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    loadAllGeotifications()
  }
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // add geotification from list segue
    if segue.identifier == "addGeotificationFromList" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      // delegate to this controller
      vc.delegate = self
    } else if segue.identifier == "showDetail"{
      if let indexPath = self.tableView.indexPathForSelectedRow() {
        let geotification = geotifications[indexPath.row] as Geotification
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! AddGeotificationViewController
        // delegate to this controller
        controller.delegate = self
        controller.viewMode = "edit"
        controller.detailItem = geotification
        //controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  // MARK: AddGeotificationViewControllerDelegate
  
  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType, editInsteadOfAdd: Bool = false) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    // 1
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius
    
    let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
    if(!editInsteadOfAdd){
      //adding geotification
      addGeotification(geotification)
      startMonitoringGeotification(geotification)
      ApiUtils.storeGeotification(geotification,sessionID: kTESTSESSIONID)
    }else{
      //editing geotification
      editGeotification(geotification)
    }
    refreshGeotificationStorage()
  }
  
  // MARK: Action handlers
  @IBAction func logoutClicked(sender: AnyObject) {
      let appDomain = NSBundle.mainBundle().bundleIdentifier
      NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
    
      self.performSegueWithIdentifier("goto_login", sender: self)
  }
  // MARK: Loading and saving functions
 
  func loadAllGeotifications() {
    geotifications = []
    var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    if let savedItems = prefs.arrayForKey(kSavedItemsKey) {
      for savedItem in savedItems {
        if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
          addGeotification(geotification)
        }
      }
    }
  }
  func addGeotification(geotification: Geotification) {
    geotifications.append(geotification)
    startMonitoringGeotification(geotification)
    let indexPath = NSIndexPath(forRow: geotifications.count-1, inSection: 0)
    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }
  func editGeotification(geotification:Geotification){
    //get index of edited element
    for (index, arrayGeotification) in enumerate(geotifications){
      if arrayGeotification.identifier == geotification.identifier {
        //make changes
        geotifications[index] = geotification
        let path = NSIndexPath(forItem: index, inSection: 0)
        tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .None)
      }
    }
  }
  func removeGeotification(indexPath: NSIndexPath){
    geotifications.removeAtIndex(indexPath.row)
    stopMonitoringGeotification(geotifications[indexPath.row])
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    refreshGeotificationStorage();
  }
  
  func refreshGeotificationStorage() {
    var items = NSMutableArray()
    for geotification in geotifications {
      let item = NSKeyedArchiver.archivedDataWithRootObject(geotification)
      items.addObject(item)
    }
    NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  func refreshHeader(){
    //self.navbarLabel.title = kBasicHeaderText+" (\(geotifications.count)) - " + loggedUsername
    self.navbarLabel.title = kBasicHeaderText+" (\(geotifications.count))"
  }
  
  // MARK: Table view functions
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return geotifications.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
    
    let fence = geotifications[indexPath.row] as Geotification
    cell.textLabel!.text = fence.note;
    if (fence.eventType == EventType.OnEntry){
      cell.detailTextLabel!.text = "On entry"
    }else{
      cell.detailTextLabel!.text = "On exit"
    }
    return cell
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      removeGeotification(indexPath)
    } else if editingStyle == .Insert {
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }
  func geotificationChanged(changedGeotification: Geotification?){
      for (index, geotification) in enumerate(geotifications){
        // use nil for refresh all
        if changedGeotification === nil || geotification == changedGeotification {
          let path = NSIndexPath(forItem: index, inSection: 0)
          tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .None)
        }
      }
    }
  
  // MARKER: location functions
  
  func regionWithGeotification(geotification: Geotification) -> CLCircularRegion {
    let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
    region.notifyOnEntry = (geotification.eventType == .OnEntry)
    region.notifyOnExit = !region.notifyOnEntry
    return region
  }
  
  func startMonitoringGeotification(geotification: Geotification) {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
      return
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
    }
    let region = regionWithGeotification(geotification)
    locationManager.startMonitoringForRegion(region)
  }
  
  func stopMonitoringGeotification(geotification: Geotification) {
    for region in locationManager.monitoredRegions {
      if let circularRegion = region as? CLCircularRegion {
        if circularRegion.identifier == geotification.identifier {
          locationManager.stopMonitoringForRegion(circularRegion)
        }
      }
    }
  }
  
  func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
    println("Monitoring failed for region with identifier: \(region.identifier)")
  }
  
  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    println("Location Manager failed with the following error: \(error)")
  }

}

