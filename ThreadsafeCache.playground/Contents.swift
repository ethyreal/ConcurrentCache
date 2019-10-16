
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


class ArtistCache {
    
    private var artists = [String:Artist]()

    private let queueLabel = "com.mydomain.artists.cache"
    private let queue:DispatchQueue

    var count:Int {
        
        var count:Int = 0
        self.queue.sync(flags: .barrier) {
            count = self.artists.count
        }
        return count
    }

    init() {
        self.queue = DispatchQueue(label:queueLabel, attributes:.concurrent)
    }

    func artistByID(_ artistID:String) -> Artist? {

        var foundArtist:Artist?
        
        self.queue.sync {
             foundArtist = self.artists[artistID]
        }
        
        return foundArtist
    }
    
    
    func allArtists() -> [Artist] {
        
        var foundArtists = [Artist]()
        
        self.queue.sync {
            foundArtists = self.artists.map { $0.1 }
        }
        
        return foundArtists
    }
    
    
    func add(artist:Artist) {
        
        self.queue.async(flags: .barrier) {
            self.artists[artist.artistID] = artist
        }
    }
    

    func remove(_ artist:Artist) {

        self.queue.async(flags: .barrier) {
            self.artists[artist.artistID] = nil
        }
    }

    func reset() {
        
        self.queue.async(flags: .barrier) {
            self.artists.removeAll()
        }
    }
}



class ArtistCacheTests: XCTestCase {

    var cache:ArtistCache!
    
    override func setUp() {
        super.setUp()
        
        self.cache = ArtistCache()
    }
    
    override func tearDown() {
        self.cache = nil
        super.tearDown()
    }
    
    func testAllArtistsEmptyWithNewCache() {
        let allArtists = self.cache.allArtists()
        XCTAssert(allArtists.count == 0)
    }
    
    func testAddingArtistIncrementsCounts() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        let expectedCount = self.cache.count + 1
        
        self.cache.add(artist: prince)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }
    
    func testAddingArtistWithSameIDDoesNotIncrementCount() {

        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "1", name: "David Bowie")
        
        let expectedCount = self.cache.count + 1
        
        self.cache.add(artist: prince)
        self.cache.add(artist: bowie)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }

    func testAddingMultipleArtistsIncrementsCount() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        let expectedCount = self.cache.count + 2
        
        self.cache.add(artist: prince)
        self.cache.add(artist: bowie)
        
        XCTAssertEqual(expectedCount, self.cache.count)
    }

    
    func testArtistByIDFailsWithInvalidID() {

        let prince = Artist(id: "1", name: "Prince")

        self.cache.add(artist: prince)
        
        XCTAssertNil(self.cache.artistByID("2"))
    }

    
    func testArtistByIDNotNilWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(artist: prince)
        
        XCTAssertNotNil(self.cache.artistByID("1"))
    }

    
    func testArtistByIDReturnsCorrectArtistWithValidID() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(artist: prince)
        
        XCTAssertEqual(prince, self.cache.artistByID("1"))
    }

    
    func testRemoveArtistSuccessfulyRemoves() {
        
        let prince = Artist(id: "1", name: "Prince")
        
        self.cache.add(artist: prince)
        self.cache.remove(prince)
        
        XCTAssertNil(self.cache.artistByID("1"))
    }
    
    func testRestRemovesAll() {
        
        let prince = Artist(id: "1", name: "Prince")
        let bowie = Artist(id: "2", name: "David Bowie")
        
        self.cache.add(artist: prince)
        self.cache.add(artist: bowie)
        
        self.cache.reset()
        
        XCTAssertEqual(0, self.cache.count)
    }


}

ArtistCacheTests.defaultTestSuite.run()
