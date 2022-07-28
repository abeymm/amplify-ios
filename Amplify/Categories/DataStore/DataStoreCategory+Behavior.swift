//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension DataStoreCategory: DataStoreBaseBehavior {
    public func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil
    ) async -> DataStoreResult<M> {
        await plugin.save(model, where: condition)
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) async -> DataStoreResult<M?> {
        await plugin.query(modelType, byId: id)
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate? = nil,
        sort sortInput: QuerySortInput? = nil,
        paginate paginationInput: QueryPaginationInput?
    ) async -> DataStoreResult<[M]> {
        await plugin.query(
            modelType,
            where: predicate,
            sort: sortInput,
            paginate: paginationInput
        )
    }
    
    public func delete<M: Model>(
        _ model: M,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        await plugin.delete(model, where: predicate)
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async -> DataStoreResult<Void> {
        await plugin.delete(modelType, withId: id, where: predicate)
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate
    ) async -> DataStoreResult<Void> {
        await plugin.delete(modelType, where: predicate)
    }
    
    public func start(completion: @escaping DataStoreCallback<Void>) {
        plugin.start(completion: completion)
    }
    
    public func stop(completion: @escaping DataStoreCallback<Void>) {
        plugin.stop(completion: completion)
    }
    
    public func clear(completion: @escaping DataStoreCallback<Void>) {
        plugin.clear(completion: completion)
    }
}
