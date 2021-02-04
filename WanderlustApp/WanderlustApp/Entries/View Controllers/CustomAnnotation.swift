//
//  CustomAnnotation.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/21/20.
//

import MapKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Foundation


// Custom annotations to store extra information about sepcific annotation (ie: photos array associated with the annatiation)
class CustomAnnotation: NSObject, MKAnnotation {
    var images: [UIImage] = [] {
        didSet {
            numPhotos = images.count
            print("number of photos \(numPhotos)")
        }
    }
    var imageUrls: [String] = []
    var locationName: String!
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var title: String?
    var text: String?
    var coverPhotoImage:UIImage?
    var coverPhoto:String?
    var username: String?
    var entryOwnerID: String?
    var entryID:String?
    var tripID:String?
    var order:Int?
    var numPhotos = 0
    var timestamp:Timestamp?
    override init() {
    }
    
    init(entry: Entry) {
        self.entryID = entry.entryId
        self.coordinate = CLLocationCoordinate2D(latitude: entry.coordinates!.latitude, longitude: entry.coordinates!.longitude)
        self.coverPhoto = entry.coverPhoto
        self.text = entry.description
        self.title = entry.entryName
        self.locationName = entry.locationName
        self.order = entry.entryOrder
    }
    
    init(image: [UIImage], locationName: String, coordinate: CLLocationCoordinate2D, title: String, text: String, order: Int) {
        super.init()
        self.images = image
        self.locationName = locationName
        self.coordinate = coordinate
        self.title = title
        self.text = text
        self.order = order
        self.entryID = UUID.init().uuidString
        self.username = ""
        fetchUser(uid: (currentUser?.uid)!) { user in
            self.username = user?.username
            
        }
    }
    
    func deleteEntry() {
        //delete from entries collection
        db?.collection("/entries").document("\(self.entryID!)").delete()
        
        //delete from followers
        var followersUids = currentUser?.followers
        followersUids?.append((currentUser?.uid)!)
        for followerUid in followersUids! {
            db?.collection("users").document(followerUid).collection("newsfeed").document(self.entryID!).delete()
        }
        
        //delete from firestore
        let storageRef = storage!.reference()
        for index in 0 ... numPhotos {
            // Create a reference to the file you want to delete
            let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/\(self.entryID!)/image\(index)")
            
            // delete the file at the path imageRef
            print("Path to Delete \(imageRef)")
            // delete the file at the path imageRef
            imageRef.delete { error in
                if let error = error {
                    print(error.localizedDescription)
                  } else {
                    print("deleted")
                  }
            }
        }
    }
    
    func addEntryToFirestore(completion: (() -> Void)?) {
        // this function adds the images to firebase storage
        let storageRef = storage!.reference()
        var imageNameCounter = 0
        
        if images.count == 0 {
            addToFirebase(completion: completion)
            return
        }
        
        // used didset to deal with synchronization issues
        var currentIndex = 0 {
            didSet {
                if currentIndex == images.count {
                    addToFirebase(completion: completion)
                }
            }
        }
        
        self.imageUrls.removeAll()
        for image in images {
            // Data in memory
            guard let imageData = image.jpegData(compressionQuality: 0.2) else {return}
            // Create a reference to the file you want to upload
            let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/\(self.entryID!)/image\(imageNameCounter)")
            imageNameCounter = imageNameCounter + 1
            // Upload the file to the path imageRef
            let uploadTask = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
              // You can also access to download URL after upload.
                print("ERROR: \(error?.localizedDescription)")
                imageRef.downloadURL { (url, error) in
                    print("ERROR Download: \(error?.localizedDescription)")
                    print("url \(url!.absoluteString)")
                    if let downloadURL = url{
                        self.imageUrls.append(downloadURL.absoluteString)
                        print("image url appended: \(self.imageUrls)")
                        currentIndex = currentIndex + 1
                    }
                   
                }
            }
        }
    }
    
    func addToFirebase(completion: (() -> Void)?) {
        //add to the entry entries collection
        print("count \(imageUrls.count)")
        db?.collection("/entries").document("\(self.entryID!)").setData(["coordinates" : GeoPoint(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude),
                                                                         "coverPhoto": self.coverPhoto,
                                                     "description": self.text,
                                                     "entryName": self.title!,
                                                     "entryOrder": self.order!,
                                                     "entryID": self.entryID!,
                                                     "locationName": self.locationName,
                                                     "timestamp": FieldValue.serverTimestamp(),
                                                     "userID": (currentUser?.uid)!,
                                                     "username": self.username,
                                                     "tripID": self.tripID,
                                                     "mediaList": self.imageUrls
        ])
        {
            (error) in
            if let error = error {
                print("BIG ERROR \(self.entryID)")
                print(error.localizedDescription)
            }
            else {
                if let completion = completion {
                    completion()
                    print("Finish add to firestore \(self.entryID)")
                }
                
            }
        }
        
        //add the entry id to other follower's news feed collection
        var followersUids = currentUser?.followers
        followersUids?.append((currentUser?.uid)!)
        for followerUid in followersUids! {
            db?.collection("users").document(followerUid).collection("newsfeed").document(self.entryID!).setData([
                  "timestamp": FieldValue.serverTimestamp(),
                  "userID": (currentUser?.uid)!])
        }
    
    }
}
