//
//  AppDelegate.swift
//  Hyphenate Messenger
//
//  Created by peng wan on 9/29/16.
//  Copyright © 2016 Hyphenate Inc. All rights reserved.
//

import UIKit
import CoreData
import HyphenateFullSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /** Hyphenate configuration constants **/
    static let kHyphenateAppKey = "hyphenatedemo#hyphenateswift"
    static let kHyphenatePushServiceDevelopment = "DevelopmentCertificate"
    static let kHyphenatePushServiceProduction = "ProductionCertificate"
    static let kSDKConfigEnableConsoleLogger = "SDKConfigEnableConsoleLogger"
    
    /** Google Analytics configuration constants **/
    static let kGaPropertyId = "updateKey"
    static let kTrackingPreferenceKey = "allowTracking"
    static let kGaDryRun = false
    static let kGaDispatchPeriod = 30

    var window: UIWindow?
    var mainViewController: MainViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var apnsCertName : String? = nil
        #if DEBUG
            apnsCertName = AppDelegate.kHyphenatePushServiceDevelopment
        #else
            apnsCertName = AppDelegate.kHyphenatePushServiceProduction
        #endif
        
        let pushSettings = UIUserNotificationSettings(types:[UIUserNotificationType.badge ,UIUserNotificationType.sound ,UIUserNotificationType.alert], categories: nil)
        application.registerUserNotificationSettings(pushSettings)
        application.registerForRemoteNotifications()
        UINavigationBar.appearance().tintColor = UIColor(red: 71.0/255, green: 201/255.0, blue: 5.0/255, alpha: 1)
        UINavigationBar.appearance().backgroundColor = UIColor(red: 250.0/255, green: 251.0/255, blue: 252.0/255, alpha: 1)
        UINavigationBar.appearance().clipsToBounds = false
        UINavigationBar.appearance().isTranslucent = true

        hyphenateApplication(application, didFinishLaunchingWithOptions: launchOptions, appKey: AppDelegate.kHyphenateAppKey, apnsCertname: apnsCertName!, otherConfig:[AppDelegate.kSDKConfigEnableConsoleLogger: NSNumber(booleanLiteral: true)])

        if EMClient.shared().isAutoLogin {
            proceedLogin()
        } else {
            proceedLogout()
            EMClient.shared().options.isAutoLogin = true
        }
        
        HyphenateMessengerHelper.sharedInstance.loadConversationFromDB()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        EMClient.shared().applicationDidEnterBackground(application)

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        EMClient.shared().applicationWillEnterForeground(application)

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "io.hyphenate.messenger.Hyphenate_Messenger" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Hyphenate_Messenger", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
   
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        EMClient.shared().registerForRemoteNotifications(withDeviceToken: deviceToken) { (error) in
            if ((error) != nil) {
                print("Error!!! Failed to register remote notification - \(error?.description)")
            }
        }
    }
}

extension AppDelegate {
    
    func hyphenateApplication(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any]?, appKey: String, apnsCertname: String, otherConfig: Dictionary<String, AnyObject>)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KNotification_login"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KNotification_logout"), object: nil)
        
        let options: EMOptions = EMOptions(appkey: appKey)
        options.apnsCertName = apnsCertname
        options.enableDnsConfig = true
        let error:EMError? = EMClient.shared().initializeSDK(with: options)
        
        if ((error) != nil) {
            print("womg")
        }
        
        registerMessagingNotification()
        
        //        let isAutoLogin = EMClient.shared().isAutoLogin
        //        if isAutoLogin {
        //            proceedLogin()
        //        } else {
        //            proceedLogout()
        //            EMClient.shared().options.isAutoLogin = true
        //        }
    }
    
    // login
    func proceedLogin() {
        
        if (self.mainViewController == nil) {
            self.mainViewController = MainViewController()
        }
        
        HyphenateMessengerHelper.sharedInstance.mainVC = mainViewController
        HyphenateMessengerHelper.sharedInstance.loadConversationFromDB()
        HyphenateMessengerHelper.sharedInstance.loadPushOptions()
        HyphenateMessengerHelper.sharedInstance.loadGroupFromServer()
        window?.rootViewController = self.mainViewController
    }
    
    //logout
    func proceedLogout() {
        if EMClient.shared().isLoggedIn {
            HyphenateMessengerHelper.sharedInstance.logout()
        } else {
            proceedLoginViewController()
        }
    }
    
    func proceedLoginViewController() {
        if ((mainViewController) != nil) {
            let _ = mainViewController?.navigationController?.popToRootViewController(animated: false)
        }
        
        self.mainViewController = nil;
        
        HyphenateMessengerHelper.sharedInstance.mainVC = nil
        let loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginScene")
        window?.rootViewController = loginController
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error!!! Failed to register remote notification - \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        do {
            
            let jsonData : Data = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            let str : String = String(data: jsonData, encoding: String.Encoding.utf8)!
            let alert = UIAlertController(title: NSLocalizedString("apns.content", comment: ""), message: str, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "ok"), style: .cancel, handler: nil))
            alert.show((window?.rootViewController)!, sender: self)
            
        } catch let parseError as NSError {
            print(parseError.localizedDescription)
        }
        
    }
    
    func registerMessagingNotification() {
        
        //        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        //        UIApplication.shared.registerUserNotificationSettings(settings)
        //        UIApplication.shared.registerForRemoteNotifications()
        
        
        
        
        //        let application : UIApplication = UIApplication.shared;
        //        application.applicationIconBadgeNumber = 0;
        //
        //#if !TARGET_IPHONE_SIMULATOR
        //
        //        if(application.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:)))) {
        //            let notificationTypes: UIUserNotificationType = [.badge, .alert, .sound]
        //            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        //            application.registerUserNotificationSettings(settings)
        //        } else {
        //            let notificationTypes: UIRemoteNotificationType = [.badge, .sound, .alert]
        //            UIApplication.shared.registerForRemoteNotifications(matching: notificationTypes)
        //        }
        //#endif
        
        /*XCode 8 issue, can not compile
         #if !TARGET_IPHONE_SIMULATOR
         
         if(application.responds(to: #selector(self.registerForRemoteNotifications))) {
         application.registerForRemoteNotifications()
         } else {
         let notificationTypes: UIRemoteNotificationType = [.badge, .sound, .alert]
         UIApplication.shared.registerForRemoteNotifications(matching: notificationTypes)
         }
         #endif
         
         */
    }
    
}

