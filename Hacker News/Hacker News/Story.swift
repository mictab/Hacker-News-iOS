//
//  Story.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/7/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import UIKit

class Story: NSObject, NSCoding {
    
    // MARK: Properties
    var title: String
    var url: String?
    var author: String
    var score: Int
    var time: String
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURLReadLater = DocumentsDirectory.URLByAppendingPathComponent("readLater")
    static let ArchiveURLFavorites = DocumentsDirectory.URLByAppendingPathComponent("favorites")
    
    //MARK: Types
    struct PropertyKey {
        static let titleKey = "title"
        static let urlKey = "url"
        static let authorKey = "author"
        static let scoreKey = "score"
        static let timeKey = "time"
    }
    
    // MARK: Initialization
    init(title: String, url: String?, author: String, score: Int, time: String) {
        self.title = title
        self.url = url
        self.author = author
        self.score = score
        self.time = time
        
        super.init()
    }
    
    //MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: PropertyKey.titleKey)
        aCoder.encodeObject(url, forKey: PropertyKey.urlKey)
        aCoder.encodeObject(author, forKey: PropertyKey.authorKey)
        aCoder.encodeInteger(score, forKey: PropertyKey.scoreKey)
        aCoder.encodeObject(time, forKey: PropertyKey.timeKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObjectForKey(PropertyKey.titleKey) as! String
        let url = aDecoder.decodeObjectForKey(PropertyKey.urlKey) as! String
        let author = aDecoder.decodeObjectForKey(PropertyKey.authorKey) as! String
        let score = aDecoder.decodeIntegerForKey(PropertyKey.scoreKey)
        let time = aDecoder.decodeObjectForKey(PropertyKey.timeKey) as! String
        // Must call designated initializer.
        self.init(title: title, url: url, author: author, score: score, time: time)
    }
}
