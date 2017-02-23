//
//  AppDelegate.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/13/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import SystemConfiguration

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
     var navigationController: NavigationController?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        //network connection check
        if (self.connectedToNetwork()){
            
            FIRApp.configure()
            
            self.loginAnon()
            
            
        }else{
            
            
            let alertController = UIAlertController(title: "Warning", message: "No Internet Connection", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(defaultAction)
            
            DispatchQueue.main.async {
                
                //SHOW INTERNET NOT AVAILABLE ALERTVIEW

                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                
            }

        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        try! FIRAuth.auth()!.signOut()
//        FIRMessaging.messaging().disconnect()
//        print("Disconnected from FCM.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        try! FIRAuth.auth()!.signOut()
    }


    
    func loginAnon(){
        
        let defaults = UserDefaults.standard
        var name = defaults.string(forKey: "displayName")
        let firstRun = defaults.string(forKey: "isFirstRun")
        
        if (firstRun == nil){
            
            defaults.set(true, forKey: "isFirstRun")
            defaults.synchronize()
        }
        
        if (name == nil){
            
            name = ""
            defaults.set(name, forKey: "displayName")
            defaults.synchronize()
            
        }
        
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            
            let isAnonymous = user!.isAnonymous  // true
            print(isAnonymous)
            
            let uid = user!.uid
            
            let viewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "startView") as! StartViewController
            
            viewController.uid = uid as NSString
            viewController.displayName = name!
            
//            self.window?.rootViewController = viewController
            
            
            self.navigationController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "navController") as? UINavigationController as! NavigationController?
            
            self.window?.rootViewController = self.navigationController
            self.navigationController?.isNavigationBarHidden = true
            self.navigationController?.pushViewController(viewController, animated: false)
            
        }
    
    }
    
    //check for internet connection, returns true if there is a connection
    func connectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }

}



