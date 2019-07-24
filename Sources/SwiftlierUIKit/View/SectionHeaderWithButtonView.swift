//
//  SectionHeaderWithButtonView.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 11/20/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import UIKit

public class SectionHeaderWithButtonView: UITableViewHeaderFooterView {
    public let button = UIButton()

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.sharedInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.sharedInit()
    }
}


extension SectionHeaderWithButtonView {
    func sharedInit() {
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.button)
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.contentView.constrain([.top, .bottom], of: self.button)
        if #available(iOS 9.0, *) {
            self.contentView.readableContentGuide.rightAnchor.constraint(equalTo: self.button.rightAnchor).isActive = true
        } else {
            self.contentView.constrain(.right, of: self.button, plus: -12)
        }
    }
}
