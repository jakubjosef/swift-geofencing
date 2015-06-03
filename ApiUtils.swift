//
//  ApiUtils.swift
//  Geotify
//
//  Created by JaKoB on 22.05.15.
//  Copyright (c) 2015 Jakub Josef. All rights reserved.
//

import Foundation
import CoreLocation

struct ApiUtils{
  // ENABLE OR DISABLE LOGGING POST REQUESTS
  static var kLogging=true
  
  //API URLS
  static var kApiBaseURL = "http://pavelbartos.vserver.cz/geofencing/"
  static var kApiLoginURL = kApiBaseURL + "login.php"
  static var kApiGeotificationsStoreURL = kApiBaseURL + "geotifications.php"
  static func doLogin(username:NSString,password:NSString) -> (response:NSHTTPURLResponse,jsonData:NSDictionary?){
    var (response,jsonData,requestError, responseError,jsonError) = ApiUtils.makePOST(kApiLoginURL, data: ["username": username, "password": password])
    return (response,jsonData)
  }
  
  static func storeGeotification(geotification:Geotification,sessionID:NSString){
    var (response, jsonData, requestError, responseError,jsonError) = self.makePOST(kApiGeotificationsStoreURL, data: ["action": "store", "sessionID":sessionID,"geotification":geotification.serialize()])
    if let data = jsonData{
      if let result = data.valueForKey("result") as? String{
        if(result != "ok"){
          NSLog("Cannot store geotification, server not returns result:ok")
        }
      }
    }else{
      NSLog("Cannot store geotification, server returns nothing")
    }
    //otherwise store is success
    if(kLogging){
      NSLog("Geotification \(geotification.note) stored")
    }
  }
  static func editGeotification(geotification:Geotification,sessionID:NSString){
    var (response, jsonData, requestError, responseError,jsonError) = self.makePOST(kApiGeotificationsStoreURL, data: ["action": "edit", "sessionID":sessionID,"geotification":geotification.serialize()])
    if let data = jsonData{
      if let result = data.valueForKey("result") as? String{
        if(result != "ok"){
          NSLog("Cannot edit geotification, server not returns result:ok")
        }
      }
    }else{
      NSLog("Cannot edit geotification, server returns nothing")
    }
    //otherwise store is success
    if(kLogging){
      NSLog("Geotification \(geotification.note) edited")
    }
  }
  static func deleteGeotification(geotification:Geotification,sessionID:NSString){
    var (response, jsonData, requestError, responseError,jsonError) = self.makePOST(kApiGeotificationsStoreURL, data: ["action": "delete", "sessionID":sessionID,"geotification":geotification.serialize()])
    if let data = jsonData{
      if let result = data.valueForKey("result") as? String{
        if(result != "ok"){
          NSLog("Cannot delete geotification, server not returns result:ok")
        }
      }
    }else{
      NSLog("Cannot delete geotification, server returns nothing")
    }
    //otherwise store is success
    if(kLogging){
      NSLog("Geotification \(geotification.note) deleted")
    }
  }
  static func makePOST(url:String, data: NSDictionary) -> (response:NSHTTPURLResponse,jsonData: NSDictionary?, requestError:NSError?, responseError: NSError?,jsonError: NSError?){
  
    var requestError: NSError?
    var postData:NSData = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &requestError)!
    if(requestError != nil){
      NSLog("Request error: " + requestError!.description)
    }
    if(kLogging){
      NSLog("Making POST request to \(url)")
      NSLog("PostData: %@",NSString(data: postData, encoding: NSUTF8StringEncoding)!)
    }
    
    var postLength:NSString = String( postData.length )
    
    var request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string:url)!)
    request.HTTPMethod = "POST"
    request.HTTPBody = postData
    request.setValue(postLength as String, forHTTPHeaderField: "Content-Length")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    var responseError: NSError?
    var response: NSURLResponse?
    var data:NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&responseError)
    var res = response as! NSHTTPURLResponse!
    var jsonData:NSDictionary?
    var jsonError:NSError?
    if(kLogging){
      if(res != nil){
        NSLog("Response code %ld",res.statusCode)
      }else{
        NSLog("")
      }
    }
    if(data != nil){
      var responseData:NSString  = NSString(data:data!, encoding:NSUTF8StringEncoding)!
      if(kLogging){
        NSLog("Response ==> %@", responseData);
      }
      jsonData = NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers , error: &jsonError) as? NSDictionary
      
    }else{
      NSLog("Cannot process POST request, returned data is nil!")
    }
    if(responseError != nil){
      NSLog("Response error: " + responseError!.description)
    }
    if(jsonError != nil){
      NSLog("JSON error: " + jsonError!.description)
    }
    return (res,jsonData,requestError, responseError, jsonError)
  }
  
  // COMMON FUNCTIONS
   static func getGeotificationsArrayFromJSONData(jsonData: NSArray) -> NSMutableArray {
    var returnItems = NSMutableArray()
    for jsonObject in jsonData{
      if let jsonDict = jsonObject as? NSDictionary{
        //create coordinate object
        let coordinate = CLLocationCoordinate2D(latitude: jsonDict["latitude"] as! Double, longitude:  jsonDict["longitude"] as! Double)
        //create EventType
        let eventType:EventType
        if(jsonDict["eventType"] as! NSInteger == 0){
          eventType=EventType.OnEntry
        }else{
          eventType=EventType.OnExit
        }
        let geotification = Geotification(coordinate: coordinate, radius: jsonDict["radius"] as! Double, identifier: jsonDict["identifier"] as! String, note: jsonDict["note"] as! String, eventType: eventType)
        
        //convert and add to return array
        returnItems.addObject(NSKeyedArchiver.archivedDataWithRootObject(geotification))
      }
    }
    return returnItems
  }
}
