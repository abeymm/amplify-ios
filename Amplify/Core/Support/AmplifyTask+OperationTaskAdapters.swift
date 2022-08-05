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

class AmplifyOperationTaskAdapter<Request: AmplifyOperationRequest, Success, Failure: AmplifyError>: AmplifyTask {
    let operation: AmplifyOperation<Request, Success, Failure>
    let childTask: ChildTask<Void, Success, Failure>
    var resultToken: UnsubscribeToken? = nil

    init(operation: AmplifyOperation<Request, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        resultToken = operation.subscribe(resultListener: resultListener)
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
    }

    var result: Success {
        get async throws {
            try await childTask.result
        }
    }

    func pause() async {
        operation.pause()
    }

    func resume() async {
        operation.resume()
    }

    func cancel() async {
        await childTask.cancel()
    }

#if canImport(Combine)
    var resultPublisher: AnyPublisher<Success, Failure> {
        operation.resultPublisher
    }
#endif

    private func resultListener(_ result: Result<Success, Failure>) {
        Task {
            await childTask.finish(result)
        }
    }
}

//extension AmplifyTask where Self == AmplifyOperationTaskAdapter {}

public extension AmplifyInProcessReportingTask {}

class AmplifyInProcessReportingOperationTaskAdapter<Request: AmplifyOperationRequest, InProcess, Success, Failure: AmplifyError>: AmplifyProgressTask {
    let operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>
    let childTask: ChildTask<InProcess, Success, Failure>
    var resultToken: UnsubscribeToken? = nil
    var inProcessToken: UnsubscribeToken? = nil

    init(operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        resultToken = operation.subscribe(resultListener: resultListener)
        inProcessToken = operation.subscribe(inProcessListener: inProcessListener)
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
        if let inProcessToken = inProcessToken {
            Amplify.Hub.removeListener(inProcessToken)
        }
    }

    var result: Success {
        get async throws {
            try await childTask.result
        }
    }

    var progress: AsyncChannel<InProcess> {
        get async {
            await childTask.inProcess
        }
    }

    func pause() async {
        operation.pause()
    }

    func resume() async {
        operation.resume()
    }

    func cancel() async {
        await childTask.cancel()
    }

#if canImport(Combine)
    var resultPublisher: AnyPublisher<Success, Failure> {
        operation.resultPublisher
    }

    var progressPublisher: AnyPublisher<InProcess, Never> {
        operation.progressPublisher
    }
#endif

    private func resultListener(_ result: Result<Success, Failure>) {
        Task {
            await childTask.finish(result)
        }
    }

    private func inProcessListener(_ inProcess: InProcess) {
        Task {
            try await childTask.report(inProcess)
        }
    }
}

extension AmplifyOperationTaskAdapter where Request: RequestIdentifier {
    var requestID: String {
        get async {
            operation.request.requestID
        }
    }
}

extension AmplifyInProcessReportingOperationTaskAdapter where Request: RequestIdentifier {
    var requestID: String {
        get async {
            operation.request.requestID
        }
    }
}
