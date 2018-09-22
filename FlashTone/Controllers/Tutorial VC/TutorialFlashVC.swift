//
//  TutorialFlashVC.swift
//  FlashTone
//
//  Created by Hakan Koluaçık on 10.07.2018.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class TutorialFlashVC: UIViewController {

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

extension TutorialFlashVC: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        self.scroll_pagecontrol .currentPage = Int(pageIndex)
        switch Int(pageIndex) {
        case 0:
            self.lbl_page_description.text = "“Settings” > “General”"
            break
        case 1:
            self.lbl_page_description.text = "“General” > “Accessibility”"
            break
        case 2:
            self.lbl_page_description.text = "Click on the “LED Flash for Alerts”"
            break
        case 3:
            self.lbl_page_description.text = "Finally switch the button!"
            break
        default:
            break
        }
    }
}
