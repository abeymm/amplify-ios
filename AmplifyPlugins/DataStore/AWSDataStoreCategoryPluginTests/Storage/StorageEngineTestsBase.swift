//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class StorageEngineTestsBase: XCTestCase {
    let defaultTimeout = 0.3
    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var syncEngine: MockRemoteSyncEngine!

    /**
     * Below are synchronous conveinence methods.  Please do not add any calls to XCTFail()
     * in these conveinence methods.  Failures should be handled in the body of the unit test.
     */
    func saveModelSynchronous<M: Model>(model: M) -> DataStoreResult<M> {
//        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        result = .success(model)
//        storageEngine.save(model) { sResult in
//            result = sResult
//            saveFinished.fulfill()
//        }
//        wait(for: [saveFinished], timeout: defaultTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func querySingleModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) async -> DataStoreResult<M> {
        let result = await queryModelSynchronous(modelType: modelType, predicate: predicate)

        switch result {
        case .success(let models):
            if models.isEmpty {
                return .failure(causedBy: "Found no models, of type \(modelType.modelName)")
            } else if models.count > 1 {
                return .failure(causedBy: "Found more than one model of type \(modelType.modelName)")
            } else {
                return .success(models.first!)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func queryModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) async -> DataStoreResult<[M]> {
//        let queryFinished = expectation(description: "Query Finished")
//        var result: DataStoreResult<[M]>?

//        wait(for: [queryFinished], timeout: defaultTimeout)
//        let queryResult = await storageEngine.query(modelType, predicate: predicate)
//        result = queryResult
//        queryFinished.fulfill()
        let result = await storageEngine.query(modelType, predicate: predicate)
//        guard let queryResult = result else {
//            return .failure(causedBy: "Query operation timed out")
//        }
        return result
    }

    func deleteModelSynchronousOrFailOtherwise<M: Model>(
        modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil,
        timeout: TimeInterval = 1
    ) async -> DataStoreResult<M> {
        let result = await deleteModelSynchronous(modelType: modelType,
                                            withId: id,
                                            where: predicate,
                                            timeout: timeout)
        switch result {
        case .success(let model):
            if let model = model {
                return .success(model)
            } else {
                return .failure(causedBy: "")
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func deleteModelSynchronous<M: Model>(
        modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil,
        timeout: TimeInterval = 10
    ) async -> DataStoreResult<M?> {
        
//        let deleteFinished = expectation(description: "Delete Finished")
//        wait(for: [deleteFinished], timeout: timeout)
        var result: DataStoreResult<M?>?

        let deleteResult = await storageEngine.delete(
            modelType,
            modelSchema: modelType.schema,
            withId: id,
            condition: predicate
        )
        
        result = deleteResult
//        deleteFinished.fulfill()
            
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }
}
