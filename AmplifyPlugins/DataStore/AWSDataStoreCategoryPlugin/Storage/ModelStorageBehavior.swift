//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {
    func setUp(modelSchemas: [ModelSchema]) throws
    
    func applyModelMigrations(modelSchemas: [ModelSchema]) throws
    
    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?
    ) async -> DataStoreResult<M>
    
    func save<M: Model>(
        _ model: M,
        condition: QueryPredicate?
    ) async -> DataStoreResult<M>
    
    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withId id: Model.Identifier,
        condition: QueryPredicate?
    ) async -> DataStoreResult<M?>
    
    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        filter: QueryPredicate
    ) async -> DataStoreResult<[M]>
    
    func query<M: Model>(
        _ modelType: M.Type,
        predicate: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?
    ) async -> DataStoreResult<[M]>
    
    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        predicate: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?
    ) async -> DataStoreResult<[M]>
    
}

protocol ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool
}

extension ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool {
        return false
    }
}
