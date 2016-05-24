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
    var searchActive = false
    
    lazy var readLater = [Story]()
    lazy var favorites = [Story]()
    
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
            readLater = savedReadLater
        }
        
        if let savedFavorites = loadFavorites() {
            favorites = savedFavorites
        }
        
        //Refresh control
        self.refreshControl?.addTarget(self, action: #selector(StoryTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredStories.count
        }
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
        } else if sender.selectedSegmentIndex == 2 {
            self.storyType = "favorites"
            self.stories = favorites
            tableView.reloadData()
        } else {
            self.storyType = "readlater"
            self.stories = readLater
            tableView.reloadData()
        }
    }
    
    @IBAction func scrollToTop(sender: UIBarButtonItem) {
        self.tableView.setContentOffset(CGPointMake(0, 0 - self.tableView.contentInset.top), animated: true)
    }
    
    //MARK: Nightmode
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
    }
    
    // MARK: Refresh Control
    func handleRefresh(refreshControl: UIRefreshControl) {
        //Get new stories
        refreshControl.beginRefreshing()
        getStories()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    // MARK: NSCoding
    func saveReadLater() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(readLater, toFile: Story.ArchiveURLReadLater.path!)
        if !isSuccessfulSave {
            print("Failed to save read later...")
        }
    }
    
    func saveFavorites() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(favorites, toFile: Story.ArchiveURLFavorites.path!)
        if !isSuccessfulSave {
            print("Failed to save favorites")
        }
    }
    
    func loadReadLater() -> [Story]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Story.ArchiveURLReadLater.path!) as? [Story]
    }
    
    func loadFavorites() -> [Story]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Story.ArchiveURLFavorites.path!) as? [Story]
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var buttonArray = [UITableViewRowAction]()
        
        if storyType == "topstories" || storyType == "newstories" {
            let favorite = UITableViewRowAction(style: .Normal, title: "Add to Favorites") { action, index in
                print("favorite button tapped")
                if !self.listContainsObject(self.stories[indexPath.row], listToSearch: self.favorites) {
                    self.favorites.append(self.stories[indexPath.row])
                    tableView.setEditing(false, animated: true)
                    self.saveFavorites()
                }
            }
            favorite.backgroundColor = UIColor.lightGrayColor()
            buttonArray.append(favorite)
            
            let readLater = UITableViewRowAction(style: .Normal, title: "Read Later") { action, index in
                print("read later button tapped")
                if !self.listContainsObject(self.stories[indexPath.row], listToSearch: self.readLater) {
                    self.readLater.append(self.stories[indexPath.row])
                    tableView.setEditing(false, animated: true)
                    self.saveReadLater()
                    print(self.readLater)
                }
            }
            readLater.backgroundColor = UIColor.orangeColor()
            buttonArray.append(readLater)
        } else if storyType == "favorites" {
            let removeFavorite = UITableViewRowAction(style: .Normal, title: "Remove from favorites") { action, index in
                print("delete button tapped")
                self.stories.removeAtIndex(indexPath.row)
                self.favorites.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.saveFavorites()
            }
            removeFavorite.backgroundColor = UIColor.redColor()
            buttonArray.append(removeFavorite)
        } else if storyType == "readlater" {
            let removeReadLater = UITableViewRowAction(style: .Normal, title: "Remove from reading list") { action, index in
                print("delete button tapped")
                self.stories.removeAtIndex(indexPath.row)
                self.readLater.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.saveReadLater()
            }
            removeReadLater.backgroundColor = UIColor.redColor()
            buttonArray.append(removeReadLater)
        }
        return buttonArray.reverse()
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        return true
    }
    
    func listContainsObject(story: Story, listToSearch: [Story]) -> Bool {
        for x in listToSearch {
            if x.title == story.title {
                return true
            }
        }
        return false
    }
    
    //MARK: Search
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredStories = stories.filter({ (text) -> Bool in
            let tmp: NSString = text.title
            let range = tmp.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        if searchText.isEmpty {
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
    }
}
