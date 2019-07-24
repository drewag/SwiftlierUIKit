//
//  NSLayoutContraint+Factory.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 9/14/15.
//  Copyright © 2015 Drewag LLC. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    @discardableResult
    public convenience init(_ attribute: NSLayoutConstraint.Attribute, of view1: UIView, to otherAttribute: NSLayoutConstraint.Attribute, of view2: UIView, relatedBy: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1, plus: CGFloat = 0, active: Bool = true) {
        self.init(
            item: view1,
            attribute: attribute,
            relatedBy: relatedBy,
            toItem: view2,
            attribute: otherAttribute,
            multiplier: multiplier,
            constant: plus
        )
        self.isActive = active
    }
}
