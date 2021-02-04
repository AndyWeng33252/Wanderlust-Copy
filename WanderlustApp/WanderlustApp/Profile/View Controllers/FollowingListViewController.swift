//
//  FollowingListViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/16/20.
//

import UIKit
import FirebaseAuth

protocol FollowingManagement {
    func unfollow(followingRow: Int)
}

class FollowingListViewController: UIViewController {
    
    @IBOutlet weak var folllowingListTableView: UITableView!
    
    var following:[String]?
    var otherUser:User? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        if(otherUser != nil && otherUser!.uid == currentUser!.uid) {
            otherUser = nil
        }
        if(otherUser != nil) {
            self.following = otherUser?.following
        } else {
            self.following = currentUser?.following
        }
        self.folllowingListTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        folllowingListTableView.delegate = self
        folllowingListTableView.dataSource = self
    }
    
}

extension FollowingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return following?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = folllowingListTableView.dequeueReusableCell(withIdentifier: "followingTableViewCell", for: indexPath as IndexPath)
        let row = indexPath.row
        fetchUser(uid: following![row]) { user in
            if let cellToUpdate = self.folllowingListTableView?.cellForRow(at: indexPath) {
                cellToUpdate.textLabel?.text = user?.username
                cellToUpdate.setNeedsLayout()
            }
        }
        (cell as! FollowingListTableViewCell).delegate = self as FollowingManagement
        (cell as! FollowingListTableViewCell).followingRow = row
        (cell as! FollowingListTableViewCell).unfollowButton.isHidden = (otherUser != nil)
        (cell as! FollowingListTableViewCell).unfollowButton.isEnabled = (otherUser == nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let storyboard = UIStoryboard(name: "ProfilePage", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "profilePage") as! ProfilePageViewController
        vc.otherUserUid = following![row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension FollowingListViewController: FollowingManagement {
    func unfollow(followingRow: Int) {
        /// get the uid of who to unfollow
        let unfollowedUserUid = self.following![followingRow]
        /// fetch that user to modifiy their followers list and currentUsers Following list
        fetchUser(uid: unfollowedUserUid) { user in
            unfollowUser(oldFollowingList: currentUser!.following, unfollowedUser: user!)
            fetchUser(uid: Auth.auth().currentUser!.uid) { user in
                /// get new currentUser
                currentUser = user
                self.following = user?.following
                self.folllowingListTableView.reloadData()
            }
        }
 
    }
}

