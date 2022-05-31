//
//  UIResponder+Ext.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-05-29.
//

import UIKit

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
