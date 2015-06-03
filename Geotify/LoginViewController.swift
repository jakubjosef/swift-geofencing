//
//  LoginViewController.swift
//  Geotify
//
//  Created by JaKoB on 04.05.15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//
import UIKit
import Foundation
import CoreLocation
class LoginViewController: UIViewController {
  
    var kSavedItemsKey = "FENCES"
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var navbar: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginClicked(sender: UIButton) {
        var username:NSString = loginField.text
        var password:NSString = passField.text
        
        if ( username.isEqualToString("") || password.isEqualToString("") ) {
          showSimpleAlertWithTitle("Sign in Failed!", message: "Please enter Username and Password", viewController: self)
        } else {
          var (res,jsonData) = ApiUtils.doLogin(username,password: password)
            if(jsonData != nil){
              if(res.statusCode >= 200 && res.statusCode < 300){
          
                let success:NSInteger = jsonData?.valueForKey("success") as! NSInteger
                NSLog("Success: %ld", success);
                
                if(success == 1)
                {
                  NSLog("Login SUCCESS");
                  //login success, save user fences
                  var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                  prefs.setObject(username, forKey: "USERNAME")
                  prefs.setInteger(1, forKey: "ISLOGGEDIN")
                  prefs.setObject(ApiUtils.getGeotificationsArrayFromJSONData(jsonData?.valueForKey("geofences") as! NSArray), forKey: kSavedItemsKey)
                  prefs.synchronize()
                  
                  self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                  //show returned error
                  var error_msg:NSString
                  
                  if jsonData?["error_message"] as? NSString != nil {
                    error_msg = jsonData?["error_message"] as! NSString
                  } else {
                    error_msg = "Unknown Error!"
                  }
                  showSimpleAlertWithTitle("Sign in failed!", message: error_msg as String, viewController: self)
                  
                }
              }else{
                showSimpleAlertWithTitle("Sign in failed!", message: "Server returns " + String(res.statusCode), viewController: self)
              }
            }
        }
    }
}
