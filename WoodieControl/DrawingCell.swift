//
//  DrawingViewCell.swift
//  WoodieControl
//
//  Created by Marius Hoggenmueller on 9/5/19.
//  Copyright © 2019 Marius Hoggenmueller. All rights reserved.
//

import Foundation
import UIKit

class DrawingCell: UICollectionViewCell {

    @IBOutlet weak var img: UIImageView!
    
    func initCellItem(with image: UIImage) {
        img.image = image
        
    }


}

