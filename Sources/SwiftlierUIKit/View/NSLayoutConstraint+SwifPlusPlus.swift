//
//  NSLayoutConstraint+SwifPlusPlus.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 11/11/15.
//  Copyright © 2015 Drewag LLC. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    public func set(multiplier: CGFloat) {
        guard let firstItem = firstItem else {
            return
        }

        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = self.priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        newConstraint.isActive = self.isActive

        NSLayoutConstraint.activate([newConstraint])
    }
}
