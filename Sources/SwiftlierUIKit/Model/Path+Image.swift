//
//  UIImage+Editing.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 5/25/16.
//  Copyright © 2016 Drewag LLC. All rights reserved.
//

import UIKit
import Swiftlier

extension FilePath {
    public func image(scale: CGFloat = 1) throws -> UIImage? {
        let data = try self.contents()
        return UIImage(data: data, scale: scale)
    }
}
