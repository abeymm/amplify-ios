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

/// Base class for Local data store tests
class BaseDataStoreTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var dataStorePlugin: AWSDataStorePlugin!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        sleep(2)
        await Amplify.reset()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                  dataStoreConfiguration: .default)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        } catch {
            XCTFail(String(describing: error))
            return
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return self.storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        // Since these tests use syncable models, we have to set up an API category also
        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let apiPlugin = MockAPICategoryPlugin()

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
            XCTAssertEqual(dataStorePlugin.dispatchedModelSyncedEvents.count, ModelRegistry.modelSchemas.count)
            Amplify.DataStore.start(completion: {_ in})
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // MARK: - Utilities

    func populateData<M: Model>(_ models: [M]) async {
        
        func save(model: M, index: Int) async {
            let result = await storageAdapter.save(model)
            switch result {
            case .success:
                let nextIndex = index + 1
                if nextIndex < models.endIndex {
                    await save(model: models[nextIndex], index: nextIndex)
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
             
            }
        }

        if let model = models.first {
            await save(model: model, index: 0)
        }

    }
}
