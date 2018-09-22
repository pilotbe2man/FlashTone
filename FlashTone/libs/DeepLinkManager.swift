//
//  DeepLinkManager.swift
//  Deep Link
//
//  Created by Hakan Koluaçık on 16.01.2018.
//  Copyright © 2018 Hakan Koluaçık. All rights reserved.
//

import UIKit
import SSKeychain
import Alamofire

let Deeplinker = DeepLinkManager()

class DeepLinkManager {
    
    private var deepLink: DeepLink?
    
    fileprivate init() {}
    
    // check existing deeplink and perform action
    func checkDeepLink() {
        guard let deepLink = deepLink else {
            //if there is no deeplink then only get the appinfo
            AppInfoNetworkManager.shared.sendRequestToServer()
            return
        }
        
        // if there is a deeplink then attach it to the class and send
        AppInfoNetworkManager.shared.deepLink = deepLink
        AppInfoNetworkManager.shared.sendRequestToServer()
        // reset deeplink after handling
        self.deepLink = nil
    }
    
    func handleDeeplink(url : URL) -> Bool {
        deepLink = DeepLinkParser.shared.parseDeeplink(url)
        return deepLink != nil
    }
}


// Deeplink Parser
class DeepLinkParser {
    
    static let shared = DeepLinkParser()
    
    private init() {}
    
    func parseDeeplink(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        if let queryItems = components.queryItems {
            var dict = [String: String]()
            for queryItem in queryItems {
                if queryItem.value == nil {
                    continue
                }
                
                if queryItem.name == "al_applink_data" {
                    continue
                }
                
                dict[queryItem.name] = queryItem.value
            }
            
            let host = components.host
            
            return DeepLink(queryString: dict, host: host)
        }
        
        return nil
    }
}

struct DeepLink {
    var queryString: [String: String]
    var host: String?
}

class AppInfoNetworkManager {
    
    let serverUrl = "http://payment.monodijital.com/v1/project/info"
    let paymentUrl = "http://payment.monodijital.com/v1/receipt/save"
    let accessToken = "$2a$09$TitVq/FY3ud5dXBXI74STOHnMYk9EG1QV6AL.PSeo.pSxyLZAqNfW"
    let bundleId = Bundle.main.bundleIdentifier!
    
    var deepLink: DeepLink?
    
    var appInfo: AppInfo?
    
    static let shared = AppInfoNetworkManager()
    
    private init() {}
    
    // Send request
    func sendRequestToServer() {
        // prepare json data
        
        var postData = "bundle_identifier=\(bundleId)"
        
        if let deepLink = deepLink {
            let jsonData = try? JSONSerialization.data(withJSONObject: deepLink.queryString, options: [])
            let decoded = String(data: jsonData!, encoding: .utf8)
            postData += "&deep_link_params=\(decoded!)"
        }
        
        if let userId = appInfo?.userId {
            postData += "&user_id=\(userId)"
        }
        
        if appInfo?.userId != nil || deepLink != nil {
            print("userId veya deepLink nil değil o zaman uuid'yi post verisine ekle")
            postData += "&uuid=\(getUniqueDeviceIdentifierAsString())"
        }
        
        print("GÖNDERİLEN POST VERİSİ: \(postData)")
        
        // create post request
        let url = URL(string: serverUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(accessToken, forHTTPHeaderField: "AccessToken")
        request.addValue("application/x-www-form-urlencoded",forHTTPHeaderField: "Content-Type")
        
        // insert json data to the request
        request.httpBody = postData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                self.parseResponse(responseJSON)
            }
        }
        
