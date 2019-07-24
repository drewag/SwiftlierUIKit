//
//  UIView+Helpers.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 9/17/15.
//  Copyright © 2015 Drewag LLC. All rights reserved.
//

import UIKit

extension UIView {
    public var firstResponder: UIView? {
        if self.isFirstResponder {
            return self
        }

        for view in self.subviews {
            if let firstResponder = view.firstResponder {
                return firstResponder
            }
        }
        return nil
    }
}
