//
//  ProfilePageViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/16/20.
//

import UIKit
import FirebaseAuth
import FirebaseUI

class ProfilePageViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var followers: UIButton!
    @IBOutlet weak var following: UIButton!
    @IBOutlet weak var bio: UILabel!
    @IBOutlet weak var profilePageTripCollectionView: UICollectionView!
    @IBOutlet weak var profileNavigationItem: UINavigationItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var profileTabBarItem: UITabBarItem!
    @IBOutlet weak var seperaterLabel: UILabel!
    @IBOutlet weak var requestNotificationButton: UIButton!
    
    let picker = UIImagePickerController()
    var otherUserUid: String?
    var otherUser:User?
    var selectedTripData:[String]?
    var favoriteView = false
    var cellTripId:String?
    let cache = NSCache<NSString, UIImage>()
        
    override func viewWillAppear(_ animated: Bool) {
        self.profilePageTripCollectionView.alpha = 0
        self.seperaterLabel.isHidden = true
        privacyLabel.isHidden = true
        setUpPrivacyLabel()
        /// we do not care about other user if same as current user
        if(self.otherUserUid != nil && self.otherUserUid! == currentUser!.uid) {
            otherUserUid = nil
        }
        if(self.otherUserUid != nil), let otherUserUid = otherUserUid {
            fetchUser(uid: otherUserUid) { user in
                self.otherUser = user
                self.setUpProfilePage(userProfile: user!)
                self.setFollowButton()
            }
            /// settings and favorites button should not be shown
            profileNavigationItem.rightBarButtonItems = nil
            
        } else {
            profileNavigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[0] = favoriteButton
            profileNavigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[1] = settingsButton
            profileNavigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[0].image =
                UIImage(systemName: favoriteView ? "heart.circle.fill" : "heart.circle")
            followButton.isHidden = true
            followButton.isEnabled = false
            self.setUpProfilePage(userProfile: currentUser!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// make the profile picture circular
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.bounds.width / 2
        
        /// Profile Picture Click Recognition
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profilePictureTapped(gesture:)))
        profilePicture.addGestureRecognizer(tapGesture)
        profilePicture.isUserInteractionEnabled = true
        if(self.otherUserUid != nil) {
            profilePicture.isUserInteractionEnabled = false
        }
        
        /// set up UIImagePickerController for profile pictures
        picker.allowsEditing = true
        picker.delegate = self
        
        /// collection view setup
        profilePageTripCollectionView.delegate = self
        profilePageTripCollectionView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProfileToTripInfoSegue", let dest = segue.destination as? TripInfoViewController {
            dest.tripId = cellTripId!
        }
        if segue.identifier == "ProfileToFollowersSegue", let dest = segue.destination as? FollowersListViewController {
            dest.otherUser = self.otherUser
        }
        if segue.identifier == "ProfileToFollowingSegue", let dest = segue.destination as? FollowingListViewController {
            dest.otherUser = self.otherUser
        }
    }
            
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        /// do not go until cellTripId is set
        if identifier == "ProfileToTripInfoSegue" {
            return false
        }
        return true
    }
        
    @IBAction func favoritesButtonPressed(_ sender: Any) {
        /// facde out trips
        UIView.animate(withDuration: 1, animations: {
            self.profilePageTripCollectionView.alpha = 0
        })
        
        /// toggle to trips of favorites
        favoriteView = !favoriteView
        if favoriteView {
            handleFavoriteTrips()
        } else {
            self.selectedTripData = currentUser?.trips.reversed()
            self.profilePageTripCollectionView.reloadData()
        }
        
        
        /// reappear collection view
        UIView.animate(withDuration:  1, animations: {
            self.profilePageTripCollectionView.alpha = 1
        })
        
        /// toggle button
        profileNavigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[0].image =
            UIImage(systemName: favoriteView ? "heart.circle.fill" : "heart.circle")
    }
    
    @IBAction func followButtonPressed(_ sender: Any) {
        /// If current user was not already following this other user
        if(!((currentUser?.following.contains(self.otherUserUid!))!)) {
            ///check is private, current user will be put on request list
            if(self.otherUser != nil && !(self.otherUser?.publicUser)!) {
                profilePageTripCollectionView.isHidden = true
                privacyLabel.isHidden = false
                self.followButton.backgroundColor = UIColor.systemGray6
                self.followButton.setTitle("Requested", for: .normal)
                /// if current user is not already on the request list
                if(!((self.otherUser?.requests.contains((currentUser?.uid)!))!)) {
                    var newRequestedList = self.otherUser?.requests
                    newRequestedList?.append((currentUser?.uid)!)
                    modifyRequests(newRequestsList: newRequestedList!, user: self.otherUser!)
                }
            } else {
                /// change follow button to reflect new status
                self.followButton.backgroundColor = UIColor.systemGray6
                self.followButton.setTitle("Following", for: .normal)

                /// change CURRENTUSER FOLLOWING list
                var newFollowingList = currentUser?.following
                newFollowingList!.append(self.otherUser!.uid!)
                modifyFollowing(newFollowingList: newFollowingList!, user: currentUser!)

                /// change OTHERUSERS FOLLOWERS list
                var newFollowersList = self.otherUser?.followers
                newFollowersList!.append((currentUser?.uid)!)
                modifyFollowers(newFollowersList: newFollowersList!, user: self.otherUser!)
                          
                //populate newsfeed with the new follwing's information
                let newsfeed = db?.collection("/users/\((currentUser?.uid)!)/newsfeed")
                db?.collection("entries").whereField("userID", isEqualTo: self.otherUser!.uid!).order(by: "timestamp", descending: true).limit(to: 20).getDocuments(){
                    (querySnapshot, err)
                    in
                    if let err = err {
                        print(err.localizedDescription)
                    }
                    else {
                        for document in querySnapshot!.documents{
                            let entry = document.data()
                            newsfeed!.document("\(entry["entryID"]!)").setData(["userID": self.otherUser!.uid!, "timestamp": entry["timestamp"]])
                        }
                    }
                }
            }
            
        } else { /// assume we were following
            /// change button
            self.followButton.backgroundColor = UIColor.systemBlue
            self.followButton.setTitle("Follow", for: .normal)
            
            if(self.otherUser != nil && !(self.otherUser?.publicUser)!) {
                profilePageTripCollectionView.isHidden = true
                privacyLabel.isHidden = false
            }
            
            /// perform unfollow and change CURRENTUSER FOLLOWING list
            unfollowUser(oldFollowingList: (currentUser?.following)!, unfollowedUser: self.otherUser!)
            
            //delete from user's newsfeed when they unfollow the other user
            let newsfeed = db?.collection("/users/\((currentUser?.uid)!)/newsfeed")
            newsfeed?.whereField("userID", isEqualTo: self.otherUser!.uid!).getDocuments() {
                (querySnapshot, err)
                in
                if let err = err {
                    print(err.localizedDescription)
                }
                for document in querySnapshot!.documents{
                    let entry = document.data()
                    newsfeed?.document(document.documentID).delete()
                }
            }
        }
        fetchUsersInfo()
    }
    
    func handleFavoriteTrips() {
        var ct = 0 {
            didSet {
                if ct == (currentUser?.favorites?.count)! {
                    self.selectedTripData = holdSelected.reversed()
                    self.profilePageTripCollectionView.reloadData()
                }
            }
        }
        
        var holdSelected:[String] = []
        for tripId in (currentUser?.favorites)! {
            fetchTrip(tripId: tripId) { trip in
                if trip == nil {
                    removeFromUsersFavorites(tripId: tripId)
                } else {
                    holdSelected.append(tripId)
                }
                ct = ct + 1
            }
        }
    }
    
    func setFollowButton() {
        /// is current user following?
        if((currentUser?.following)!.contains(self.otherUserUid!)) {
            /// yes current user is following
            followButton.backgroundColor = UIColor.systemGray6
            followButton.setTitle("Following", for: .normal)
        } else if((self.otherUser?.requests)!.contains((currentUser?.uid)!)) {
            /// currentUser is not following but has requested
            followButton.backgroundColor = UIColor.systemGray6
            followButton.setTitle("Requested", for: .normal)
            toggleTripCollectionView(hideCollectionView: true)
        } else {
            /// current user is not following
            if(self.otherUser != nil) {
                toggleTripCollectionView(hideCollectionView: !(self.otherUser?.publicUser)!)
            }
            followButton.backgroundColor = UIColor.systemBlue
            followButton.setTitle("Follow", for: .normal)
        }
        // show and enable follow button after it is set up
        followButton.isHidden = false
        followButton.isEnabled = true
    }

    func setUpProfilePage(userProfile: User) {
        
        /// get user trips
        if self.favoriteView {
            handleFavoriteTrips()
        } else {
            self.selectedTripData = userProfile.trips.reversed()
            self.profilePageTripCollectionView.reloadData()
        }
        
    
        /// set up profile with basic info
        self.requestNotificationButton.isHidden = true
        self.username.text = userProfile.username
        self.followers.setTitle("\(userProfile.followers.count  ) Followers", for: .normal)
        self.following.setTitle("\(userProfile.following.count  ) Following", for: .normal)
        self.bio.text = userProfile.bio
        if((currentUser?.requests.count)! > 0 && userProfile.uid == currentUser?.uid!) {
            self.requestNotificationButton.isHidden = false
            self.seperaterLabel.isHidden = false
            self.requestNotificationButton.setTitle("\((currentUser?.requests.count)!) Requests", for: .normal)
        }
        
        /// get profile image
        let placeholderImage = UIImage(named: "defaultProfilePicture")
        self.profilePicture.sd_setImage(with: URL(string: (userProfile.photoUrl ?? " "))){ (image, error, cache, urls) in
            if (error != nil) {
                // Failed to load image
                self.profilePicture.image = placeholderImage
            } else {
                // Successful in loading image
                self.profilePicture.image = image
            }
        }
        
        // fade in collection view
        UIView.animate(withDuration:  1, animations: {
                self.profilePageTripCollectionView.alpha = 1
        })
        
    }
    
    func fetchUsersInfo() {
        fetchUser(uid: (currentUser?.uid!)!){ user in
            currentUser = user
            fetchUser(uid: (self.otherUser?.uid!)!) { user in
                self.otherUser = user
                self.followers.setTitle("\(String(describing: user?.followers.count)) Followers", for: .normal)
                self.setUpProfilePage(userProfile: self.otherUser!)
            }
        }
    }
    
    func setUpPrivacyLabel() {
        privacyLabel.text = "This user is private"
        privacyLabel.numberOfLines = 1
        privacyLabel.sizeToFit()
        privacyLabel.center.y = self.view.center.y
        privacyLabel.center.x = self.view.center.x
    }
    
    func toggleTripCollectionView(hideCollectionView: Bool) {
        // true is do not want to show, false if do want to show
        profilePageTripCollectionView.isHidden = hideCollectionView
        privacyLabel.isHidden = !hideCollectionView
    }
        
}

