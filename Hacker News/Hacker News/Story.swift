//
//  Story.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/7/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import UIKit

class Story {
    
    // MARK: Properties
    var title: String
    var url: String
    var author: String
    var score: Int
    
    // MARK: Initialization
    init(title: String, url: String, author: String, score: Int) {
        self.title = title
        self.url = url
        self.author = author
        self.score = score
    }
}
