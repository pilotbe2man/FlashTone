//
//  PremiumVC.swift
//  FlashTone
//
//  Created by Hakan Koluaçık on 13.07.2018.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SwiftyStoreKit

class PremiumVC: UIViewController {

    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var firstPurchaseButtonSubLabel: UILabel!
    @IBOutlet weak var firstPurchaseButton: UIButton!
    @IBOutlet weak var secondPurchaseButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var delay = AppInfoNetworkManager.shared.appInfo?.getCountDown() ?? 50
    var videoPlayer: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createAVPlayer()
        createGradientLayer()
        loadProductinfo()
        print("Geri sayım başlangıcı: \(delay)")
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay), execute: {
            self.closeButton.isHidden = false
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoPlayer?.pause()
        videoPlayer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadProductinfo()
    {
        Utills.showLoadingMessage(view: self.view, message: "Loading...")
        SwiftyStoreKit.retrieveProductsInfo([IAP_SUBSCRIPTION_WEEKLY, IAP_SUBSCRIPTION_YEARLY]) { result in
            Utills.hideLoadingMessage(view: self.view)
            if result.retrievedProducts.count > 0 {
                for product in result.retrievedProducts {
                    
                    
                    switch product.productIdentifier {
                    case IAP_SUBSCRIPTION_WEEKLY:
                        let priceString = product.localizedPrice!
                        self.firstPurchaseButtonSubLabel.text = "3 days free trial then \(priceString) / Week"
                    case IAP_SUBSCRIPTION_YEARLY:
                        let priceString = product.localizedPrice!
                        self.secondPurchaseButton.setTitle("\(priceString) / Yearly", for: .normal)
                    default:
                        break
                    }
                }
                
                if let appInfo = AppInfoNetworkManager.shared.appInfo {
                    if !appInfo.shouldSeeThePrice() {
                        self.firstPurchaseButtonSubLabel.isHidden = true
                        self.closeButton.isHidden = true
                    }
                }

            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                Utills.showMessage(title: "", message: "Cannot load product, try again later.", parent: self)
            }
        }
    }
    
    func handlePurchase(productId: String)
    {
        Utills.showLoadingMessage(view: self.view, message: "")
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
    
    func completeTransaction(isRestore: Int) {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        var receiptData: NSData = NSData(contentsOf: receiptUrl!)!
        do {
            receiptData = try NSData(contentsOf: receiptUrl!, options: NSData.ReadingOptions.alwaysMapped)
        } catch {}
        
        let receipt = receiptData.base64EncodedString(options: [])
        
        AppInfoNetworkManager.shared.sendReceiptToServer(receipt: receipt, isRestore: isRestore)
        
    }
    
    // MARK: Actions
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func firstPurchaseButtonPressed(_ sender: Any) {
        handlePurchase(productId: IAP_SUBSCRIPTION_WEEKLY)
    }
    
    @IBAction func secondPurchaseButtonPressed(_ sender: Any) {
        handlePurchase(productId: IAP_SUBSCRIPTION_YEARLY)
    }
    
    @IBAction func restoreButtonPressed(_ sender: Any) {
        purchaseRestore()
    }
}

//UI Customizing methods - seperated for better reading
extension PremiumVC {
    fileprivate func createGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [#colorLiteral(red: 0.07450980392, green: 0.768627451, blue: 0.9803921569, alpha: 1).cgColor, #colorLiteral(red: 0.7176470588, green: 0.1647058824, blue: 0.6509803922, alpha: 1).cgColor, #colorLiteral(red: 0.9803921569, green: 0.1450980392, blue: 0.4549019608, alpha: 1).cgColor]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        gradientLayer.frame = firstPurchaseButton.bounds
        firstPurchaseButton.layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.add(animateView(), forKey: nil)
    }
    
    func animateView() -> CABasicAnimation {
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = [0.0, 0.3, 0.6]
        gradientAnimation.toValue = [0.6, 0.9, 1.0]
        gradientAnimation.duration = 4
        gradientAnimation.autoreverses = true
        gradientAnimation.repeatCount = Float.infinity
        return gradientAnimation
    }
    
    fileprivate func createAVPlayer() {
        let videoPath = Bundle.main.path(forResource: "premium_page_video2", ofType: "mp4")
        let videoUrl = URL(fileURLWithPath: videoPath!)
        videoPlayer = AVPlayer(url: videoUrl)
        let playerController = createAVPlayerVC(with: videoPlayer!)
        //self.addChildViewController(playerController)
        playView.addSubview(playerController.view)
        playerController.view.frame = playView.frame
        videoPlayer?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem, queue: .main) { _ in
            self.videoPlayer?.seek(to: kCMTimeZero)
            self.videoPlayer?.play()
        }
        
    }
    
    fileprivate func createAVPlayerVC(with player: AVPlayer) -> AVPlayerViewController {
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = false
        playerController.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        return playerController
    }
}
