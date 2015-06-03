//
//  AppDelegate.swift
//  Geotify
//
//  Created by Jakub Josef on 24.4.15.
//  Copyright (c) 2015 Jakub Josef. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

  var window: UIWindow?
  let locationManager = CLLocationManager()

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()

    application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil))
    UIApplication.sharedApplication().cancelAllLocalNotifications()

    return true
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  func handleRegionEvent(region: CLRegion) {
    // Show an alert if application is active
    if UIApplication.sharedApplication().applicationState == .Active {
      if let message = notefromRegionIdentifier(region.identifier) {
        if let viewController = window?.rootViewController {
          showSimpleAlertWithTitle(nil, message: message, viewController: viewController)
        }
      }
    } else {
   // Otherwise present a local notification
      var notification = UILocalNotification()
      notification.alertBody = notefromRegionIdentifier(region.identifier)
      notification.soundName = "Default";
      UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
  }

  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
    if region is CLCircularRegion {
      handleRegionEvent(region)
    }
  }

  func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
    if region is CLCircularRegion {
      handleRegionEvent(region)
    }
  }

  func notefromRegionIdentifier(identifier: String) -> String? {
    if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
      for savedItem in savedItems {
        if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
          if geotification.identifier == identifier {
            return geotification.note
          }
        }
      }
    }
    return nil
  }

}

