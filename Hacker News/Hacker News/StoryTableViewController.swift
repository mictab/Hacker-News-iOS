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

struct StoryType {
    static let Top = "topstories"
    static let New = "newstories"
    static let Favorite = "favorites"
    static let ReadLater = "readlater"
}

class StoryTableViewController: UITableViewController, SFSafariViewControllerDelegate, UISearchBarDelegate, UIViewControllerPreviewingDelegate {
    
    // MARK: Properties
    
    var stories = [Story]()
    var filteredStories = [Story]()
    var searchActive = false
    lazy var readLater = [Story]()
    lazy var favorites = [Story]()
    var firebase: Firebase!
    let baseUrl = "https://hacker-news.firebaseio.com/v0/"
    let storyNumLimit: UInt = 60
    var storyType = StoryType.Top
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StoryTableViewController.networkStatusChanged(_:)), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
        
        checkNetwork()
        getStories()
        
        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: tableView)
        }
        
        navigationController?.navigationBar.barTintColor = Colors.greyishTint
        searchBar.delegate = self
        
        if let savedReadLater = loadReadLater() {
            readLater = savedReadLater
        }
        
        if let savedFavorites = loadFavorites() {
            favorites = savedFavorites
        }
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
        let story = filteredStories.count > 0 ? filteredStories[indexPath.row] : stories[indexPath.row]
        
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
        let story = filteredStories.count > 0 ? filteredStories[indexPath.row] : stories[indexPath.row]
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
        checkNetwork()
        if storyType == StoryType.Favorite || storyType == StoryType.ReadLater {
            return
        }
        let item = "item"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.stories = []
        var storiesMap = [Int:Story]()
        let dataQuery = firebase.childByAppendingPath(storyType).queryLimitedToFirst(storyNumLimit)
        dataQuery.observeSingleEventOfType(.Value, withBlock:  {
            snapshot in let ids = snapshot.value as! [Int]
            for id in ids {
                let dataQuery = self.firebase.childByAppendingPath(item).childByAppendingPath(String(id))
                dataQuery.observeSingleEventOfType(.Value, withBlock: {
                    snapshot in storiesMap[id] = self.getStoryDetail(snapshot)
                    if storiesMap.count == Int(self.storyNumLimit) {
                        for id in ids {
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
            self.storyType = StoryType.Top
            getStories()
        } else if sender.selectedSegmentIndex == 1 {
            self.storyType = StoryType.New
            getStories()
        } else if sender.selectedSegmentIndex == 2 {
            self.storyType = StoryType.Favorite
            self.stories = favorites
            tableView.reloadData()
        } else {
            self.storyType = StoryType.ReadLater
            self.stories = readLater
            tableView.reloadData()
        }
    }
    
    @IBAction func scrollToTop(sender: UIBarButtonItem) {
        self.tableView.setContentOffset(CGPointMake(0, 0 - self.tableView.contentInset.top), animated: true)
    }
    
    // MARK: Nightmode
    
    @IBAction func changeTheme(sender: UIBarButtonItem) {
        if self.navigationItem.leftBarButtonItem!.title == "Night" {
            nightMode()
        } else {
            dayMode()
        }
        self.tableView.reloadData()
    }
    
    func nightMode(){
        self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: "Day", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(StoryTableViewController.changeTheme(_:)))
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Colors.greyishTint]
        self.navigationController?.navigationBar.barTintColor = Colors.nightTint
        self.searchBar.tintColor = UIColor.whiteColor()
        self.searchBar.backgroundColor = Colors.nightTint
        self.segmentedController.backgroundColor = Colors.nightTint
        self.view.backgroundColor = Colors.nightTint
    }
    
    func dayMode(){
        self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: "Night", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(StoryTableViewController.changeTheme(_:)))
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blackColor()]
        self.navigationController?.navigationBar.barTintColor = Colors.greyishTint
        self.searchBar.backgroundColor = UIColor.whiteColor()
        self.searchBar.tintColor = Colors.hackerTint
        self.segmentedController.backgroundColor = UIColor.whiteColor()
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: Refresh Control
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        getStories()
        if storyType == StoryType.Top || storyType == StoryType.New {
            self.tableView.reloadData()
        }
        refreshControl.endRefreshing()
    }
    
    // MARK: NSCoding
    
    func saveReadLater() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(readLater, toFile: Story.ArchiveURLReadLater.path!)
        if !isSuccessfulSave {
            print("Failed to save read later")
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
        let story = self.filteredStories.count > 0 ? self.filteredStories[indexPath.row] : self.stories[indexPath.row]
        if storyType == StoryType.Top || storyType == StoryType.New {
            let favorite = UITableViewRowAction(style: .Normal, title: "Favorite") { action, index in
                if !self.listContainsObject(story, listToSearch: self.favorites) {
                    self.favorites.append(story)
                    tableView.setEditing(false, animated: true)
                    self.saveFavorites()
                }
            }
            favorite.backgroundColor = UIColor.lightGrayColor()
            buttonArray.append(favorite)
            
            let readLater = UITableViewRowAction(style: .Normal, title: "Read Later") { action, index in
                if !self.listContainsObject(story, listToSearch: self.readLater) {
                    self.readLater.append(story)
                    tableView.setEditing(false, animated: true)
                    self.saveReadLater()
                }
            }
            readLater.backgroundColor = UIColor.orangeColor()
            buttonArray.append(readLater)
        } else if storyType == StoryType.Favorite {
            let removeFavorite = UITableViewRowAction(style: .Normal, title: "Remove") { action, index in
                self.stories.removeAtIndex(indexPath.row)
                self.favorites.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.saveFavorites()
            }
            removeFavorite.backgroundColor = UIColor.redColor()
            buttonArray.append(removeFavorite)
        } else if storyType == StoryType.ReadLater {
            let removeReadLater = UITableViewRowAction(style: .Normal, title: "Remove") { action, index in
                self.stories.removeAtIndex(indexPath.row)
                self.readLater.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.saveReadLater()
            }
            removeReadLater.backgroundColor = UIColor.redColor()
            buttonArray.append(removeReadLater)
        }
        
        let share = UITableViewRowAction(style: .Normal, title: "Share") { action, index in
            let shareText = "Hey! I just read this awesome story in the Hacker News app!"
            if story.url == nil {
                return
            }
            let url = story.url
            let vc = UIActivityViewController(activityItems: [shareText, url!], applicationActivities: nil)
            self.navigationController?.presentViewController(vc, animated: true, completion: nil)
            tableView.setEditing(false, animated: true)
        }
        share.backgroundColor = UIColor.blueColor()
        buttonArray.append(share)
        
        return buttonArray.reverse()
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
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
    
    func configureInternetAlert() {
        print("Internet connection FAILED")
        let OK = UIAlertAction(title: "OK", style: .Default, handler: nil)
        let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.",
                                      preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(OK)
        self.navigationController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Search
    
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
        tableView.reloadData()
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
    
    // MARK: 3D Touch
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let highlightedIndexPath = tableView.indexPathForRowAtPoint(location),
            let cell = tableView.cellForRowAtIndexPath(highlightedIndexPath) else { return nil }
        let arrayToUse = self.filteredStories.count > 0 ? self.filteredStories : self.stories
        let cellToOpen = arrayToUse[highlightedIndexPath.row]
        if cellToOpen.url == nil {
            return nil
        }
        let vc = SFSafariViewController(URL: NSURL(string: cellToOpen.url!)!, entersReaderIfAvailable: true)
        
        vc.preferredContentSize = CGSize(width: 0.0, height: 620.0)
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        presentViewController(viewControllerToCommit, animated: true, completion: nil)
    }
    
    // MARK: Network checks
    
    func networkStatusChanged(notification: NSNotification) {
        let userInfo = notification.userInfo
        print(userInfo)
    }
    
    func checkNetwork() {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            configureInternetAlert()
        default:
            break
        }
    }
}
