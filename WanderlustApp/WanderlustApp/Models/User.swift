//
//  User.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/26/20.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

var currentUser:User? = nil

public struct User: Codable {
    @DocumentID var uid:String?
    let username:String
    let followers:[String]
    let following:[String]
    let requests:[String]
    let bio:String
    let publicUser:Bool
    let trips:[String]
    let photoUrl:String?
    let favorites:[String]?

    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case followers
        case following
        case requests
        case bio
        case publicUser = "public"
        case trips
        case photoUrl
        case favorites
    }
}

func addUserToFirestore(newUser: User) {
    do {
        try db?.collection("users").document(Auth.auth().currentUser!.uid).setData(from: newUser)
    } catch let error {
        print("Error writing user to Firestore: \(error)")
    }
}

func fetchUser(uid: String, completion: @escaping (User?)->()) {
    let docRef = db!.collection("users").document(uid)
    var fetchedUser: User?

    docRef.getDocument { (document, error) in
        let result = Result {
          try document?.data(as: User.self)
        }
        switch result {
        case .success(let user):
            if let user = user {
                fetchedUser = user
                print("successful got \(user)")
            } else {
                print("User does not exist")
            }
        case .failure(let error):
            print("Error decoding user: \(error)")
        }
        completion(fetchedUser)

    }
}

func fetchUserTrips(tripIds: [String], completion: @escaping ([Trip]?)->()) {
    var trips:[Trip] = []
    
    for tripId in tripIds {
        db!.collection("trips").document(tripId).getDocument { (document, error) in
           // print(document?.data.time)
            let result = Result {
              try document?.data(as: Trip.self)
            }
            switch result {
            case .success(let trip):
                if let trip = trip {
                    var newTrip = trip
                    newTrip.tripId = document!.documentID
                    trips.append(newTrip)
                    print("successful got \(trip)")
                } else {
                    print("Trip does not exist, removing from favorites")
                }
            case .failure(let error):
                print("Error decoding user: \(error)")
            }
            completion(trips)
        }
    }
}

func unfollowUser(oldFollowingList:[String], unfollowedUser: User) {
    // remove unfollowed user from list
    let newFollowingList = oldFollowingList.filter { $0 != unfollowedUser.uid }
    
    // modify currentusers FOLLOWING list
    modifyFollowing(newFollowingList: newFollowingList, user: currentUser!)
    
    // remove current user from list
    let newFollowersList = unfollowedUser.followers.filter { $0 != currentUser?.uid }
    
    // modify currentusers FOLLOWERS list
    modifyFollowers(newFollowersList: newFollowersList, user: unfollowedUser)
    
    
}

func modifyFollowers(newFollowersList: [String], user: User) {
    db!.collection("users").document(user.uid!).updateData([
        "followers": newFollowersList
    ])
}

func modifyFollowing(newFollowingList: [String], user: User) {
    db!.collection("users").document(user.uid!).updateData([
        "following": newFollowingList
    ])
}

func modifyRequests(newRequestsList: [String], user: User) {
    db!.collection("users").document(user.uid!).updateData([
        "requests": newRequestsList
    ])
}

func changeProfilePicture(profilePicture: UIImage, completion: @escaping (URL?) -> Void) {
    let user = Auth.auth().currentUser
    let storageRef = storage?.reference(withPath: "users/" + user!.uid + "/profilePicture/" + "profile.jpg")
        
    guard let imageData = profilePicture.jpegData(compressionQuality: 0.1) else {
        return print("problem compressing image")
    }

    storageRef!.putData(imageData, metadata: nil, completion: { (metadata, error) in
           if let error = error {
               print(error.localizedDescription)
               return completion(nil)
           }
        storageRef!.downloadURL(completion: { (url, error) in
               if let error = error {
                   print(error.localizedDescription)
                   return completion(nil)
               }
            completion(url)
                
           })
    
    })
}

func addToUsersFavorites(tripId: String) {
    var newFavoriteList = currentUser?.favorites ?? []
    newFavoriteList.append(tripId)
    db!.collection("users").document((currentUser?.uid)!).updateData([
        "favorites": newFavoriteList
    ])
}

func removeFromUsersFavorites(tripId: String) {
    var newFavoriteList = currentUser?.favorites ?? []
    newFavoriteList.remove(at: newFavoriteList.firstIndex(of: tripId)!)
    db!.collection("users").document((currentUser?.uid)!).updateData([
        "favorites": newFavoriteList
    ])
}



