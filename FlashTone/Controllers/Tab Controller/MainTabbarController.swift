//
//  MainTabbarController.swift
//  FlashTone
//
//  Created by Developer on 5/20/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import ESTabBarController_swift

class MainTabbarController: ESTabBarController {

    let storyboard_main = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let v1 = storyboard_main.instantiateViewController(withIdentifier: "TabHomeVC")
        let v2 = storyboard_main.instantiateViewController(withIdentifier: "TabCategoriesVC")
        let v3 = storyboard_main.instantiateViewController(withIdentifier: "TabPopularVC")
        let v4 = storyboard_main.instantiateViewController(withIdentifier: "TabDownloadVC")
        
        v1.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "", image: UIImage(named: "tabbar_home"), selectedImage: UIImage(named: "tabbar_home_hightlight"))
        v2.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "", image: UIImage(named: "tabbar_category"), selectedImage: UIImage(named: "tabbar_category_hightlight"))
        v3.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "", image: UIImage(named: "tabbar_popular"), selectedImage: UIImage(named: "tabbar_popular_hightlight"))
        v4.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "", image: #imageLiteral(resourceName: "tabbar_download"), selectedImage: #imageLiteral(resourceName: "tabbar_download_hightlight"))
      
        self.viewControllers = [v1, v2, v3, v4]
        self.tabBar.backgroundImage = UIImage(named: "background_dark")
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

}
