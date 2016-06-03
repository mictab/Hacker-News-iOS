//
//  CommonExtensions.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/29/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import Foundation

extension Array where Element:Story {
    func contains(story: Story) -> Bool {
        for x in self {
            if x.title == story.title {
                return true
            }
        }
        return false
    }
}