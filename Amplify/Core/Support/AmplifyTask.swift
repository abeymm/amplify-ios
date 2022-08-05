//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(Combine)
import Combine
#endif

public protocol AmplifyTask {
    associatedtype Request
    associatedtype Success
    associatedtype Failure: AmplifyError

    var result: Success { get async throws }

    func pause() async
    func resume() async
    func cancel() async

#if canImport(Combine)
    var resultPublisher: AnyPublisher<Success, Failure> { get }
#endif
}

public protocol AmplifyInProcessReportingTask {
    associatedtype InProcess

    var progress: AsyncChannel<InProcess> { get async }

#if canImport(Combine)
    var progressPublisher: AnyPublisher<InProcess, Never> { get }
#endif
}

public typealias AmplifyProgressTask = AmplifyTask & AmplifyInProcessReportingTask
