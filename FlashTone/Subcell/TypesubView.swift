//
//  TypesubView.swift
//  FlashTone
//
//  Created by Developer on 6/1/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

protocol TypesubViewDelegate {
    func typesClick(_ dict: NSDictionary)
}

class TypesubView: UIView {

    @IBOutlet weak var imgview_type: UIImageView!
    @IBOutlet weak var lbl_title: UILabel!
    var types_dict: NSDictionary?
    var delegate: TypesubViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func typesViewClick(_ sender: Any) {
        self.delegate?.typesClick(self.types_dict!)
    }
    
}
