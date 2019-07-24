//
//  PassThroughTouchView.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 3/5/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import UIKit
import Swiftlier

public class PassThroughTouchView: UIView {
    public var onDidTouch = MultiCallback<Void>()

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        self.onDidTouch.trigger()
        return nil
    }
}
