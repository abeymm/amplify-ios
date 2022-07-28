//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class MutationSyncMetadataMigrationTestBase: XCTestCase {
    var storageAdapter: SQLiteStorageEngineAdapter!
    var modelSchemas: [ModelSchema]!

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .debug
        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            modelSchemas = [Restaurant.schema, Menu.schema, Dish.schema]
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func setUpAllModels() throws {
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

        ModelRegistry.register(modelType: Restaurant.self)
        ModelRegistry.register(modelType: Menu.self)
        ModelRegistry.register(modelType: Dish.self)
        do {
            try storageAdapter.setUp(modelSchemas: modelSchemas)
        } catch {
            XCTFail("Failed to setup storage engine")
        }
    }

    // MARK: - Helpers

    func save<M: Model>(_ model: M) {
        let saveSuccess = expectation(description: "Save successful")
        Task {
            let result = await storageAdapter.save(model)
            switch result {
            case .success: saveSuccess.fulfill()
            case .failure(let error): XCTFail("\(error.errorDescription)")
            }
        }
        wait(for: [saveSuccess], timeout: 1)
    }

    func saveMutationSyncMetadata(_ metadata: MutationSyncMetadata) async {
        let saveMetadataSuccess = expectation(description: "Save metadata successful")
        
        let result = await storageAdapter.save(metadata)
        switch result {
        case .success: saveMetadataSuccess.fulfill()
        case .failure(let error): XCTFail("\(error.errorDescription)")
        }
        
        wait(for: [saveMetadataSuccess], timeout: 1)
    }

    func queryMutationSyncMetadata() async -> [MutationSyncMetadata]? {
        let firstQueryModelSyncMetadata = expectation(description: "query successful")
        var result: [MutationSyncMetadata]?
        wait(for: [firstQueryModelSyncMetadata], timeout: 1)
        let r = await storageAdapter.query(MutationSyncMetadata.self)
        switch r {
        case .success(let mutationSyncMetadatas):
            result = mutationSyncMetadatas
            firstQueryModelSyncMetadata.fulfill()
        case .failure(let error): XCTFail("\(error.errorDescription)")
        }
        
        return result
    }

    func queryModelSyncMetadata() async -> [ModelSyncMetadata]? {
        let queryModelSyncMetadata = expectation(description: "query model sync metadata successful")
        var result: [ModelSyncMetadata]?
        wait(for: [queryModelSyncMetadata], timeout: 1)
        let r = await storageAdapter.query(ModelSyncMetadata.self)
        switch r {
        case .success(let modelSyncMetadatas):
            result = modelSyncMetadatas
            queryModelSyncMetadata.fulfill()
        case .failure(let error): XCTFail("\(error.errorDescription)")
        }
        return result
    }
}
