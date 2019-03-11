//
//  UIController=HideKeyboard.swift
//  WoodieControl
//
//  Created by Marius Hoggenmueller on 10/3/19.
//  Copyright © 2019 Marius Hoggenmueller. All rights reserved.
//

import Foundation

//
//  UIViewController+HideKeyboard.swift
//  AVLightingToolkit
//
//  Created by Marius Hoggenmüller on 19.12.18.
//  Copyright © 2018 Marius Hoggenmüller. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
