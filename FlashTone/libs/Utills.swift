//
//  Utills.swift
//  FlashTone
//
//  Created by Developer on 6/1/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import Foundation
import MBProgressHUD
import CoreData

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIDevice {
    var iPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
    var iPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    enum ScreenType: String {
        case iPhone4 = "iPhone 4 or iPhone 4S"
        case iPhones_5_5s_5c_SE = "iPhone 5, iPhone 5s, iPhone 5c or iPhone SE"
        case iPhones_6_6s_7_8 = "iPhone 6, iPhone 6S, iPhone 7 or iPhone 8"
        case iPhones_6Plus_6sPlus_7Plus_8Plus = "iPhone 6 Plus, iPhone 6S Plus, iPhone 7 Plus or iPhone 8 Plus"
        case iPhoneX = "iPhone X"
        case unknown
    }
    var screenType: ScreenType {
        switch UIScreen.main.nativeBounds.height {
        case 960:
            return .iPhone4
        case 1136:
            return .iPhones_5_5s_5c_SE
        case 1334:
            return .iPhones_6_6s_7_8
        case 1920, 2208:
            return .iPhones_6Plus_6sPlus_7Plus_8Plus
        case 2436:
            return .iPhoneX
        default:
            return .unknown
        }
    }
}

extension String {
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedStringKey.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
    
    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedStringKey.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

class Utills: NSObject {
    
    class func showMessage(title: String, message: String, parent: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (alertController) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }))
        defer {
            DispatchQueue.main.async{
                parent.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    class func showMessageWithdelegate(title: String, message: String, parent: UIViewController,  completionHandler: @escaping (AnyObject?) -> Void)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (alertController) -> Void in
            completionHandler(alertController)
        }))
        defer {
            DispatchQueue.main.async{
                parent.present(alert, animated: true, completion: nil)
            }
        }
    }    
    
    class func showLoadingMessage(view: UIView, message: String){
        let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.contentColor = UIColor.purple
        loadingNotification.bezelView.color = UIColor.clear
        loadingNotification.labelText = message
    }
    
    class func hideLoadingMessage(view: UIView){
        MBProgressHUD.hideAllHUDs(for: view, animated: true)
    }
   
    class func userMembershipCheck()  -> String      // return user membership status after checking membership
    {
        //        return RETURN_USER_MEMBERSIP_PREMIUM
        if UserDefaults.standard.bool(forKey: USER_MEMBERSIP_PREMIUM_STATUS)
        {
            if let expire_date_string = UserDefaults.standard.object(forKey: USER_MEMBERSIP_PREMIUM_EXPIRE_DATE) as? String
            {
                let expire_date = Utills.getDatefromString(strdate: expire_date_string, format: "yyyy-MM-dd HH:mm")
                let current_date = Date()
                if current_date > expire_date
                {
                    return RETURN_USER_MEMBERSIP_EXPIRE
                }
                else{
                    return RETURN_USER_MEMBERSIP_PREMIUM
                }
            }
            return RETURN_USER_MEMBERSIP_NO
        }
        else{
            return RETURN_USER_MEMBERSIP_NO
        }
    }
    
    class func getStringFromDate(date: Date, format: String) -> String         // convert date to string
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let stringdate = dateFormatter.string(from: date)
        return stringdate
    }
    
    class func getDatefromString(strdate: String, format: String) -> Date      // convert string to date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if dateFormatter.date(from: strdate) != nil {
            let datevalue = dateFormatter.date(from: strdate)
            return datevalue!
        } else {
            // invalid format
            return Date()
        }
    }
    
    class func getAudioplaybgIcon(_ id: Int)-> UIImage
    {
        var img: UIImage?
        switch id {
        case 4:
            img = #imageLiteral(resourceName: "btn_audio_bg_pink")
            break
        case 5:
            img = #imageLiteral(resourceName: "btn_audio_bg_yellow")
            break
        case 6:
            img = #imageLiteral(resourceName: "btn_audio_bg_lightRed")
            break
        case 7:
            img = #imageLiteral(resourceName: "btn_audio_bg_turquoise")
            break
        case 8:
            img = #imageLiteral(resourceName: "btn_audio_bg_blue")
            break
        case 9:
            img = #imageLiteral(resourceName: "btn_audio_bg_deepPurple")
            break
        case 10:
            img = #imageLiteral(resourceName: "btn_audio_bg_gray")
            break
        case 11:
            img = #imageLiteral(resourceName: "btn_audio_bg_purple")
            break
        case 12:
            img = #imageLiteral(resourceName: "btn_audio_bg_red")
            break
        case 13:
            img = #imageLiteral(resourceName: "btn_audio_bg_green")
            break
        default:
            img = #imageLiteral(resourceName: "btn_audio_bg_red")
        }
        
        return img!
    }
    
    class func ringtoneUpdate(_ songID: String, view: UIView)
    {
        Utills.showLoadingMessage(view: view, message: "")
        let typevalue = "UPDATE_RINGTONES"
        let params = ["type": typevalue,
            "songid"   :  songID] as [String : AnyObject]
        
        NetworkManager.sharedInstance.postRequest(url: URL_API_SERVER, paramameters: params) { (result, error) in
            Utills.hideLoadingMessage(view: view)
        }
    }
    
    
    class func saveDownloadringtoneFunc(_ songDict : NSDictionary)
    {
        let insert_ringtoneID = String(describing: songDict["id"] as! String)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        
        // check existing download data
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Downloads")
        fetchRequest.predicate = NSPredicate(format: "id_ringtone = \(insert_ringtoneID)", argumentArray: nil)
        
        let res = try! managedObjectContext.fetch(fetchRequest)
        if(res.count > 0)
        {
            print("error - exist")
            return
        }
        else
        {
            print("success - new add")
            // Using the Managed Object Context, lets create a new entry into entity "Downloads".
            let object = NSEntityDescription.insertNewObject(forEntityName: "Downloads", into: managedObjectContext) as! Downloads
            
            object.category = String(describing: songDict["category_name"] as! String)
            object.category_id = String(describing: songDict["category_id"] as! String)
            object.type = String(describing: songDict["type_name"] as! String)
            object.p_song = String(describing: songDict["p_song"] as! String)
            object.title = String(describing: songDict["title"] as! String)
            object.duration = String(describing: songDict["duration"] as! String)
            object.id_ringtone = insert_ringtoneID
            
            do {
                // Then we try to persist the new entry.
                try managedObjectContext.save()
            } catch {
                
            }
        }
    }
}
