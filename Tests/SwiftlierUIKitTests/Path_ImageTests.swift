//
//  AlertTests.swift
//  SwiftlieriOS
//
//  Created by Andrew J Wagner on 4/29/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import XCTest
import Swiftlier
import SwiftlierUIKit

final class Path_ImageTests: XCTestCase {
    var base: DirectoryPath {
        return try! FileSystem.default.workingDirectory.subdirectory("tmp")
    }

    func testImage() throws {
        let base64Data = "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"
        guard let data = Data(base64Encoded: base64Data) else {
            XCTFail("Failed to parse base64 data")
            return
        }
        let url = URL(fileURLWithPath: "tmp/image.png")
        try data.write(to: url)

        guard let file = try self.base.file("image.png").file else {
            XCTFail("Could not find image file as path")
            return
        }
        XCTAssertNotNil(try file.image())
    }
}
