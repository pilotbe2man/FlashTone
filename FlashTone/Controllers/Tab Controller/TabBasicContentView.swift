//
//  TabBasicContentView.swift
//  FlashTone
//
//  Created by Developer on 5/20/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import Foundation
import ESTabBarController_swift

class TabBasicContentView: ESTabBarItemContentView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        highlightIconColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.renderingMode = .alwaysOriginal
        self.insets = UIEdgeInsetsMake(5.5, 0, -5.5, 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
