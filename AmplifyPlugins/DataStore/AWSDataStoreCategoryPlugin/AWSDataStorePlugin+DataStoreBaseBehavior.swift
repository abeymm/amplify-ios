//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension AWSDataStorePlugin: DataStoreBaseBehavior {
    
    public func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil
    ) async -> DataStoreResult<M> {
        await save(model, modelSchema: model.schema, where: condition)
    }
    
    public func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        where condition: QueryPredicate? = nil
    ) async -> DataStoreResult<M> {
        log.verbose("Saving: \(model) with condition: \(String(describing: condition))")
        initStorageEngineAndStartSync()
        
        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            guard let engine = storageEngine as? StorageEngine else {
                throw DataStoreError.configuration("Unable to get storage adapter",
                                                   "")
            }
            modelExists = try engine.storageAdapter.exists(modelSchema, withId: model.id, predicate: nil)
        } catch {
            if let dataStoreError = error as? DataStoreError {
                return .failure(dataStoreError)
            }
            
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            return .failure(dataStoreError)
        }
        
        let mutationType = modelExists ? MutationEvent.MutationType.update : .create
        
        let result = await storageEngine.save(
            model,
            modelSchema: modelSchema,
            condition: condition
        )
        
        switch result {
        case .success(let model):
            // TODO: Differentiate between save & update
            // TODO: Handle errors from mutation event creation
            self.publishMutationEvent(
                from: model,
                modelSchema: modelSchema,
                mutationType: mutationType
            )
        case .failure:
            break
        }
        return result
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) async -> DataStoreResult<M?> {
        initStorageEngineAndStartSync()
        let predicate: QueryPredicate = field("id") == id
        let result = await query(modelType, where: predicate, paginate: .firstResult)
        switch result {
        case .success(let models):
            do {
                let first = try models.unique()
                return .success(first)
            } catch {
                return .failure(causedBy: error)
            }
        case .failure(let error):
            return .failure(causedBy: error)
        }
        
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate? = nil,
        sort sortInput: QuerySortInput? = nil,
        paginate paginationInput: QueryPaginationInput? = nil
    ) async -> DataStoreResult<[M]> {
        await query(
            modelType,
            modelSchema: modelType.schema,
            where: predicate,
            sort: sortInput?.asSortDescriptors(),
            paginate: paginationInput
        )
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate? = nil,
        sort sortInput: [QuerySortDescriptor]? = nil,
        paginate paginationInput: QueryPaginationInput? = nil
    ) async -> DataStoreResult<[M]> {
        initStorageEngineAndStartSync()
        return await storageEngine.query(
            modelType,
            modelSchema: modelSchema,
            predicate: predicate,
            sort: sortInput,
            paginationInput: paginationInput
        )
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        await delete(modelType, modelSchema: modelType.schema, withId: id, where: predicate)
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        initStorageEngineAndStartSync()
        let result = await storageEngine.delete(
            modelType,
            modelSchema: modelSchema,
            withId: id,
            condition: predicate
        )
        return onDeleteCompletion(result: result, modelSchema: modelSchema)
    }
    
    public func delete<M: Model>(
        _ model: M,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        await delete(
            model,
            modelSchema: model.schema,
            where: predicate
        )
    }
    
    public func delete<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        initStorageEngineAndStartSync()
        let result = await storageEngine.delete(
            type(of: model),
            modelSchema: modelSchema,
            withId: model.id,
            condition: predicate
        )
        return self.onDeleteCompletion(
            result: result,
            modelSchema: modelSchema
        )
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate
    ) async -> DataStoreResult<Void> {
        await delete(
            modelType, modelSchema: modelType.schema,
            where: predicate
        )
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate
    ) async -> DataStoreResult<Void> {
        initStorageEngineAndStartSync()
        
        let result: DataStoreResult<[M]> = await storageEngine.delete(
            modelType,
            modelSchema: modelSchema,
            filter: predicate
        )
        
        switch result {
        case .success(let models):
            for model in models {
                self.publishMutationEvent(
                    from: model,
                    modelSchema: modelSchema,
                    mutationType: .delete
                )
            }
            return .emptyResult
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func start(completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSync { result in
            completion(result)
        }
    }
    
    public func stop(completion: @escaping DataStoreCallback<Void>) {
        storageEngineInitQueue.sync {
            operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
            dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }
            if storageEngine == nil {
                
                completion(.successfulVoid)
                return
            }
            
            storageEngine.stopSync { result in
                self.storageEngine = nil
                completion(result)
            }
        }
    }
    
    public func clear(completion: @escaping DataStoreCallback<Void>) {
        if case let .failure(error) = initStorageEngine() {
            completion(.failure(causedBy: error))
            return
        }
        
        storageEngineInitQueue.sync {
            operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
            dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }
            if storageEngine == nil {
                completion(.successfulVoid)
                return
            }
            storageEngine.clear { result in
                self.storageEngine = nil
                completion(result)
            }
        }
    }
    
    // MARK: Private
    
    private func onDeleteCompletion<M: Model>(
        result: DataStoreResult<M?>,
        modelSchema: ModelSchema
    ) -> DataStoreResult<Void> {
        switch result {
        case .success(let model):
            if let model = model {
                publishMutationEvent(
                    from: model,
                    modelSchema: modelSchema,
                    mutationType: .delete
                )
            }
            return .emptyResult
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func publishMutationEvent<M: Model>(
        from model: M,
        modelSchema: ModelSchema,
        mutationType: MutationEvent.MutationType
    ) {
        
        let metadata = MutationSyncMetadata.keys
        let metadataId = MutationSyncMetadata.identifier(modelName: modelSchema.name, modelId: model.id)
        Task {
            let result = await storageEngine.query(
                MutationSyncMetadata.self,
                predicate: metadata.id == metadataId,
                sort: nil,
                paginationInput: .firstResult
            )
            do {
                let result = try result.get()
                let syncMetadata = try result.unique()
                let mutationEvent = try MutationEvent(
                    model: model,
                    modelSchema: modelSchema,
                    mutationType: mutationType,
                    version: syncMetadata?.version
                )
                self.dataStorePublisher?.send(input: mutationEvent)
            } catch {
                self.log.error(error: error)
            }
        }
    }
}
