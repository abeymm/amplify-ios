//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class RequestIdentiferTests: XCTestCase {

    func testRequestIdentifer() {
        let key = "key"
        let local = URL(string: "https://www.amazon.com")!
        let request = StorageDownloadFileRequest(key: key, local: local, options: .init())
        XCTAssertFalse(request.requestID.isEmpty)
    }

}
