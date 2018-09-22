//
//  NetworkManager.swift
//  FlashTone
//
//  Created by Developer on 6/1/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import Foundation
import Alamofire
import SystemConfiguration

class NetworkManager: NSObject {
    
    class var sharedInstance: NetworkManager {
        
        struct Singleton {
            static let instance = NetworkManager()
        }
        return Singleton.instance
    }
    
    override init() {
        
    }
    
    
    func getRequest(url:String, paramameters: [String: AnyObject]?, completionHandler: @escaping (AnyObject?, Error?) -> Void) {
        
        Alamofire.request(url, method: .get, parameters: paramameters, encoding: JSONEncoding.default, headers: nil)
            .responseJSON { response in
                
                switch response.result {
                case .success(let data):
                    completionHandler(data as AnyObject?, nil)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completionHandler(nil, error)
                }
        }
    }
    
    func postRequest(url:String, paramameters: [String: AnyObject]?, completionHandler: @escaping (AnyObject?, Error?) -> Void) {
        var header_params: [String: String]? = nil
        if let header = UserDefaults.standard.object(forKey: "user_token") as? String
        {
            header_params = ["Authorization": header]
        }
        
        Alamofire.request(url, method: .post, parameters: paramameters, encoding: URLEncoding.default, headers: header_params ).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                completionHandler(data as AnyObject?, nil)
            case .failure(let error):
                print("Request failed with error: \(error)")
                completionHandler(nil, error)
            }
        }
        
    }
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
}

