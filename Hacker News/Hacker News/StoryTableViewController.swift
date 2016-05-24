//
//  StoryTableViewController.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/4/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import UIKit
import SafariServices
import Firebase

class StoryTableViewController: UITableViewController, SFSafariViewControllerDelegate, UISearchBarDelegate {
    
    // MARK: Properties
    var stories = [Story]()
    var filteredStories = [Story]()
    var readLater = [Story]()
    var firebase: Firebase!
    let baseUrl = "https://hacker-news.firebaseio.com/v0/"
    let storyNumLimit: UInt = 60
    var storyType: String = "topstories"
    let dateFormatter = NSDateFormatter()
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var segmentedController: UISegmentedControl!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        firebase = Firebase(url: baseUrl)
        self.dateFormatter.dateFormat = "HH:mm"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Colors.greyishTint
        searchBar.delegate = self
        getStories()
        
        if let savedReadLater = loadReadLater() {
            readLater += savedReadLater
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "StoryTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! StoryTableViewCell
        let story = stories[indexPath.row]
        
        if self.navigationItem.leftBarButtonItem!.title == "Day" {
            cell.backgroundColor = Colors.lightNightTint
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        cell.titleLabel.text = story.title
        if story.score > 1 {
            cell.detailLabel.text = "\(story.score) points by \(story.author), published at \(story.time)"
        } else {
            cell.detailLabel.text = "\(story.score) point by \(story.author), published at \(story.time)"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let story = stories[indexPath.row]
        if let url = story.url {
            let webViewController = SFSafariViewController(URL: NSURL(string: url)!, entersReaderIfAvailable: true)
            webViewController.delegate = self
            presentViewController(webViewController, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getStories() {
        let item = "item"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.stories = []
        // Map each Id to a story
        var storiesMap = [Int:Story]()
        let dataQuery = firebase.childByAppendingPath(storyType).queryLimitedToFirst(storyNumLimit)
        dataQuery.observeSingleEventOfType(.Value, withBlock:  {
            snapshot in let ids = snapshot.value as! [Int]
            for id in ids {
                let dataQuery = self.firebase.childByAppendingPath(item).childByAppendingPath(String(id))
                dataQuery.observeSingleEventOfType(.Value, withBlock: {
                    snapshot in storiesMap[id] = self.getStoryDetail(snapshot)
                    if storiesMap.count == Int(self.storyNumLimit) {
                        // We have our stories
                        for id in ids {
                            // Newest first
                            self.stories.append(storiesMap[id]!)
                        }
                        self.tableView.reloadData()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        print("Stories are in!")
                    }
                })
            }
        })
    }
    
    func getStoryDetail(snapshot: FDataSnapshot) -> Story {
        let title = snapshot.value["title"] as! String
        let url = snapshot.value["url"] as? String
        let author = snapshot.value["by"] as! String
        let score = snapshot.value["score"] as! Int
        let time = NSDate(timeIntervalSince1970: snapshot.value["time"] as! Double)
        let dateString = dateFormatter.stringFromDate(time)
        
        return Story(title: title, url: url, author: author, score: score, time: dateString)
    }
    
    @IBAction func changeStoryType(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.storyType = "topstories"
            getStories()
        } else if sender.selectedSegmentIndex == 1 {
            self.storyType = "newstories"
            getStories()
        } else {
            print("Not yet implemented")
        }
    }
    
    @IBAction func scrollToTop(sender: UIBarButtonItem) {
        self.tableView.setContentOffset(CGPointMake(0, 0 - self.tableView.contentInset.top), animated: true)
    }
    
    @IBAction func changeTheme(sender: UIBarButtonItem) {
        if self.navigationItem.leftBarButtonItem!.title == "Night" {
            nightMode()
        } else {
            dayMode()
        }
        self.tableView.reloadData()
    }
    
    func nightMode(){
        // Navigation Bar
        self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: "Day", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(StoryTableViewController.changeTheme(_:)))
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Colors.greyishTint]
        self.navigationController?.navigationBar.barTintColor = Colors.nightTint
        
        // Search Bar
        self.searchBar.tintColor = UIColor.whiteColor()
        self.searchBar.backgroundColor = Colors.nightTint
        
        // Segmented Control
        self.segmentedController.backgroundColor = Colors.nightTint
        
        // Background
        self.view.backgroundColor = Colors.nightTint
        self.refreshControl?.tintColor = UIColor.whiteColor()
    }
    
    func dayMode(){
        // Navigation Bar
        self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: "Night", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(StoryTableViewController.changeTheme(_:)))
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blackColor()]
        self.navigationController?.navigationBar.barTintColor = Colors.greyishTint
        
        // Search Bar
        self.searchBar.backgroundColor = UIColor.whiteColor()
        self.searchBar.tintColor = Colors.hackerTint
        
        // Segmented Control
        self.segmentedController.backgroundColor = UIColor.whiteColor()
        
        // Background
        self.view.backgroundColor = UIColor.whiteColor()
        self.refreshControl?.tintColor = UIColor.whiteColor()
    }
    
    //MARK: NSCoding
    func saveReadLater() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(readLater, toFile: Story.ArchiveURLReadLater.path!)
        if !isSuccessfulSave {
            print("Failed to save stories...")
        }
    }
    
    func loadReadLater() -> [Story]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Story.ArchiveURLReadLater.path!) as? [Story]
    }
}
