//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
import SQLite3

@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class SQLiteStorageEngineAdapterTests: BaseDataStoreTests {

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post)` to check if the model was correctly inserted
    func testInsertPost() async {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        wait(for: [expectation], timeout: 5)
        // insert a post
        let post = Post(title: "title", content: "content", createdAt: .now())
        let saveResult = await storageAdapter.save(post)
        switch saveResult {
        case .success:
            let queryResult = await self.storageAdapter.query(Post.self)
            switch queryResult {
            case .success(let posts):
                XCTAssert(posts.count == 1)
                if let savedPost = posts.first {
                    XCTAssert(post.id == savedPost.id)
                    XCTAssert(post.title == savedPost.title)
                    XCTAssert(post.content == savedPost.content)
                    XCTAssertEqual(post.createdAt.iso8601String, savedPost.createdAt.iso8601String)
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
            expectation.fulfill()
            
        }

    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post, condition = .all)` is called
    /// - Then:
    ///   - call `query(Post)` to check if the model was correctly inserted
    func testInsertPostWithAll() async {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        wait(for: [expectation], timeout: 5)
        let post = Post(title: "title", content: "content", createdAt: .now())
        let saveResult = await storageAdapter.save(post, condition: QueryPredicateConstant.all)
        switch saveResult {
        case .success:
            let queryResult = await self.storageAdapter.query(Post.self)
            switch queryResult {
            case .success(let posts):
                XCTAssert(posts.count == 1)
                if let savedPost = posts.first {
                    XCTAssert(post.id == savedPost.id)
                    XCTAssert(post.title == savedPost.title)
                    XCTAssert(post.content == savedPost.content)
                    XCTAssertEqual(post.createdAt.iso8601String, savedPost.createdAt.iso8601String)
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
            expectation.fulfill()
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post, where: title == post.title)` to check
    ///   if the model was correctly inserted using a predicate
    func testInsertPostAndSelectByTitle() async {
//        let expectation = self.expectation(
//            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content", createdAt: .now())
//        wait(for: [expectation], timeout: 5)
        let saveResult = await storageAdapter.save(post)
        switch saveResult {
        case .success:
            let predicate = Post.keys.title == post.title
            let queryResult = await self.storageAdapter.query(Post.self, predicate: predicate)
            switch queryResult {
            case .success(let posts):
                XCTAssertEqual(posts.count, 1)
                if let savedPost = posts.first {
                    XCTAssert(post.id == savedPost.id)
                    XCTAssert(post.title == savedPost.title)
                    XCTAssert(post.content == savedPost.content)
                    XCTAssertEqual(post.createdAt.iso8601String, savedPost.createdAt.iso8601String)
                }
//                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
//                expectation.fulfill()
            }
        case .failure(let error):
            XCTFail(String(describing: error))
//            expectation.fulfill()
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `save(post)` again with an updated title
    ///   - check if the `query(Post)` returns only 1 post
    ///   - the post has the updated title
    func testInsertPostAndThenUpdateIt() async {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) async {
            let result = await storageAdapter.query(Post.self)
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 1)
                if let post = posts.first {
                    XCTAssertEqual(post.id, id)
                    XCTAssertEqual(post.title, "title updated")
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        var post = Post(title: "title", content: "content", createdAt: .now())
        wait(for: [expectation], timeout: 5)
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            post.title = "title updated"
            let updateResult = await self.storageAdapter.save(post)
            switch updateResult {
            case .success:
                await checkSavedPost(id: post.id)
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
            expectation.fulfill()
        }
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition matches `post.content`
    ///    - a successful update for `update(post, condition)`
    ///    - call `query(Post)` to check if the model was correctly updated
    func testInsertPostAndThenUpdateItWithCondition() async {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) async {
            let result = await storageAdapter.query(Post.self)
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 1)
                if let post = posts.first {
                    XCTAssertEqual(post.id, id)
                    XCTAssertEqual(post.title, "title updated")
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        var post = Post(title: "title", content: "content", createdAt: .now())
        wait(for: [expectation], timeout: 5)
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            post.title = "title updated"
            let condition = Post.keys.content == post.content
            let updateResult = await self.storageAdapter.save(post, condition: condition)
            switch updateResult {
            case .success:
                await checkSavedPost(id: post.id)
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition = .all)` with `post.title` updated and condition `.all`
    ///    - a successful update for `update(post, condition)`
    ///    - call `query(Post)` to check if the model was correctly updated
    func testInsertPostAndThenUpdateItWithConditionAll() async {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) async {
            let result = await storageAdapter.query(Post.self)
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 1)
                if let post = posts.first {
                    XCTAssertEqual(post.id, id)
                    XCTAssertEqual(post.title, "title updated")
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
            
        }

        wait(for: [expectation], timeout: 5)
        var post = Post(title: "title", content: "content", createdAt: .now())
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            post.title = "title updated"
            let updateResult = await self.storageAdapter.save(post, condition: QueryPredicateConstant.all)
            switch updateResult {
            case .success:
                await checkSavedPost(id: post.id)
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post, condition)` is called, condition is passed in.
    /// - Then:
    ///    - Fails with conditional save failed error when there is no existing model instance
    func testUpdateWithConditionFailsWhenNoExistingModel() async {
        let expectation = self.expectation(
            description: "it should fail to update the Post that does not exist")

        wait(for: [expectation], timeout: 5)
        let post = Post(title: "title", content: "content", createdAt: .now())
        let condition = Post.keys.content == "content"
        let insertResult = await storageAdapter.save(post, condition: condition)
        switch insertResult {
        case .success:
            XCTFail("Update should not be successful")
        case .failure(let error):
            guard case .invalidCondition = error else {
                XCTFail("Did not match invalid condition error")
                return
            }
            expectation.fulfill()
        }
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition does not match
    ///    - the update for `update(post, condition)` fails with conditional save failed error
    func testInsertPostAndThenUpdateItWithConditionDoesNotMatchShouldReturnError() async {
        let expectation = self.expectation(
            description: "it should insert and then fail to update the Post, given bad condition")
        wait(for: [expectation], timeout: 5)

        var post = Post(title: "title not updated", content: "content", createdAt: .now())
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            post.title = "title updated"
            let condition = Post.keys.content == "content 2 does not match previous content"
            let updateResult = await self.storageAdapter.save(post, condition: condition)
            switch updateResult {
            case .success:
                XCTFail("Update should not be successful")
            case .failure(let error):
                guard case .invalidCondition = error else {
                    XCTFail("Did not match invalid conditiion")
                    return
                }
                
                expectation.fulfill()
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `delete(Post, id)` and check if `query(Post)` is empty
    ///   - check if `storageAdapter.exists(Post, id)` returns `false`
    func testInsertPostAndThenDeleteIt() async {
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")

        let post = Post(title: "title", content: "content", createdAt: .now())
        let insertResult = await storageAdapter.save(post)
            switch insertResult {
            case .success:
                saveExpectation.fulfill()
                let deleteResult = await self.storageAdapter.delete(Post.self, modelSchema: Post.schema, withId: post.id)
                switch deleteResult {
                case .success:
                    deleteExpectation.fulfill()
                    self.checkIfPostIsDeleted(id: post.id)
                    queryExpectation.fulfill()
                case .failure(let error):
                    XCTFail(error.errorDescription)
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        

        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)
    }

    func testInsertPostAndThenDeleteByIdWithPredicate() async {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")
        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)

        let post = Post(title: "title1", content: "content1", createdAt: dateInFuture)
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            saveExpectation.fulfill()
            let postKeys = Post.keys
            let predicate = postKeys.createdAt.gt(dateTestStart)
            let deleteResult = await self.storageAdapter.delete(
                Post.self,
                modelSchema: Post.schema,
                withId: post.id,
                condition: predicate
            )
            switch deleteResult {
            case .success:
                deleteExpectation.fulfill()
                self.checkIfPostIsDeleted(id: post.id)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
    }

    func testInsertPostAndThenDeleteByIdWithPredicateThatDoesNotMatch() async {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)
//        let saveExpectation = expectation(description: "Saved")
//        let deleteCompleteExpectation = expectation(description: "Delete completed")
//        let queryExpectation = expectation(description: "Queried")
//        wait(for: [saveExpectation, deleteCompleteExpectation, queryExpectation], timeout: 2)
        
        let post = Post(title: "title1", content: "content1", createdAt: dateInFuture)
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
//            saveExpectation.fulfill()
            let postKeys = Post.keys
            let predicate = postKeys.createdAt.lt(dateTestStart)
            let deleteResult = await self.storageAdapter.delete(
                Post.self,
                modelSchema: Post.schema,
                withId: post.id,
                condition: predicate
            )
            switch deleteResult {
            case .success:
//                deleteCompleteExpectation.fulfill()
                self.checkIfPostExists(id: post.id)
//                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
    }

    func testInsertSinglePostThenDeleteItByPredicate() async {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")


        let post = Post(title: "title1", content: "content1", createdAt: dateInFuture)
        let insertResult = await storageAdapter.save(post)
        switch insertResult {
        case .success:
            saveExpectation.fulfill()
            let postKeys = Post.keys
            let predicate = postKeys.createdAt.gt(dateTestStart)
            let deleteResult = await self.storageAdapter.delete(Post.self, modelSchema: Post.schema, filter: predicate)
            switch deleteResult {
            case .success:
                deleteExpectation.fulfill()
                self.checkIfPostIsDeleted(id: post.id)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
            
        case .failure(let error):
            XCTFail(String(describing: error))
        }
        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)
    }

    func testInsertionOfManyItemsThenDeleteAllByPredicateConstant() async {
        let saveExpectation = expectation(description: "Saved 10 items")
        let deleteExpectation = expectation(description: "Deleted 10 items")
        let queryExpectation = expectation(description: "Queried 10 items")

        let titleX = "title"
        let contentX = "content"
        var counter = 0
        let maxCount = 10
        var postsAdded: [String] = []
        while counter < maxCount {
            let title = "\(titleX)\(counter)"
            let content = "\(contentX)\(counter)"

            let post = Post(title: title, content: content, createdAt: .now())
            let insertResult = await storageAdapter.save(post)
                switch insertResult {
                case .success:
                    postsAdded.append(post.id)
                    if counter == maxCount - 1 {
                        saveExpectation.fulfill()
                        let deleteResult = await self.storageAdapter.delete(
                            Post.self,
                            modelSchema: Post.schema,
                            filter: QueryPredicateConstant.all
                        )
                        switch deleteResult {
                        case .success:
                            deleteExpectation.fulfill()
                            for postId in postsAdded {
                                self.checkIfPostIsDeleted(id: postId)
                            }
                            queryExpectation.fulfill()
                        case .failure(let error):
                            XCTFail(error.errorDescription)
                        }
                    }
                    
                case .failure(let error):
                    XCTFail(String(describing: error))
                }
            
            counter += 1
        }
        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 5)
    }

    func checkIfPostIsDeleted(id: String) {
        do {
            let exists = try storageAdapter.exists(Post.schema, withId: id)
            XCTAssertFalse(exists, "ID \(id) should not exist")
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func checkIfPostExists(id: String) {
        do {
            let exists = try storageAdapter.exists(Post.schema, withId: id)
            XCTAssertTrue(exists, "ID \(id) should exist")
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testClearIfNewVersionWithEmptyUserDefaults() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithEmptyUserDefaults") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }
        userDefaults.removeObject(forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.removeItem = { _ in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionWithVersionSameAsPrevious() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithVersionSameAsPrevious") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }
        let previousVersion = "previousVersion"
        userDefaults.set(previousVersion, forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.removeItem = { _ in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionWithMissingFile() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionWithMissingFile") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.removeItem = { _ in
            XCTFail("Should not have called removeItem")
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            XCTFail("Test failed due to \(error)")
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testClearIfNewVersionFailure() {
        guard let userDefaults = UserDefaults.init(suiteName: "testClearIfNewVersionFailure") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"
        let mockFileManager = MockFileManager()
        mockFileManager.hasError = true
        mockFileManager.fileExists = true

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            guard let dataStoreError = error as? DataStoreError, case .invalidDatabase = dataStoreError else {
                XCTFail("Expected DataStoreErrorF")
                return
            }
        }

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testQueryMutationSyncMetadata_EmptyResult() {
        let modelIds = [UUID().uuidString, UUID().uuidString]
        do {
            let results = try storageAdapter.queryMutationSyncMetadata(for: modelIds, modelName: "modelName")
            XCTAssertTrue(results.isEmpty)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testQueryMutationSyncMetadata() async {
        let querySuccess = expectation(description: "query for metadata success")
        let modelId = UUID().uuidString
        let modelName = "modelName"
        let metadata = MutationSyncMetadata(
            modelId: modelId,
            modelName: modelName,
            deleted: false,
            lastChangedAt: Int(Date().timeIntervalSince1970),
            version: 1
        )

        let result = await storageAdapter.save(metadata)
        switch result {
        case .success:
            do {
                let result = try self.storageAdapter.queryMutationSyncMetadata(for: modelId, modelName: modelName)
                XCTAssertEqual(result?.id, metadata.id)
                querySuccess.fulfill()
            } catch {
                XCTFail("\(error)")
            }
        case .failure(let error): XCTFail("\(error)")
        }
        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryMutationSyncMetadataForModelIds() async {
        let modelName = "modelName"
        let metadata1 = MutationSyncMetadata(modelId: UUID().uuidString,
                                             modelName: modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)
        let metadata2 = MutationSyncMetadata(modelId: UUID().uuidString,
                                             modelName: modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)

        let saveMetadata1 = expectation(description: "save metadata1 success")
        let result = await storageAdapter.save(metadata1)
        guard case .success = result else {
            XCTFail("Failed to save metadata")
            return
        }
        saveMetadata1.fulfill()
        wait(for: [saveMetadata1], timeout: 1)

        
        let saveMetadata2 = expectation(description: "save metadata2 success")
        let result2 = await storageAdapter.save(metadata2)
        guard case .success = result2 else {
            XCTFail("Failed to save metadata")
            return
        }
        saveMetadata2.fulfill()
        wait(for: [saveMetadata2], timeout: 1)


        let querySuccess = expectation(description: "query for metadata success")
        var modelIds = [metadata1.modelId]
        modelIds.append(contentsOf: (1 ... 999).map { _ in UUID().uuidString })
        modelIds.append(metadata2.modelId)
        do {
            let results = try storageAdapter.queryMutationSyncMetadata(for: modelIds, modelName: modelName)
            XCTAssertEqual(results.count, 2)
            querySuccess.fulfill()
        } catch {
            XCTFail("\(error)")
        }

        wait(for: [querySuccess], timeout: 1)
    }

    func testShouldIgnoreConstraintViolationError() {
        let constraintViolationError = Result.error(message: "Foreign Key Constraint Violation",
                                                    code: SQLITE_CONSTRAINT,
                                                    statement: nil)
        let dataStoreError = DataStoreError.invalidOperation(causedBy: constraintViolationError)

        XCTAssertTrue(storageAdapter.shouldIgnoreError(error: dataStoreError))
    }

    func testShouldIgnoreErrorFalse() {
        let constraintViolationError = Result.error(message: "",
                                                    code: SQLITE_BUSY,
                                                    statement: nil)
        let dataStoreError = DataStoreError.invalidOperation(causedBy: constraintViolationError)

        XCTAssertFalse(storageAdapter.shouldIgnoreError(error: dataStoreError))
    }
}

// MARK: Reserved words tests
extension SQLiteStorageEngineAdapterTests {
    func testSaveWithReservedWords() async {
        // "Transaction"
        let transactionSaved = expectation(description: "Transaction model saved")
        let result = await storageAdapter.save(Transaction())
        guard case .success = result else {
            XCTFail("Failed to save transaction")
            return
        }
        transactionSaved.fulfill()
        
        
        // "Group"
        let groupSaved = expectation(description: "Group model saved")
        let group = Group()
        let result2 = await storageAdapter.save(group)
        guard case .success = result2 else {
            XCTFail("Failed to save group")
            return
        }
        groupSaved.fulfill()
        
        
        // "Row"
        let rowSaved = expectation(description: "Row model saved")
        let result3 = await storageAdapter.save(Row(group: group))
        guard case .success = result3 else {
            XCTFail("Failed to save Row")
            return
        }
        rowSaved.fulfill()
        wait(for: [transactionSaved, groupSaved, rowSaved], timeout: 1)

    }

    func testQueryWithReservedWords() async {
        // "Transaction"
        let transactionQueried = expectation(description: "Transaction model queried")
        let result = await storageAdapter.query(Transaction.self)
            guard case .success = result else {
                XCTFail("Failed to query Transaction")
                return
            }
            transactionQueried.fulfill()
        

        // "Group"
        let groupQueried = expectation(description: "Group model queried")
        let result2 = await storageAdapter.query(Group.self)
            guard case .success = result2 else {
                XCTFail("Failed to query Group")
                return
            }
            groupQueried.fulfill()
        

        // "Row"
        let rowQueried = expectation(description: "Row model queried")
        wait(for: [transactionQueried, groupQueried, rowQueried], timeout: 1)
        let result3 = await storageAdapter.query(Row.self)
            guard case .success = result3 else {
                XCTFail("Failed to query Row")
                return
            }
            rowQueried.fulfill()
        
    }
}
