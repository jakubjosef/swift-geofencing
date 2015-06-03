//
//  GeotificationsViewController.swift
//  Geotify
//
//  Created by Jakub Josef on 24.4.15.
//  Copyright (c) 2015 Jakub Josef. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

let kTESTSESSIONID = "session123"
let kSavedItemsKey = "FENCES"

class GeotificationsViewController: UIViewController, AddGeotificationsViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {


  @IBOutlet weak var addButton: UIBarButtonItem!
  @IBOutlet weak var locButton: UIBarButtonItem!
  @IBOutlet weak var logoutButton: UIBarButtonItem!
  @IBOutlet weak var flexibleBar: UIBarButtonItem!
    
  @IBOutlet weak var mapView: MKMapView!

  var geotifications = [Geotification]()
  let locationManager = CLLocationManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItems = [addButton, locButton]
    self.toolbarItems=[flexibleBar,logoutButton]
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    loadAllGeotifications()
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addGeotificationFromMap" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }

   @IBAction func logoutClicked(sender: UIBarButtonItem) {
      let appDomain = NSBundle.mainBundle().bundleIdentifier
      NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
    
      self.performSegueWithIdentifier("goto_login", sender: self)
   }
  // MARK: Loading and saving functions

  func loadAllGeotifications() {
    geotifications = []

    if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
      for savedItem in savedItems {
        if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
          addGeotification(geotification)
        }
      }
    }
  }

  func saveAllGeotifications() {
    var items = NSMutableArray()
    for geotification in geotifications {
      let item = NSKeyedArchiver.archivedDataWithRootObject(geotification)
      items.addObject(item)
    }
    NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }

  // MARK: Functions that update the model/associated views with geotification changes

  func addGeotification(geotification: Geotification) {
    geotifications.append(geotification)
    mapView.addAnnotation(geotification)
    addRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func removeGeotification(geotification: Geotification) {
    if let indexInArray = find(geotifications, geotification) {
      geotifications.removeAtIndex(indexInArray)
    }
    ApiUtils.deleteGeotification(geotification, sessionID: kTESTSESSIONID)
    mapView.removeAnnotation(geotification)
    removeRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func updateGeotificationsCount() {
    title = "Geotifications (\(geotifications.count))"
    navigationItem.rightBarButtonItem?.enabled = (geotifications.count < 20)
  }

  // MARK: AddGeotificationViewControllerDelegate

  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType,editInsteadOfAdd: Bool = false) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius

    let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
    addGeotification(geotification)
    startMonitoringGeotification(geotification)
    ApiUtils.storeGeotification(geotification,sessionID: kTESTSESSIONID)
    saveAllGeotifications()
  }

  // MARK: MKMapViewDelegate

  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        var removeButton = UIButton.buttonWithType(.Custom) as! UIButton
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, forState: .Normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }

  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    if overlay is MKCircle {
      var circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = UIColor.purpleColor()
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
      return circleRenderer
    }
    return nil
  }

  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    // Delete geotification
    var geotification = view.annotation as! Geotification
    stopMonitoringGeotification(geotification)
    removeGeotification(geotification)
    saveAllGeotifications()
  }

  // MARK: Map overlay functions

  func addRadiusOverlayForGeotification(geotification: Geotification) {
    mapView?.addOverlay(MKCircle(centerCoordinate: geotification.coordinate, radius: geotification.radius))
  }

  func removeRadiusOverlayForGeotification(geotification: Geotification) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if let circleOverlay = overlay as? MKCircle {
          var coord = circleOverlay.coordinate
          if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
            mapView?.removeOverlay(circleOverlay)
            break
          }
        }
      }
    }
  }

  // MARK: Other mapview functions

  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }

  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .AuthorizedAlways)
  }

  func regionWithGeotification(geotification: Geotification) -> CLCircularRegion {
    // 1
    let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
    // 2
    region.notifyOnEntry = (geotification.eventType == .OnEntry)
    region.notifyOnExit = !region.notifyOnEntry
    return region
  }

  func startMonitoringGeotification(geotification: Geotification) {
    // 1
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
      return
    }
    // 2
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
    }
    // 3
    let region = regionWithGeotification(geotification)
    // 4
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
