//
//  NewsFeedViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/15/20.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import MapKit
import Foundation


class NewsFeedViewController: UIViewController {
    @IBOutlet weak var newsFeedTable: UITableView!
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    
    // The list of entries(posts) to use as source of table view
    var postList:[CustomAnnotation] = []
    
    //current selected row (used for segue, because tableview
    //doesn't recognize when inner collection view cell tapped on)
    var selectedRow: IndexPath!
    
    // number of feeds to return
    let limit = 10
    
    // total number of pictures(used to deal with synchronization problem)
    var totalPics = 0
    
    // refreshing table view to reload
    private let refreshControl = UIRefreshControl()
    
    // Cache for images
    let cache = NSCache<NSString, UIImage>()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        newsFeedTable.delegate = self
        newsFeedTable.dataSource = self
        loadFeedWithFirebase()
        
        // Add the refreshing action
        newsFeedTable.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshNewsFeed), for: .valueChanged)
        refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Updating News Feed")
    }
    
    @objc private func refreshNewsFeed(_ sender: Any) {
        // Fetch News Feed Data
        loadFeedWithFirebase()
    }
    
    @IBAction func toTop(_ sender: Any) {
        refreshNewsFeed(self)
    }
    
    ///function loads the photos for each post, once the posts are all being done added to the postList
    ///done after the populating the whole post list to avoid issues where the order is different each time you refresh
    func loadPhotosFromStorage() {
        var doneCounter = 0 {
            didSet {
                if doneCounter == self.totalPics {
                    self.totalPics = 0
                    self.newsFeedTable.reloadData()
                    self.refreshControl.endRefreshing()
                    let topIndex = IndexPath(row: 0, section: 0)
                    newsFeedTable.scrollToRow(at: topIndex, at: .top, animated: true)
                }
            }
        }
        for post in postList {
            for imageUrl in post.imageUrls {
                if let imageFromCache = cache.object(forKey: imageUrl as NSString) {
                    post.images.append(imageFromCache)
                    doneCounter = doneCounter + 1
                }
                else {
                    let imageRef = storage?.reference(forURL: imageUrl)
                    imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                        if let error = error {
                            print("error loading photos from storage: \(error.localizedDescription)")
                            return
                        }
                        let image = UIImage(data: data!)
                        self.cache.setObject(image!, forKey: imageUrl as NSString)
                        post.images.append(image!)
                        doneCounter = doneCounter + 1
                    }
                }
                
            }
        }
    }
    
    func loadFeedWithFirebase() {
        ///Loads the entries from the newsfeed collection for that user
        ///Entries are sorted by time, where the newest is on top (closer to 0)
        db.collection("/users/\((currentUser?.uid)!)/newsfeed").order(by: "timestamp", descending: true).limit(to: limit).getDocuments() {
            (querySnapshot, error) in

            if querySnapshot != nil {
                
                ///used did set to determine when all the posts are being added to the temp list so we can began downloading the photos
                var tempPostList: [CustomAnnotation] = [] {
                    didSet {
                        if tempPostList.count == querySnapshot?.count {
                            tempPostList.sort(by: {$0.timestamp!.seconds > $1.timestamp!.seconds})
                            self.postList = tempPostList
                            self.loadPhotosFromStorage()
                        }
                    }
                }
                let snapshots = querySnapshot?.documents as [DocumentSnapshot]
                if snapshots.count == 0 {
                    self.postList = []
                    self.newsFeedTable.reloadData()
                    self.refreshControl.endRefreshing()
                    return
                }
                
                ///For each entry we create a customAnnotation object to store the information needed for the newsfeed to display
                for document in snapshots{
                    let document = document as DocumentSnapshot
                    self.db.collection("entries").document(document.documentID).getDocument { (doc , error) in
                        let data = doc!.data()
                        var tempAnnotation:CustomAnnotation = CustomAnnotation()
                        tempAnnotation.imageUrls = data!["mediaList"] as! [String]
                        self.totalPics = tempAnnotation.imageUrls.count + self.totalPics
                        let cords:GeoPoint = data!["coordinates"] as! GeoPoint
                        tempAnnotation.coordinate = CLLocationCoordinate2D(latitude: cords.latitude, longitude: cords.longitude)
                        tempAnnotation.locationName = data!["locationName"] as? String
                        tempAnnotation.title = (data!["entryName"] as! String)
                        tempAnnotation.text = (data!["description"] as! String)
                        tempAnnotation.order = (data!["entryOrder"] as! Int)
                        tempAnnotation.entryOwnerID = data!["userID"] as? String
                        tempAnnotation.coverPhoto = (data!["coverPhoto"] as! String)
                        tempAnnotation.entryID = (data!["entryID"] as! String)
                        tempAnnotation.timestamp = data!["timestamp"] as! Timestamp
                        tempPostList.append(tempAnnotation)
                    }
                }
                
            }
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEntryInfo" {
            let dest = segue.destination as! EntryInfoViewController
            dest.entryID = self.postList[self.selectedRow.row].entryID
        }
    }
        
    ///used when the user taps on the user's profile picture to bring the user to the other user's profile page
    func pushProfilePage(postUid: String) {
        let storyboard = UIStoryboard(name: "ProfilePage", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "profilePage") as! ProfilePageViewController
        vc.otherUserUid = postUid
        self.navigationController?.pushViewController(vc, animated: true)
    }

}

extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = newsFeedTable.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsFeedTableViewCell
        let post = postList[indexPath.row]
        // Download profile image
        storage?.reference(withPath: "/users/\((post.entryOwnerID)!)/profilePicture/profile.jpg").getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
            if let error = error {
                print("error downloading profile picture: \(error.localizedDescription)")
                cell.profileImage.image = UIImage(named: "defaultProfilePicture")
                return
            }
            cell.profileImage.image = UIImage(data: data!)!
        })
        // handles getting the username
        // this handles the case if a user changes it username
        fetchUser(uid: post.entryOwnerID!) { user in
            if let cellToUpdate = self.newsFeedTable.cellForRow(at: indexPath) as? NewsFeedTableViewCell {
                cellToUpdate.username.text = user!.username
                cellToUpdate.setNeedsLayout()
            }
        }
        
        // Populates the post cell with the appropriate information
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        cell.date.text = dateFormatter.string(from: (post.timestamp?.dateValue()) as! Date)
        cell.tripdesciption.text = post.title
        cell.caption = post.text
        cell.photoList = post.images
        cell.uid = post.entryOwnerID
        cell.entry = post
        cell.index = indexPath
        cell.delegate = self
        cell.imageCollection.reloadData()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (newsFeedTable.superview?.safeAreaLayoutGuide.layoutFrame.size.height)!
    }
}
