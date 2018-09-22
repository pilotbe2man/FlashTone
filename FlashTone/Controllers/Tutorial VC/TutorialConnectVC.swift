//
//  TutorialConnectVC.swift
//  FlashTone
//
//  Created by Developer on 5/19/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class TutorialConnectVC: UIViewController {

    @IBOutlet weak var scroll_pagecontrol: UIPageControl!
    @IBOutlet weak var lbl_page_description: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    @IBAction func closeBtnClicck(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}


extension TutorialConnectVC: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        self.scroll_pagecontrol .currentPage = Int(pageIndex)
        switch Int(pageIndex) {
        case 0:
            self.lbl_page_description.text = "Connect your device to the computer and launch iTunes"
            break
        case 1:
            self.lbl_page_description.text = "Select your device and then “File Sharing” tab"
            break
        case 2:
            self.lbl_page_description.text = "Choose Flashtone app from the list"
            break
        case 3:
            self.lbl_page_description.text = "Select ringtones, then drag and drop them to the computer desktop"
            break
        case 4:
            self.lbl_page_description.text = "Open “Tones” tab in iTunes"
            break
        case 5:
            self.lbl_page_description.text = "Drag and drop ringtones to the “Tones” and click “Done”"
            break
        case 6:
            self.lbl_page_description.text = "Go to device “Settings” > “Sounds”"
            break
        case 7:
            self.lbl_page_description.text = "Tap the sound you want to change and choose a new ringtone"
            break
        default:
            break
        }
    }
}
