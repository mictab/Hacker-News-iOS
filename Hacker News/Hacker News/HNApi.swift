//
//  HNApi.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/29/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import Foundation
import Firebase

class HNApi {
    
    // MARK: Properties
    
    let storyNumLimit: UInt = 60
    let dateFormatter = NSDateFormatter()
    let firebase = Firebase(url: "https://hacker-news.firebaseio.com/v0/")
    
    func getStories(storyType: String, completionHandler: ([Story]?, NSError?) -> ()) {
        let item = "item"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var storiesMap = [Int:Story]()
        let dataQuery = firebase.childByAppendingPath(storyType).queryLimitedToFirst(storyNumLimit)
        var stories = [Story]()
        dataQuery.observeSingleEventOfType(.Value, withBlock:  {
            snapshot in let ids = snapshot.value as! [Int]
            for id in ids {
                let dataQuery = self.firebase.childByAppendingPath(item).childByAppendingPath(String(id))
                dataQuery.observeSingleEventOfType(.Value, withBlock: {
                    snapshot in storiesMap[id] = self.getStoryDetail(snapshot)
                    if storiesMap.count == Int(self.storyNumLimit) {
                        for id in ids {
                            stories.append(storiesMap[id]!)
                        }
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        print("GETTING STORIES")
                        completionHandler(stories, nil)
                    }
                })
            }
        })
    }
    
    private func getStoryDetail(snapshot: FDataSnapshot) -> Story {
        self.dateFormatter.dateFormat = "HH:mm"
        
        let title = snapshot.value["title"] as! String
        let url = snapshot.value["url"] as? String
        let author = snapshot.value["by"] as! String
        let score = snapshot.value["score"] as! Int
        let time = NSDate(timeIntervalSince1970: snapshot.value["time"] as! Double)
        let dateString = dateFormatter.stringFromDate(time)
        
        return Story(title: title, url: url, author: author, score: score, time: dateString)
    }
}

let hnApi = HNApi()