        task.resume()
    }
    
    //Parse the response and create AppInfo instance
    func parseResponse(_ responseJSON: [String: Any]){
        if let status = responseJSON["status"] as? Int, let result = responseJSON["result"] as? [String: Any], status == 200 {
            print("Status 200 döndü herşey yolunda")
            if let bundleId = result["bundle_identifier"] as? String,
                let accessKey = result["access_key"] as? String,
                let commentSetting = result["comment_setting"] as? String,
                let priceSetting = result["price_setting"] as? String {
                
                if let priceSetting = SettingType(rawValue: priceSetting), let commentSetting = SettingType(rawValue: commentSetting) {
                    if let extraInfoArr = result["extra_info"] as? [[String: Any]], let countDownInfo = extraInfoArr[0] as? [String: String] {
                        if let countDown = countDownInfo["value"] as? String {
                            self.appInfo = AppInfo(bundleId: bundleId, accessKey: accessKey, priceSetting: priceSetting, commentSetting: commentSetting, countDownStr: countDown)

                        } else {
                            self.appInfo = AppInfo(bundleId: bundleId, accessKey: accessKey, priceSetting: priceSetting, commentSetting: commentSetting)
                        }
                    }
                } else {
                    self.appInfo = AppInfo(bundleId: bundleId, accessKey: accessKey)
                }
                if self.deepLink != nil {
                    print("kullanıcı reklamdan geldi")
                    self.appInfo?.cameFromAds = true
                } else {
                    print("kullanıcı reklamdan gelmedi")
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "appInfoHasBeenSet"), object: nil)

            } else {
                print("json parse edilirken bir problem meydana geldi")
            }
        } else {
            print("status 200 dönmedi: ")
            print(responseJSON)
        }
    }
    
    func getUniqueDeviceIdentifierAsString() -> String {
        let appName: String? = (Bundle.main.infoDictionary?[(kCFBundleNameKey as String?)!] as? String)
        var strApplicationUUID:String = ""
        if let strApplicationUUID: String = SSKeychain.password(forService: appName!, account: "incoding") {
            return strApplicationUUID
        } else {
            strApplicationUUID = (UIDevice.current.identifierForVendor?.uuidString)!
            SSKeychain.setPassword(strApplicationUUID, forService: appName!, account: "incoding")
            return strApplicationUUID
        }
    }
    
    func sendReceiptToServer(receipt: String, isRestore: Int) {
        if appInfo != nil {
            // create post request
            let url = URL(string: paymentUrl)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(appInfo!.accessKey,forHTTPHeaderField: "ProjectToken")
            request.addValue("application/json",forHTTPHeaderField: "Content-Type")
            
            let fields: [String: Any] = [
                "receipt": receipt,
                "country": Locale.current.regionCode ?? "UNK",
                "user_id": appInfo!.userId ?? self.getUniqueDeviceIdentifierAsString(),
                "is_restore": isRestore]
            
            // insert json data to the request
            let jsonData = try? JSONSerialization.data(withJSONObject: fields)
            
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    if let status = responseJSON["status"] as? Int, status == 200 {
                        print("Status 200 döndü fatura başarıyla gönderildi: ")
                        print(responseJSON)
                    } else {
                        print("status 200 dönmedi: ")
                        print(responseJSON)
                    }
                }
                
            }
            
            task.resume()
        } else {
            print("Fatura gönderilemedi. appInfo değeri nil")
        }
        
    }
}

class AppInfo {
    var priceSetting: SettingType
    var commentSetting: SettingType
    var countDownStr: String
    var bundleId: String
    var accessKey: String
    var userId: String? {
        get {
            if let userId = UserDefaults.standard.object(forKey: "userId") as? String {
                return userId
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userId")
            if cameFromAds {
                Deeplinker.checkDeepLink()
            }
        }
    }
    
    var userDidSeeTheCommentScreen: Bool {
        get {
            if let userDidSeeTheCommentScreen = UserDefaults.standard.object(forKey: "userDidSeeTheCommentScreen") as? Bool {
                return userDidSeeTheCommentScreen
            }
            return false
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "userDidSeeTheCommentScreen")
        }
    }
    
    var cameFromAds: Bool {
        get {
            if let cameFromAds = UserDefaults.standard.object(forKey: "cameFromAds") as? Bool {
                return cameFromAds
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "cameFromAds")
        }
    }
    
    init(bundleId: String, accessKey: String, priceSetting: SettingType = .ad_only, commentSetting: SettingType = .never, countDownStr: String = "50") {
        self.bundleId = bundleId
        self.accessKey = accessKey
        self.priceSetting = priceSetting
        self.commentSetting = commentSetting
        self.countDownStr = countDownStr
    }
    
    func shouldSeeThePrice() -> Bool {
        switch priceSetting {
        case .all:
            return false
        case .ad_only:
            return !cameFromAds
        case .never:
            return true
        }
    }
    
    func getCountDown() -> Int {
        if let countDown = Int(countDownStr) {
            return countDown
        }
        return 15
    }
    
    func shouldSeeTheCommentScreen() -> Bool {
        return cameFromAds && !userDidSeeTheCommentScreen && commentSetting == .ad_only ? true : false
    }
}

enum SettingType: String {
    case ad_only
    case all
    case never
}

