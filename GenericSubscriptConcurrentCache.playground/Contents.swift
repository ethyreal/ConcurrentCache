
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


class Cache<T> {
    
    private var items = [String:T]()
    
    private let queueLabel = "com.mydomain.artists.cache"
    private let queue:DispatchQueue
    
    var count:Int {
        var count:Int = 0
        self.queue.sync(flags: .barrier) {
            count = self.items.count
        }
        return count
    }
    
    init() {
        self.queue = DispatchQueue(label:queueLabel, attributes:.concurrent)
    }
    
    subscript(key: String) -> T? {
        get {
            var item:T?
            self.queue.sync {
                item = self.items[key]
            }
            return item
        }
        set {
            self.queue.async(flags: .barrier) {
                self.items[key] = newValue
            }
        }
    }

    func allItems() -> [T] {
        var items = [T]()
        self.queue.sync {
            items = self.items.map { $0.1 }
        }
        return items
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
        
        self.cache[prince.artistID] = prince
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    func testAddingArtistWithSameIDDoesNotIncrementCount() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "1", name: "David Bowie")
        
        let expectedCount = self.cache.count + 1
        
        self.cache[prince.artistID] = prince
        self.cache[prince.artistID] = bowie
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    func testAddingMultipleArtistsIncrementsCount() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        let expectedCount = self.cache.count + 2
        
        self.cache[prince.artistID] = prince
        self.cache[bowie.artistID] = bowie

        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    
    func testItemByKeyFailsWithInvalidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache[prince.artistID] = prince
        
        XCTAssertNil(self.cache["2"])
    }
    
    
    func testItemByKeyNotNilWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache["1"] = prince
        
        XCTAssertNotNil(self.cache["1"])
    }
    
    
    func testItemByKeyReturnsCorrectArtistWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache["1"] = prince
        
        XCTAssertEqual(prince, self.cache["1"])
    }
    
    
    func testRemoveArtistSuccessfulyRemoves() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache["1"] = prince
        self.cache["1"] = nil
        
        XCTAssertNil(self.cache["1"])
    }
    
    func testRestRemovesAll() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        self.cache["1"] = prince
        self.cache["2"] = bowie
        
        self.cache.reset()
        
        XCTAssertEqual(0, self.cache.count)
    }
    
    
}

ArtistCacheTests.defaultTestSuite.run()
