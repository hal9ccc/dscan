/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to fetch data from the remote server and save it to the Core Data store.
*/

import CoreData
import OSLog
import SwiftUI

class MediaProvider {

    @EnvironmentObject var app: DScanApp

    // MARK: Logging
    let logger = Logger(subsystem: "de.hal9ccc.dscan", category: "persistence")

    // MARK: Core Data

    /// A shared quakes provider for use within the main app bundle.
    static let shared = MediaProvider()
    //static let shared = MediaProvider(inMemory: true)

    /// A quakes provider for use with canvas previews.
    static let preview: MediaProvider = {
        let provider = MediaProvider(inMemory: true)
        Media.makePreviews(count: 10)
        return provider
    }()

    private let inMemory: Bool
    private var notificationToken: NSObjectProtocol?

    @AppStorage("DataSyncHours")
    private var syncRange: Int = 48

    @AppStorage("MaxCID")
    private var maxCID: Int = -1

    @AppStorage("lastMediaChange")
    private var lastMediaChange = Date.distantFuture.timeIntervalSince1970


    private init(inMemory: Bool = false) {

        self.inMemory = inMemory

        // Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
            self.logger.debug("Received a persistent store remote change notification.")
            Task {
                await self.fetchPersistentHistory()
            }
        }
    }

    deinit {
        if let observer = notificationToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?

    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "Media")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()

    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }

    /// Fetches the earthquake feed from the remote server, and imports it into Core Data.
    func fetchMedia(pollingFor pollSeconds: Int, complete: Bool = false)  async throws -> Int {
        let session = URLSession.shared

        @AppStorage("ServerURL")
        var serverurl = "http://localhost"
        let dn = UIDevice.current.name

        let url = URL(string: "\(serverurl)/media/sync?hours=\(syncRange)"
                + (pollSeconds  > -1 ? "&wait=\(pollSeconds)"   : "")
                + (!complete         ? "&cid=\(maxCID)"         : "")
                + "&dn=\(dn.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
        )

        guard let (data, response) = try? await session.data(from: url!)
        else {
            logger.debug("Failed to fetch data from the server.")
            throw DscanError.missingData
        }

        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("\(url?.path ?? "")?\(url?.query ?? ""): \(httpResponse.statusCode) \(String(describing: data))")
        }

        do {
            // Decode the JSON into a data model.
            let jsonDecoder = JSONDecoder()
            //jsonDecoder.dateDecodingStrategy = .iso8601
            let mediaJSON = try jsonDecoder.decode(MediaJSON.self, from: data)
            let mediaPropertiesList = mediaJSON.mediaPropertiesList

            if mediaPropertiesList.count > 0 {
                lastMediaChange = Date().timeIntervalSince1970
                logger.debug("Importing \(mediaPropertiesList.count) records...")
                try await importMedia(from: mediaPropertiesList)
                logger.debug("Finished importing data.")
            }
            return mediaPropertiesList.count

        } catch {
            throw DscanError.wrongDataFormat(error: error)
        }
    }

    /// Uses `NSBatchInsertRequest` (BIR) to import a JSON dictionary into the Core Data store on a private queue.
    func importMedia(from propertiesList: [MediaProperties]) async throws {
        guard !propertiesList.isEmpty else { return }

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importMedia"

        let maxCidFromData = propertiesList.map{$0.cid}.max()
        if maxCidFromData != nil && maxCidFromData! > maxCID {
            logger.info("maxCID: \(self.maxCID) -> \(String(describing:maxCidFromData))")
            maxCID = maxCidFromData!
        }

        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: propertiesList)

            //            if let fetchResult          = try? taskContext.execute(batchInsertRequest),
            //               let batchInsertResult    = fetchResult as? NSBatchInsertResult,
            //               let success              = batchInsertResult.result as? Bool,
            //               success {
            //                return
            //            }


            if let fetchResult              = try? taskContext.execute(batchInsertRequest) {
                if let batchInsertResult    = fetchResult as? NSBatchInsertResult {
                    if let success          = batchInsertResult.result as? Bool {
                        if success {
                            self.logger.info("Successfully inserted data.")

//                            let objectIDArray = batchInsertResult.result as? [NSManagedObjectID]
//                            let changes = [NSUpdatedObjectsKey : objectIDArray]
//                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [taskContext])

                            return
                        }
                    }
                    else {
                        self.logger.debug("Failed to execute batch insert request.")
//                        self.logger.critical("\(String(describing: batchInsertResult))")
                    }
//                    self.logger.critical("batchInsertResult: \(String(describing: batchInsertResult))")
                }
//                self.logger.critical("fetchResult: \(String(describing: fetchResult))")
            }
            self.logger.critical("Failed to execute batch insert request (2).")
            throw DscanError.batchInsertError
        }
    }

    private func newBatchInsertRequest(with propertyList: [MediaProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Media.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }

    /// Synchronously deletes given records in the Core Data store with the specified object IDs.
    func deleteMedia(identifiedBy objectIDs: [NSManagedObjectID]) {
        let viewContext = container.viewContext
        logger.debug("Start deleting data from the store...")

        viewContext.perform {
            objectIDs.forEach { objectID in
                let media = viewContext.object(with: objectID)
                viewContext.delete(media)
            }
        }

        logger.debug("Successfully deleted data.")
    }

    /// Asynchronously deletes records in the Core Data store with the specified `Media` managed objects.
    func deleteMedia(_ media: [Media]) async throws {
        let objectIDs = media.map { $0.objectID }
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "deleteContext"
        taskContext.transactionAuthor = "deleteMedia"
        logger.debug("Start deleting data from the store...")

        try await taskContext.perform {
            // Execute the batch delete.
            let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            guard let fetchResult = try? taskContext.execute(batchDeleteRequest),
                  let batchDeleteResult = fetchResult as? NSBatchDeleteResult,
                  let success = batchDeleteResult.result as? Bool, success
            else {
                self.logger.debug("Failed to execute batch delete request.")
                throw DscanError.batchDeleteError
            }
        }

        logger.debug("Successfully deleted data.")
    }

    func fetchPersistentHistory() async {
        do {
            try await fetchPersistentHistoryTransactionsAndChanges()
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }

    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        logger.debug("Start fetching persistent history changes from the store...")

        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                self.mergePersistentHistoryChanges(from: history)
                return
            }

            self.logger.debug("No persistent history transactions found.")
            throw DscanError.persistentHistoryChangeError
        }

        logger.debug("Finished merging history changes.")
    }

    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = container.viewContext
        viewContext.perform {
            for transaction in history {
                self.logger.debug("Merge...")
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }


    func importSet(_ scanData: [MediaProperties]?) {
        self.logger.debug("Importing \(scanData?.count ?? 0) scan(s)...")

        if scanData != nil && scanData!.count > 0 {
            Task {
                // Import the JSON into Core Data.
                do {
                    try await importMedia(from: scanData!)
                    self.logger.debug("Done!")
                }
                catch {
                    self.logger.debug("\(error.localizedDescription)")
                }
            }
        }
    }





}
