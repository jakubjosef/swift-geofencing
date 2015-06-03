//
//  AddGeotificationViewController.swift
//  Geotify
//
//  Created by Ken Toh on 29.4.15.
//  Copyright (c) 2015 Jakub Josef. All rights reserved.
//

import UIKit
import MapKit

protocol AddGeotificationsViewControllerDelegate {
  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
    radius: Double, identifier: String, note: String, eventType: EventType,editInsteadOfAdd: Bool)
}

class AddGeotificationViewController: UITableViewController {

  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
  @IBOutlet var editButton: UIBarButtonItem!

  @IBOutlet weak var eventTypeSegmentedControl: UISegmentedControl!
  @IBOutlet weak var radiusTextField: UITextField!
  @IBOutlet weak var noteTextField: UITextField!
  @IBOutlet weak var editIdentifier: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  
  var viewMode: NSString = "add"
  var detailItem: Geotification?
  
  var delegate: AddGeotificationsViewControllerDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    if(viewMode == "add"){
      navigationItem.rightBarButtonItems = [addButton, zoomButton]
    }else if(viewMode=="edit"){
      navigationItem.rightBarButtonItems = [editButton]
    }else{
      NSLog("There was an error during rendering bar buttons. Cannot determine which buttons be visible")
    }
    addButton.enabled = false

    tableView.tableFooterView = UIView()
    configureView()
  }
  func configureView() {
    if(viewMode == "edit" && detailItem != nil){
      //using add geotification form for edit
      self.navigationItem.title = "Edit geotification"
      // Update the user interface for the detail item.
      if let detail: Geotification = self.detailItem {
        //set edit identifier
        editIdentifier.text=detail.identifier
        //update event type control
        if detail.eventType == EventType.OnEntry{
          self.eventTypeSegmentedControl.selectedSegmentIndex=0
        }else if detail.eventType == EventType.OnExit {
          self.eventTypeSegmentedControl.selectedSegmentIndex=1
        }else{
          NSLog("Invalid event type detected!")
        }
        //update map center
        self.mapView.setRegion(MKCoordinateRegionMake(detail.coordinate, MKCoordinateSpanMake(1, 1)), animated: false)
        //update note field
        self.noteTextField.text = detail.note
        //update radius field, we dont want to have decimal places
        let radius = detail.radius.description
        self.radiusTextField.text = radius.substringWithRange(Range<String.Index>(start: radius.startIndex, end: advance(radius.endIndex,-2)))
      }
    }
  }
  
  @IBAction func textFieldEditingChanged(sender: UITextField) {
    addButton.enabled = !radiusTextField.text.isEmpty && !noteTextField.text.isEmpty
  }

  @IBAction func onCancel(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction private func onAdd(sender: AnyObject) {
    var coordinate = mapView.centerCoordinate
    var radius = (radiusTextField.text as NSString).doubleValue
    var identifier = NSUUID().UUIDString
    var note = noteTextField.text
    var eventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? EventType.OnEntry : EventType.OnExit
    delegate!.addGeotificationViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType,editInsteadOfAdd: false)
  }

  @IBAction func onEdit(sender: AnyObject) {
    if(editIdentifier.text==""){
      NSLog("Cannot edit geotification! Edit identifier not set!")
    }else{
        var coordinate = mapView.centerCoordinate
        var radius = (radiusTextField.text as NSString).doubleValue
        var identifier = editIdentifier.text!
        var note = noteTextField.text
        var eventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? EventType.OnEntry : EventType.OnExit
        delegate!.addGeotificationViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType,editInsteadOfAdd: true)
    }
  }
  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
}
