//
//  XCTestCase+MemroyLeaks.swift
//  EssentialFeedTests
//
//  Created by Max Lukashevich on 21/10/2023.
//

import XCTest

extension XCTestCase {
    public func trackForMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated", file: file, line: line)
        }
    }
}
