//
//  UIImage+Editing.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 5/25/16.
//  Copyright © 2016 Drewag LLC. All rights reserved.
//

import UIKit

extension Date {
    public var dispatchTime: DispatchWallTime {
        let seconds = self.timeIntervalSince1970
        let wholeSecsFloor = floor(seconds)
        let nanosOnly = seconds - wholeSecsFloor
        let nanosFloor = floor(nanosOnly * Double(NSEC_PER_SEC))
        let spec = timespec(tv_sec: Int(wholeSecsFloor),
                            tv_nsec: Int(nanosFloor))
        return DispatchWallTime(timespec: spec)
    }
}
