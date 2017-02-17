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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        
//        if #available(iOS 10.0, *) {
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//            
//            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self
//            // For iOS 10 data message (sent via FCM)
//            FIRMessaging.messaging().remoteMessageDelegate = self
//            
//        } else {
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            application.registerUserNotificationSettings(settings)
//        }
//        
//        application.registerForRemoteNotifications()
        
        FIRApp.configure()
        
        self.loginAnon()
        
        
        
        // Add observer for InstanceID token refresh callback.
//        NotificationCenter.default.addObserver(self,
//                                                         selector: #selector(self.tokenRefreshNotification),
//                                                         name: NSNotification.Name.firInstanceIDTokenRefresh,
//                                                         object: nil)
        
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
    }

//    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
//        
//        
////        FIRInstanceID.instanceID().setAPNSToken(deviceToken as Data, type: FIRInstanceIDAPNSTokenType.unknown)
//        
//
//        
//    }
    
//    // [START receive_message]
//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
//                     fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
//
//    }
//    // [END receive_message]
//    
//
//    func tokenRefreshNotification(_ notification: Notification) {
//        if let refreshedToken = FIRInstanceID.instanceID().token() {
//            print("InstanceID token: \(refreshedToken)")
//        }
//        
//        // Connect to FCM since connection may have failed when attempted before having a token.
//        connectToFcm()
//    }
//    
//    // [START connect_to_fcm]
//    func connectToFcm() {
//        FIRMessaging.messaging().connect { (error) in
//            if (error != nil) {
//                print("Unable to connect with FCM. \(error)")
//            } else {
//                print("Connected to FCM.")
//            }
//        }
//    }
//    // [END connect_to_fcm]
    
    func loginAnon(){
        
        let defaults = UserDefaults.standard
        var name = defaults.string(forKey: "displayName")
        
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
            
            self.window?.rootViewController = viewController
                
            
        }
    
    }

}

//// [START ios_10_message_handling]
//@available(iOS 10, *)
//extension AppDelegate : UNUserNotificationCenterDelegate {
//    
//    // Receive displayed notifications for iOS 10 devices.
//    func userNotificationCenter(center: UNUserNotificationCenter,
//                                willPresentNotification notification: UNNotification,
//                                withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
//        
//        let userInfo = notification.request.content.userInfo
//        // Print message ID.
//        print("Message ID: \(userInfo["gcm.message_id"]!)")
//        // Print full message.
//        print("%@", userInfo)
//    }
//}
//
//extension AppDelegate : FIRMessagingDelegate {
//    // Receive data message on iOS 10 devices.
//    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
//        print("%@", remoteMessage.appData)
//    }
//}
//// [END ios_10_message_handling]



