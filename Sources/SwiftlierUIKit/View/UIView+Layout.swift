//
//  UIView+Layout.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 9/14/15.
//  Copyright © 2015 Drewag LLC. All rights reserved.
//

import UIKit

extension UIView {
    public func addFillingSubview(_ view: UIView, insetBy inset: CGPoint = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = self.bounds
        self.addSubview(view)
        view.constrainToFill(self, insetBy: inset)
    }

    public func addCenteredView(_ view: UIView, withOffset offset: CGPoint) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        view.constrainToCenter(of: self)
    }

    @available(iOS 9.0, *)
    public var crossPlatformSafeLayoutGuide: UILayoutGuide {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return self.safeAreaLayoutGuide
        }
        else {
            return self.layoutMarginsGuide
        }
    }
}
