import Foundation
import CoreData

/// A class to manage CoreData loading and saving.
open class DataController {
	public let persistentContainerName: String
	public let appGroupName: String?
	
	lazy var persistentContainer: NSPersistentContainer = { () -> NSPersistentContainer in
		// Create container
		let container = NSPersistentContainer(name: persistentContainerName)
		container.loadPersistentStores { description, error in
			if let error = error {
				print("Error loading Core Data: \(error.localizedDescription)")
				return
			}
			
			container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
			
			if let appGroupName = self.appGroupName {
				let sharedAppGroupURL = FileManager.default
					.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
				
				guard let sharedAppGroupURL = sharedAppGroupURL else {
					fatalError("Shared app group URL not found!")
				}
				
				print("Shared app group URL found: \(sharedAppGroupURL)")
				
				container.persistentStoreDescriptions.append(
					.init(url: sharedAppGroupURL)
				)
			}
				
			print("CoreDate persistent container stores loaded: \(description.debugDescription)")
		}
		
		return container
	}()
	
	var moc: NSManagedObjectContext { persistentContainer.viewContext }
	
	init(name: String, appGroupName: String? = nil) {
		print("DataController starting for persistent container \"\(name)\"")
		self.persistentContainerName = name
		self.appGroupName = appGroupName
	}
	
	func loadPersistentContainer() {
		let _ = persistentContainer
	}
}

extension DataController {
	/// A function to load generic data from CoreData.
	///
	/// - Parameters:
	///   + sortDescriptors: Sort descriptors for the request. Defaults to an empty array.
	///   + predicate: A search predicate for the request. If `nil`, no predicate will be applied. Defaults to `nil`.
	///   + defaultValue: The default value for the data if it can't be found. Defaults to `nil`.
	///
	/// - Returns: The requested data, or the default value if it can't be found.
	///
	/// - Precondition: There must be only one instance of the data. If not, the first one will be returned.
	func loadData<T: NSManagedObject>(
		sortDescriptors: [NSSortDescriptor] = [],
		predicate: NSPredicate? = nil,
		defaultValue: T? = nil
	) -> T? {
		let fetchedResults: [T] = loadDataArray(
			sortDescriptors: sortDescriptors,
			predicate: predicate,
			resultsLimit: 1
		)
		
		guard fetchedResults.count > 0 else {
			print("WARNING: No CoreData results were found.")
			return defaultValue
		}
		
		return fetchedResults[0]
	}
	
	/// A function to load a generic array of data from CoreData.
	/// - Parameters:
	///   + sortDescriptors: Sort descriptors for the request. Defaults to an empty array.
	///   + predicate: A search predicate for the request. If `nil`, no predicate will be applied. Defaults to `nil`.
	///   + resultsLimit: The amount of results to fetch. If `nil`, all the results will be returned. Defaults to `nil`.
	///   + defaultValue: The default value for the data if it can't be found. Defaults to an empty array.
	///
	/// - Returns: The requested array of data, or the default value if it can't be found.
	func loadDataArray<T: NSManagedObject>(
		sortDescriptors: [NSSortDescriptor] = [],
		predicate: NSPredicate? = nil,
		resultsLimit: Int? = nil,
		defaultValue: [T] = []
	) -> [T] {
		loadPersistentContainer()
		
		print("Loading data array for \(T.entity().name ?? "Unknown Entity").")
		
		let fetchRequest = T.fetchRequest() as! NSFetchRequest<T>
		fetchRequest.sortDescriptors = sortDescriptors
		fetchRequest.predicate = predicate
		if let resultsLimit = resultsLimit { fetchRequest.fetchLimit = resultsLimit }
		
		return (try? moc.fetch(fetchRequest)) ?? defaultValue
	}
}

extension DataController {
	/// Save data to disk
	/// - Returns: `true` if the data was saved correctly, `false` if there was an error or no data to save.
	@discardableResult
	func save() -> Bool {
		if moc.hasChanges {
			do {
				try moc.save()
				
				print("Saved data!")
				return true
			} catch {
				print("Error saving data: \(error.localizedDescription)")
				return false
			}
		}
		
		return false
	}
}
