//
//  FollowersListViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/16/20.
//

import UIKit
import FirebaseAuth

protocol RequestManagement {
    func acceptRequest(requestRow: Int)
    func denyRequest(requestRow: Int)
}

class FollowersListViewController: UIViewController {

    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var followersTableView: UITableView!
    @IBOutlet weak var requestLabel: UILabel!
    
    var followers:[String]?
    var requests:[String]?
    var otherUser:User?

    override func viewWillAppear(_ animated: Bool) {
        /// if there is another user, do not show requests
        if(otherUser != nil) {
            setUpFollowersList(user: otherUser!)
            requestsTableView.isHidden = true
            requestLabel.isHidden = true
        } else {
            setUpFollowersList(user: currentUser!)
            requestsTableView.isHidden = false
            requestLabel.isHidden = false
        }

        self.followersTableView.reloadData()
        self.requestsTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        requestsTableView.delegate = self
        followersTableView.delegate = self
        requestsTableView.dataSource = self
        followersTableView.dataSource = self
    }
        
    func setUpFollowersList(user: User) {
        self.followers = user.followers
        self.requests = user.requests
    }
}

extension FollowersListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == requestsTableView {
            return requests?.count ?? 0
        }
        // followers table view
        return followers?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       if tableView == requestsTableView {
            let cell = requestsTableView.dequeueReusableCell(withIdentifier: "requestTableViewCell", for: indexPath as IndexPath)
            let row = indexPath.row
            (cell as! RequestsTableViewCell).delegate = self as RequestManagement
            (cell as! RequestsTableViewCell).requestRow = row
            fetchUser(uid: requests![row]) { user in
                if let cellToUpdate = self.requestsTableView?.cellForRow(at: indexPath) {
                    cellToUpdate.textLabel?.text = user?.username
                    cellToUpdate.setNeedsLayout()
                }
            }
            return cell
       } else {
            /// followers table view
            let row = indexPath.row
            let cell = followersTableView.dequeueReusableCell(withIdentifier: "followersTableViewCell", for: indexPath as IndexPath)

            fetchUser(uid: followers![row]) { user in
                if let cellToUpdate = self.followersTableView?.cellForRow(at: indexPath) {
                    cellToUpdate.textLabel?.text = user?.username
                    cellToUpdate.setNeedsLayout()
                }
            }
            return cell
       }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == requestsTableView {
            let row = indexPath.row
            let storyboard = UIStoryboard(name: "ProfilePage", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "profilePage") as! ProfilePageViewController
            vc.otherUserUid = requests![row]
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let row = indexPath.row
            let storyboard = UIStoryboard(name: "ProfilePage", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "profilePage") as! ProfilePageViewController
            vc.otherUserUid = followers![row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension FollowersListViewController: RequestManagement {
    
    func acceptRequest(requestRow: Int) {
        /// add to followers list on firebase
        self.followers?.append(requests![requestRow])
        modifyFollowers(newFollowersList: self.followers!, user: currentUser!)
        
        /// add to followings list of other user on firebase
        fetchUser(uid: requests![requestRow]) { user in
            var newFollowingList = user?.following
            newFollowingList!.append((currentUser?.uid)!)
            modifyFollowing(newFollowingList: newFollowingList!, user: user!)
        }
        
        let newsfeed = db?.collection("/users/\(requests![requestRow])/newsfeed")
        
        db?.collection("entries").whereField("userID", isEqualTo: (currentUser?.uid)!).order(by: "timestamp", descending: true).limit(to: 20).getDocuments(){
            (querySnapshot, err)
            in
            if let err = err {
                print("error")
            }
            else{
                for document in querySnapshot!.documents{
                    let entry = document.data()
                    newsfeed!.document("\(entry["entryID"]!)").setData(["userID": (currentUser?.uid)!, "timestamp": entry["timestamp"]])
                }
            }
        }
        
        
        /// remove from request list and map
        self.requests = self.requests?.filter { $0 != requests![requestRow] }
        modifyRequests(newRequestsList: self.requests!, user: currentUser!)
        
        requestsTableView.reloadData()
        followersTableView.reloadData()
        
    }
    
    func denyRequest(requestRow: Int) {
        self.requests = self.requests?.filter { $0 != requests![requestRow] }
        modifyRequests(newRequestsList: self.requests!, user: currentUser!)
        requestsTableView.reloadData()
    }
}
