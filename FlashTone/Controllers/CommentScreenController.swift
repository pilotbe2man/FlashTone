//
//  CommentScreenController.swift
//  Findbee
//
//  Created by Hakan Koluaçık on 5.05.2018.
//  Copyright © 2018 Hakan. All rights reserved.
//

import UIKit

class CommentScreenController: UIViewController {
    
    static var starsClicked = false
    
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var thanksLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func starsClicked(_ sender: Any) {
        openAppStore()
    }
    
    @IBAction func closeClicked(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    func openAppStore(){
        
        CommentScreenController.starsClicked = true
        
        messageLabel.isHidden = false
        thanksLabel.isHidden = false
        starButton.isHidden = true
        closeButton.isHidden = false
        
        let appID = "1405532435"
        let urlStr = "itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=\(appID)" // (Option 2) Open App Review Tab
        
        
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
}
