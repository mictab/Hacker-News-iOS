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
    var url: String?
    var author: String
    var score: Int
    var time: String
    
    // MARK: Initialization
    init(title: String, url: String?, author: String, score: Int, time: String) {
        self.title = title
        self.url = url
        self.author = author
        self.score = score
        self.time = time
    }
}