extension ProfilePageViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = Grid.GRID_SECTION_INSETS.left * (Grid.ITEMS_PER_ROW + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / Grid.ITEMS_PER_ROW

        return CGSize(width: widthPerItem, height: widthPerItem)

    }
  
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Grid.GRID_SECTION_INSETS.left
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedTripData?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = profilePageTripCollectionView.dequeueReusableCell(withReuseIdentifier: "profilePageCollectionViewCell", for: indexPath as IndexPath) as! ProfilePageCollectionViewCell

        let row = indexPath.row
        
        fetchTrip(tripId: (selectedTripData?[row])!) { trip in
                if let cellToUpdate = self.profilePageTripCollectionView?.cellForItem(at: indexPath) {
                    (cellToUpdate as! ProfilePageCollectionViewCell).setTripName(name: (trip?.tripName)!)
                    (cellToUpdate as! ProfilePageCollectionViewCell).setTripCoverPhoto(photo: (trip?.coverPhoto)!, cache: self.cache)
                    (cellToUpdate as! ProfilePageCollectionViewCell).setNeedsLayout()
                }
        }

       return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellTripId = selectedTripData?[indexPath.row]
        performSegue(withIdentifier: "ProfileToTripInfoSegue", sender: self)
    }
    
}

extension ProfilePageViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @objc func profilePictureTapped(gesture: UIGestureRecognizer) {
        if (gesture.view as? UIImageView) != nil {
            present(picker, animated: true)
        }
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        changeProfilePicture(profilePicture: image) { url in
            let profilePicRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            profilePicRequest?.photoURL = url
            profilePicRequest?.commitChanges { (error) in
                if let error = error {
                    print(error.localizedDescription as Any)
                    return
                }
                db?.collection("users").document((currentUser?.uid)!).updateData([
                    "photoUrl": url!.absoluteString
                ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                            fetchUser(uid: (currentUser?.uid)!) { user in
                                currentUser = user
                            }
                        }
                }

            }
        }
        self.profilePicture.image = image
    }
}
