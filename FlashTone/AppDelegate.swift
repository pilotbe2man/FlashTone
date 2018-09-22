//
//  AppDelegate.swift
//  FlashTone
//
//  Created by Developer on 5/18/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import CoreData
import SwiftyStoreKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.statusBarStyle = .lightContent
        
        FBSDKAppLinkUtility.fetchDeferredAppLink { (url, error) in
            if let error = error {
                print("Received error while fetching deferred app link: \(error)")
            }
            if let url = url {
                print("facebooktan Deeplink geldi")
                self.application(application, open: url)
                Deeplinker.checkDeepLink()
            }
        }
        
        let tabBarController = MainTabbarController()
        let navigationController = UINavigationController(rootViewController: tabBarController)
        navigationController.isNavigationBarHidden = true
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        setupIAP()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        print("handle deep link çağırıldı")
        return Deeplinker.handleDeeplink(url: url)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        print("check deeplink çağırıldı, bu aşamada göndermesi gerek")
        Deeplinker.checkDeepLink()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
         self.saveContext()
    }
    
    func purchaseRestore()
    {
        SwiftyStoreKit.restorePurchases { (results) in
            
            if results.restoreFailedPurchases.count > 0
            {
                print("Restore faild: \(results.restoreFailedPurchases)")
            }
            else if results.restoredPurchases.count > 0
            {
                print("Restore Success: \(results.restoredPurchases)")
                let product_result = results.restoredPurchases[0]
                let productId = product_result.productId
                
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: IAP_SUBSCRITPION_SECRET)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { (result) in
                   
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate):
                            print("Product is valid until \(expiryDate)")
                            
                            let date_string = Utills.getStringFromDate(date: expiryDate.expiryDate, format: "yyyy-MM-dd HH:mm")
                            UserDefaults.standard.set(true, forKey: USER_MEMBERSIP_PREMIUM_STATUS)
                            UserDefaults.standard.set(date_string, forKey: USER_MEMBERSIP_PREMIUM_EXPIRE_DATE)
                            UserDefaults.standard.synchronize()
                         
                        case .expired(let expiryDate):
                            print("Product is expired since \(expiryDate)")
                        //                            Utills.showMessage(title: "", message: "Your purchase was expired.", parent: self)
                        case .notPurchased:
                            print("This product has never been purchased")
                            //                            Utills.showMessage(title: "", message: "You did not purchase any product.", parent: self)
                        }                        
                    }
                }
            }
            else
            {
                print("Nothing to Restore")
            }
        }
    }   
    
    func setupIAP() {
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    let downloads = purchase.transaction.downloads
                    if !downloads.isEmpty {
                        SwiftyStoreKit.start(downloads)
                    } else if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
            print("setupIAP girdi")
            self.purchaseRestore()
        }
        
        SwiftyStoreKit.updatedDownloadsHandler = { downloads in
            
            // contentURL is not nil if downloadState == .finished
            let contentURLs = downloads.flatMap { $0.contentURL }
            if contentURLs.count == downloads.count {
                print("Saving: \(contentURLs)")
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
    }
    

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "downloads")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

