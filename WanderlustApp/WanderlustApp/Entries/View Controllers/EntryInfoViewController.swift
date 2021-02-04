//
//  entryInfoViewController.swift
//  WanderlustApp
//
//  Created by Hudson  Tran on 10/19/20.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

private let cellIdentifier = "entrycell"

// View Controller to view an Entry
class EntryInfoViewController: UIViewController {

    @IBOutlet weak var entryName: UILabel!
    @IBOutlet weak var entryLocation: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var tripLink: UIButton!
    @IBOutlet weak var entryDescription: UILabel!
    @IBOutlet weak var entryImagesCollectionView: UICollectionView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    var user = Auth.auth().currentUser
    var entryImages: [String] = []
    var entryID: String?
    var tripID:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        entryImagesCollectionView.delegate = self
        entryImagesCollectionView.dataSource = self
    }
    
    // Loads entry info each time it will appear
    override func viewWillAppear(_ animated: Bool) {
        entryImagesCollectionView.reloadData()
        loadEntryInfo()
    }
    
    // Function that handles loading of the entry
    func loadEntryInfo() {
        
        print("Loading EntryID: \(entryID)")
        let docRef = db?.collection("entries").document(entryID!)
        docRef?.getDocument { (document, error) in
            if let document = document, let documentData = document.data() {
                self.entryName.text = documentData["entryName"] as? String
                self.entryLocation.text = documentData["locationName"] as? String
                self.entryDescription.text = documentData["description"] as? String
                
                if let tripDocRef = db?.collection("trips").document(documentData["tripID"] as! String) {
                    self.tripID = documentData["tripID"] as! String
                    tripDocRef.getDocument { (tripDoc, error3) in
                        if let tripDoc = tripDoc, let tripData = tripDoc.data() {
                            self.tripLink.setTitle(tripData["tripName"] as? String, for: .normal)
                        }
                    }
                }
                
                fetchUser(uid:documentData["userID"] as! String) { user in
                    self.username.text = user?.username
                }
            }
                
            // Loads the entry images
            self.loadEntryImages(docSnap: document!)
            self.checkUser(docSnap: document!)
            }
        }
    
    // load the given entry's image names
    func loadEntryImages(docSnap: DocumentSnapshot) {
        entryImages.removeAll()
        if let documentData = docSnap.data() {
            let imageList = documentData["mediaList"] as! Array<String>
            for image in imageList {
                entryImages.append(image)
                entryImagesCollectionView.reloadData()
            }
        }
    }
    
    // Checks the user to see if they can edit the entry
    func checkUser(docSnap: DocumentSnapshot) {
        if let documentData = docSnap.data() {
            let ownerId = documentData["userID"] as! String
            if user!.uid != ownerId {
                settingsButton.isEnabled = false
                settingsButton.tintColor = UIColor.clear
            }
        }
    }
    
    // Handles the settings bar viewed by owner of the entry
    @IBAction func barButtonPressed(_ sender: Any) {
        let controller = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        let EditAction = UIAlertAction(title: "Edit",
                                         style: .default,
                                         handler: {
                                            (action) in
                                            let storyboard = UIStoryboard(name: "EditEntry", bundle: nil)
                                            let vc = storyboard.instantiateViewController(withIdentifier: "edit") as! EditEntryViewController
                                            vc.initialTitle = self.entryName.text
                                            vc.initialLocation = self.entryLocation.text
                                            vc.initialDescription = self.entryDescription.text
                                            vc.entryInfoImages = self.entryImages
                                            print("Passing into EditEntry: \(self.entryImages)")
                                            vc.entryID = self.entryID
                                            vc.addNew = false
                                            vc.delegate = self
                                            self.navigationController?.pushViewController(vc, animated: true)
                                         })
        controller.addAction(EditAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                        style: .cancel,
                                        handler: nil)
        controller.addAction(cancelAction)

        present(controller, animated: true, completion: nil)
    }
        
    // Send tripID to the tripInfoVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tripInfoSegue" {
            if let dest = segue.destination as? TripInfoViewController {
                dest.tripId = tripID!
            }
        }
    }
}

// Extension to handle Collection view setup
extension EntryInfoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionview: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return entryImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = entryImagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! EntryInfoCollectionViewCell
            
        let row = indexPath.row
        print("setting image")
        cell.setImage(photo: entryImages[row])
        return cell
    }
}

// Extension to handle collection view style
extension EntryInfoViewController: UICollectionViewDelegateFlowLayout {
    
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
}
