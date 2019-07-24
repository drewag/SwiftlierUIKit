//
//  Float+Factory.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 12/18/16.
//  Copyright © 2016 Drewag. All rights reserved.
//

import UIKit

extension CGFloat {
    public static var thin: CGFloat {
        return CGFloat(1) / UIScreen.main.scale
    }
}
