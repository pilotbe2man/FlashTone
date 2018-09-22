//
//  StartVC.swift
//  FlashTone
//
//  Created by Developer on 5/21/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SwiftyStoreKit

class StartVC: UIViewController {

    @IBOutlet weak var view_play: UIView!
    @IBOutlet weak var btn_purchase: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var delay = AppInfoNetworkManager.shared.appInfo?.getCountDown() ?? 50
    
    var player: AVPlayer?
    var flag_navigation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Geri sayım başlangıcı: \(delay)")
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay), execute: {
            self.closeButton.isHidden = false
        })

        
        self.loadProductinfo()

        // Do any additional setup after loading the view.
        let playerController = AVPlayerViewController()
        let bundle = Bundle.main
        let moviePath: String? = bundle.path(forResource: "flashtunepremium", ofType: "mp4")
        let movieURL = URL(fileURLWithPath: moviePath!)
        
        self.player = AVPlayer(url: movieURL)
        playerController.player = self.player
        playerController.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        playerController.showsPlaybackControls = false
        self.addChildViewController(playerController)
        self.view_play.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        self.player?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) { _ in
            self.player?.seek(to: kCMTimeZero)
            self.player?.play()
        }
        
        self.view_play.isHidden = true
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { (timer) in
            self.view_play.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.btn_purchase.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.player?.pause()
        self.player = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func purchaseBtnClick(_ sender: Any) {
        self.updateAccountmembership()
    }
    
    @IBAction func restoreBtnClick(_ sender: Any) {
        self.purchaseRestore()
    }    
    
    func loadProductinfo()
    {
        Utills.showLoadingMessage(view: self.view, message: "")
        SwiftyStoreKit.retrieveProductsInfo([IAP_SUBSCRIPTION_ID]) { result in
            Utills.hideLoadingMessage(view: self.view)
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                
                if let appInfo = AppInfoNetworkManager.shared.appInfo {
                    if appInfo.shouldSeeThePrice() {
                        self.btn_purchase.setTitle("\(priceString) / Week", for: .normal)
                    } else {
                        self.btn_purchase.setTitle("TRY FOR FREE", for: .normal)
                        self.closeButton.isHidden = true
                    }
                } else {
                    self.btn_purchase.setTitle("\(priceString) / Week", for: .normal)
                }
                
                self.btn_purchase.isHidden = false
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                Utills.showMessage(title: "", message: "Cannot load product, try again later.", parent: self)
            }
        }
    }
    
    func goTomainTabVC()
    {
        let tabBarController = MainTabbarController()
        self.navigationController?.pushViewController(tabBarController, animated: false)
    }
    
    func completeTransaction(isRestore: Int) {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        var receiptData: NSData = NSData(contentsOf: receiptUrl!)!
        do {
            receiptData = try NSData(contentsOf: receiptUrl!, options: NSData.ReadingOptions.alwaysMapped)
        } catch {}
        
        let receipt = receiptData.base64EncodedString(options: [])
        
        AppInfoNetworkManager.shared.sendReceiptToServer(receipt: receipt, isRestore: isRestore)
        
    }
    
    func updateAccountmembership()
    {
        Utills.showLoadingMessage(view: self.view, message: "")
        let productId = IAP_SUBSCRIPTION_ID
        SwiftyStoreKit.purchaseProduct(productId, atomically: true) { result in
            print("result=\(result)")
            if case .success(let product) = result {
                // Deliver content from server, then:
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: IAP_SUBSCRITPION_SECRET)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { (result) in
                    Utills.hideLoadingMessage(view: self.view)
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate):
                            print("Product is valid until \(expiryDate.expiryDate) \(Date())")
                            let date_string = Utills.getStringFromDate(date: expiryDate.expiryDate, format: "yyyy-MM-dd HH:mm")
                            UserDefaults.standard.set(true, forKey: USER_MEMBERSIP_PREMIUM_STATUS)
                            UserDefaults.standard.set(date_string, forKey: USER_MEMBERSIP_PREMIUM_EXPIRE_DATE)
                            
                            self.completeTransaction(isRestore: 0)
                            
                            Utills.showMessageWithdelegate(title: "", message: "You have purchased product successfully.", parent: self, completionHandler: { (controller) in
                                self.navigationController?.popViewController(animated: true)
                            })
                        case .expired(let expiryDate):
                            print("Product is expired since \(expiryDate)")
                            Utills.showMessage(title: "", message: "Your purchase was expired.", parent: self)
                        case .notPurchased:
                            print("This product has never been purchased")
                            Utills.showMessage(title: "", message: "You did not purchase any product.", parent: self)
                        }
                        
                    } else {
                        // receipt verification error
                        Utills.showMessage(title: "", message: "Cannot connect to iTunes Store. Please try again.", parent: self)
                    }
                }
                
            } else {
                // purchase error
                Utills.hideLoadingMessage(view: self.view)
                Utills.showMessage(title: "", message: "Subscription verification failed.", parent: self)
            }
        }
    }

    
    func purchaseRestore()
    {
        Utills.showLoadingMessage(view: self.view, message: "")
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
                    Utills.hideLoadingMessage(view: self.view)
                    
                    Utills.hideLoadingMessage(view: self.view)
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate):
                            print("Product is valid until \(expiryDate)")
                            
                            let date_string = Utills.getStringFromDate(date: expiryDate.expiryDate, format: "yyyy-MM-dd HH:mm")
                            UserDefaults.standard.set(true, forKey: USER_MEMBERSIP_PREMIUM_STATUS)
                            UserDefaults.standard.set(date_string, forKey: USER_MEMBERSIP_PREMIUM_EXPIRE_DATE)
                            
                            self.completeTransaction(isRestore: 1)
                            
                            Utills.showMessageWithdelegate(title: "", message: "You have restored product successfully.", parent: self, completionHandler: { (controller) in
                                self.navigationController?.popViewController(animated: true)
                            })
                        case .expired(let expiryDate):
                            print("Product is expired since \(expiryDate)")
                            Utills.showMessage(title: "", message: "Your purchase was expired.", parent: self)
                        case .notPurchased:
                            print("This product has never been purchased")
                            Utills.showMessage(title: "", message: "You did not purchase any product.", parent: self)
                        }
                        
                    } else {
                        // receipt verification error
                        Utills.showMessage(title: "", message: "Subscription was failed. Please try again later", parent: self)
                    }
                }
            }
            else
            {
                Utills.hideLoadingMessage(view: self.view)
                Utills.showMessage(title: "", message: "The restore was failed. Please try again later", parent: self)
                print("Nothing to Restore")
            }
        }
    }
    
}
