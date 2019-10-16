
import UIKit
import XCTest

class Artist: Equatable {

    let artistID: String
    let name: String

    init(id artistID: String, name: String) {
        self.artistID = artistID
        self.name = name
    }

    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.artistID == rhs.artistID && lhs.name == rhs.name
    }
}


extension Artist: Cachable {
    var cacheKey: String {
        return self.artistID
    }
}

protocol Cachable {
    
    var cacheKey:String { get }
}


class Cache<T:Cachable> {
    
    private var items = [String:T]()
    
    private let queueLabel = "com.mydomain.artists.cache"
    private let queue:DispatchQueue
    
    var count:Int {
        
        var count:Int = 0
        self.queue.sync {
            count = self.items.count
        }
        return count
    }
    
    init() {
        self.queue = DispatchQueue(label:queueLabel, attributes:.concurrent)
    }
    
    func itemByKey(_ cacheKey:String) -> T? {
        
        var item:T?
        
        self.queue.sync {
            item = self.items[cacheKey]
        }
        
        return item
    }
    
    
    func allItems() -> [T] {
        
        var items = [T]()
        
        self.queue.sync {
            items = self.items.map { $0.1 }
        }
        
        return items
    }
    
    
    func add(item:T) {
        
        self.queue.async(flags: .barrier) {
            self.items[item.cacheKey] = item
        }
    }
    
    
    func remove(_ item:T) {
        
        self.queue.async(flags: .barrier) {
            self.items[item.cacheKey] = nil
        }
    }
    
    func reset() {
        
        self.queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }
}



class ArtistCacheTests: XCTestCase {
    
    var cache:Cache<Artist>!
    
    override func setUp() {
        super.setUp()
        
        self.cache = Cache<Artist>()
    }
    
    override func tearDown() {
        self.cache = nil
        super.tearDown()
    }
    
    func testAllArtistsEmptyWithNewCache() {
        let allArtists = self.cache.allItems()
        XCTAssert(allArtists.count == 0)
    }
    
    func testAddingArtistIncrementsCounts() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        let expectedCount = self.cache.count + 1
        
        self.cache.add(item: prince)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    func testAddingArtistWithSameIDDoesNotIncrementCount() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "1", name: "David Bowie")
        
        let expectedCount = self.cache.count + 1
        
        self.cache.add(item: prince)
        self.cache.add(item: bowie)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    func testAddingMultipleArtistsIncrementsCount() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        let expectedCount = self.cache.count + 2
        
        self.cache.add(item: prince)
        self.cache.add(item: bowie)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    
    func testItemByKeyFailsWithInvalidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(item: prince)
        
        XCTAssertNil(self.cache.itemByKey("2"))
    }
    
    
    func testItemByKeyNotNilWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(item: prince)
        
        XCTAssertNotNil(self.cache.itemByKey("1"))
    }
    
    
    func testItemByKeyReturnsCorrectArtistWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(item: prince)
        
        XCTAssertEqual(prince, self.cache.itemByKey("1"))
    }
    
    
    func testRemoveArtistSuccessfulyRemoves() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(item: prince)
        self.cache.remove(prince)
        
        XCTAssertNil(self.cache.itemByKey("1"))
    }
    
    func testRestRemovesAll() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        self.cache.add(item: prince)
        self.cache.add(item: bowie)
        
        self.cache.reset()
        
        XCTAssertEqual(0, self.cache.count)
    }
    
    
}

ArtistCacheTests.defaultTestSuite.run()
