//
//  TabCategoriesVC.swift
//  FlashTone
//
//  Created by Developer on 5/20/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import SwiftyJSON
import ImageLoader

class TabCategoriesVC: UIViewController {
    
    var array_categories: NSMutableArray = []
    @IBOutlet weak var collection_category: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nibCell = UINib(nibName: "CategoryCell", bundle: nil)
        self.collection_category.register(nibCell, forCellWithReuseIdentifier: "CategoryCell")
        // Do any additional setup after loading the view.
        
         self.categoresLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.categoresLoad()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.array_categories.removeAllObjects()
//        self.collection_category.reloadData()
//    }
    
    func categoresLoad()
    {
        Utills.showLoadingMessage(view: self.view, message: "")
        let typevalue = "CATEGORIES"
        let params = ["type"   :  typevalue] as [String : AnyObject]
        
        NetworkManager.sharedInstance.postRequest(url: URL_API_SERVER, paramameters: params) { (result, error) in
            Utills.hideLoadingMessage(view: self.view)
            if error != nil
            {
                Utills.showMessage(title: "Error", message: (error?.localizedDescription)!, parent: self)
            }
            else
            {
                if let response = result {
                    if let json = JSON(response).dictionaryObject {
                        let category_arr_json = json["response_data"] as! NSArray
                        self.array_categories = category_arr_json.mutableCopy() as! NSMutableArray
                        self.collection_category.reloadData()
                    }
                }
            }
        }
    }
}

extension TabCategoriesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets{
        return UIEdgeInsetsMake(7.5, 0, 7.5, 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell_width = UIDevice.current.screenType == .iPhones_5_5s_5c_SE ? 160 * ((UIScreen.main.bounds.width - 20) / 375) : 160 * ((UIScreen.main.bounds.width) / 375)
        let cell_height = 86 * (UIScreen.main.bounds.height / 667)
        return CGSize(width: cell_width , height: cell_height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.array_categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        cell.backgroundColor = UIColor.black
        let category_dict = self.array_categories[indexPath.row] as! NSDictionary
        cell.lbl_title.text = category_dict["category_name"] as? String
        
        let imgurl = "\(URL_BASE_SERVER)\(category_dict["category_image"] as! String)"
        cell.imgview_category.load.request(with: imgurl)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "CategoryDetailVC") as! CategoryDetailVC
        let category_dict = self.array_categories[indexPath.row] as! NSDictionary
        controller.title_category_str = category_dict["category_name"] as! String
        controller.category_id = category_dict["category_id"] as! String
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
}

