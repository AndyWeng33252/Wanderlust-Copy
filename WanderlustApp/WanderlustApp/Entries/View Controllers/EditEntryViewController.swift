//
//  EditEntryViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/16/20.
//

import UIKit
import MapKit
import Firebase

class EditEntryViewController: UIViewController {
    
    @IBOutlet weak var entryNameField: UITextField!
    @IBOutlet weak var locationNameField: UITextField!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var editImageCollectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var mapView: MKMapView!
    
    ///Varaibles that are used to fill the initial values if any
    var initialTitle:String!
    var initialDescription:String!
    var initialLocation:String!
    var addNew = true
    var delegate:UIViewController!
    var currentAnnotation: CustomAnnotation!
    
    ///Variables used for selecting a cover photo for the entry
    var entryCoverPhoto = UIImage(named: "entryPlaceholder")
    var entryCoverURL:String!
    var entryImage:[UIImage] = []
    
    
    var entryID:String!
    var initialImageCount: Int = 0
    
    // entryInfoImages is passed from entryInfo
    var entryInfoImages:[String] = []
    
    ///alert to add photo
    var addImageAlert = UIAlertController(title: "Add Photo", message: "Where would like to select photos?", preferredStyle: .actionSheet)
     
    ///alert to check if the entires have the required elements
    var pictureCheck = UIAlertController(title: "Empty Field", message: "An entry must contain at least one photo, a cover, and cannot have empty location, name, and description", preferredStyle: .alert)
    
    ///alert to make sure the user wants to delete
    var deleteAlert = UIAlertController(title: "Delete An Image", message: "Are you sure you want to delete this entry?", preferredStyle: .alert)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if entryInfoImages.count > 0 {
            loadImagesFromEntryInfo()
            initialImageCount = entryInfoImages.count
        }
        editImageCollectionView.reloadData()
        
        saveButton.layer.cornerRadius = 5
        deleteButton.layer.cornerRadius = 5
        
        ///hide delete if the you are just adding an entry
        if addNew || ((delegate as? EntryInfoViewController) != nil) {
            deleteButton.isHidden = true
        }

        ///The three optional binding below sets inital value if there is one
        if let location = self.initialLocation {
            locationNameField.text = location
        }
        if let title = self.initialTitle, let description = self.initialDescription {
            entryNameField.text = title
            descriptionField.text = description
        }
        if let annotation = self.currentAnnotation {
            entryCoverPhoto = annotation.coverPhotoImage
            entryCoverURL = annotation.coverPhoto
        }
        
        
        ///initializing the ImagePickers (both from album and from camera)
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
//        let cameraPicker = UIImagePickerController()
//        cameraPicker.sourceType = .camera
//        cameraPicker.allowsEditing = true
//        cameraPicker.delegate = self
//
        
        ///**add alerts for choosing media**
        addImageAlert.addAction(UIAlertAction(title: "Choose From Album", style: .default, handler: {(alert:UIAlertAction) in
            self.present(picker, animated: true, completion: nil)
        }))
        
        ///We took the camera out since simulators didn't have cameras
        addImageAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(alert:UIAlertAction) in
//            self.present(cameraPicker, animated: true)
        }))
        addImageAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        pictureCheck.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(alert: UIAlertAction) in
            self.deleteEntry()
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        ///styling the 3 text fields
        descriptionField.layer.borderWidth = 1
        entryNameField.layer.borderWidth = 1
        locationNameField.layer.borderWidth = 1
        descriptionField.layer.borderColor = UIColor.black.cgColor
        entryNameField.layer.borderColor = UIColor.black.cgColor
        locationNameField.layer.borderColor = UIColor.black.cgColor
        
        
        ///collectionview delegates is self
        editImageCollectionView.delegate = self
        editImageCollectionView.dataSource = self
        
    }

    /// Get rid of keyboard when you touch the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
    }
    
    /// present the add image alert to give user ability to chose image from album or take from camera
    @IBAction func addPhoto(_ sender: Any) {
        present(addImageAlert, animated: true, completion: nil)
    }

    
   
    @IBAction func deleteButtonPressed(_ sender: Any) {
        present(deleteAlert, animated: true, completion: nil)
    }
    
    ///function used to delete the entry from map and array of entries for trip
    func deleteEntry() {
        let vc = delegate as? EditTripViewController
        vc?.deleteAnnotation(annotation: currentAnnotation)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    // When the save button is pressed
     //   - If the delegate is Edit Entry then we would just use the add annotation
     //     the annotation list on the map
     //   - If the delegate is Entry Info then just update the entry info
     // Then pop this view controller off the stack
    @IBAction func saveButton(_ sender: Any) {
        if entryImage.count == 0 || entryNameField.text == "" || locationNameField.text == "" || descriptionField.text == "" || entryCoverPhoto == UIImage(named: "entryPlaceholder") {
            present(pictureCheck, animated: true, completion: nil)
            return
        }
        
        uploadEntryCoverPhoto {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(self.locationNameField.text!) { [self](placemarks, error) -> Void
                in
                guard let placemarks = placemarks, let location = placemarks.first?.location
                else {
                    print(error?.localizedDescription)
                    print("No Location")
                    return
                }
                ///If the delegate was Edit Trip, we also have to find out if the segue was from the edit button or adding a new entry
                if let vc = delegate as? EditTripViewController {
                    if addNew {
                        ///create new entry/annotation object
                        vc.addAnnotation(location: location.coordinate, title: entryNameField.text!, text: descriptionField.text!, images: entryImage, locationName: locationNameField.text!, coverPhotoURL: entryCoverURL, coverPhotoImage: entryCoverPhoto!)
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    else {
                        ///We just wanted to edit, so just update the values and don't create a new annotation
                        currentAnnotation.coordinate = location.coordinate
                        currentAnnotation.title = entryNameField.text!
                        currentAnnotation.text = descriptionField.text!
                        currentAnnotation.images = entryImage
                        currentAnnotation.locationName = locationNameField.text!
                        currentAnnotation.coverPhoto = self.entryCoverURL
                        currentAnnotation.coverPhotoImage = self.entryCoverPhoto
                        ///Reset the map so it's not selecting the same annotation when we pop this VC
                        mapView.deselectAnnotation(currentAnnotation, animated: false)
                        mapView.selectAnnotation(currentAnnotation, animated: true)
                        self.navigationController?.popViewController(animated: true)

                    }
                }
                
                if let vc = delegate as? EditEntryViewController {
                    currentAnnotation.coordinate = location.coordinate
                    currentAnnotation.title = entryNameField.text!
                    currentAnnotation.text = descriptionField.text!
                    currentAnnotation.images = entryImage
                    currentAnnotation.locationName = locationNameField.text!
                    currentAnnotation.coverPhoto = self.entryCoverURL
                    currentAnnotation.coverPhotoImage = self.entryCoverPhoto
                    currentAnnotation.addToFirebase {}
                    self.navigationController?.popViewController(animated: true)

                }
            }
            
            
            // If the entryInfoImages is > 0, we know it's from an entryInfoVC
            if self.initialImageCount > 0 {
                self.entryInfoImages.removeAll()
                self.updateEntry() {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

    }
    
    
    /// This function is used to upload the entry's cover photo to firebase storage when the save button is pressed
    func  uploadEntryCoverPhoto(completion: (() -> Void)?) {
        guard let imageData = entryCoverPhoto?.jpegData(compressionQuality: 0.2) else {return}
        // Create a reference to the file you want to upload
        let storageRef = storage!.reference()
        let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/entryCovers/\(entryID)")
        // Upload the file to the path imageRef
        let uploadTask = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
          // You can also access to download URL after upload.
            imageRef.downloadURL { (url, error) in
                if let downloadURL = url{
                    self.entryCoverURL = downloadURL.absoluteString
                    completion!()
                }
               
            }
        }
    }
    
    
    ///This is used tp update the entry on firebase firestore, this is only called if the delegate was entry info, since we need the newest info
    ///as soon as save was pressed in order to update the entry info when we pop this VC
    func updateEntry(completion: (() -> Void)?) {
        var imageNameCounter = 0
        var currentIndex = 0
        
        var tempEntryList:[String] = [] {
            didSet{
                // Compare sizes to ensure that each new image has been added to the temp list
                if tempEntryList.count == entryImage.count {
                    db?.collection("entries").document(entryID!).setData(
                        ["entryName" : self.entryNameField.text,
                         "locationName": self.locationNameField.text,
                         "description" : self.descriptionField.text,
                         "coverPhoto": entryCoverURL,
                         "mediaList": self.entryInfoImages,
                        ], merge: true) {
                        (error) in
                        if let error = error {
                            print("error: \(error)")
                        }
                        if let completion = completion {
                            completion()
                        }
                    }
                    
               
                }
            }
        }
        
            let storageRef = storage!.reference()
            for imageIndex in 0...entryImage.count - 1 {
                // Data in memory
                guard let imageData = entryImage[imageIndex].jpegData(compressionQuality: 0.2) else {return}
                // Create a reference to the file you want to upload
                let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/\(self.entryID!)/images\(imageNameCounter)")
                imageNameCounter = imageNameCounter + 1
                // Upload the file to the path imageRef
                let uploadTask = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                  // You can also access to download URL after upload.
                    imageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {return}
                        self.entryInfoImages.append(downloadURL.absoluteString)
                        print("image url appended: \(self.entryInfoImages)")
                        tempEntryList.append(downloadURL.absoluteString)
                        currentIndex = currentIndex + 1
                    }
                }
            }
    }

    
    // Used by the cell, which conforms to this class, to delete images from the screen/entry image array
    func deleteImage(index:Int) {
        entryImage.remove(at: index)
        editImageCollectionView.reloadData()
    }
    
    // Loads images for the entry the delegate was from entryInfo
    func loadImagesFromEntryInfo() {
        var tempImages:[UIImage] = [] {
            didSet{
                if tempImages.count == entryInfoImages.count {
                    initialImageCount = tempImages.count
                }
            }
        }
        
        //load entry cover photo
        let docRef = db?.collection("entries").document(entryID!)
        docRef?.getDocument(completion: {(document, error) in
            if let document = document, document.exists, let entryData = document.data() {
                let imageRef = storage?.reference(forURL: entryData["coverPhoto"] as! String)
                self.entryCoverURL = entryData["coverPhoto"] as! String
                imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                        if let error = error {
                            print("error")
                            return
                        }
                    self.entryCoverPhoto = UIImage(data: data!)
                    }
                }
            })
        
        //load images
        for photoUrl in entryInfoImages {
            let ref = storage?.reference(forURL: photoUrl)
            ref?.getData(maxSize: 500000, completion: { (data, error) in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                }
                else {
                    let image = UIImage(data: data!)
                    tempImages.append(image!)
                    self.entryImage.append(image!)
                    self.editImageCollectionView.reloadData()
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectCover", let dest = segue.destination as? SelectEntryCoverViewController {
            dest.delegate = self
        }
    }
}




extension EditEntryViewController:  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // If finished picking image, add the image picked to the entry image array, and reload to display
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {return}
        dismiss(animated: true, completion: nil)
        entryImage.append(image)
        editImageCollectionView.reloadData()
    }
    
    //Styling the Colelction View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        entryImage.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       let cell = editImageCollectionView.dequeueReusableCell(withReuseIdentifier: "editImageCell", for: indexPath) as! EditImageCollectionViewCell
        cell.imageView.image = entryImage[indexPath.row]
        cell.delegate = self
        cell.cellIndex = indexPath.row
        return cell
    }
    
    
    //sets the size of each cell so that 2 cells can fit on each row perfectly with spaces
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numItemsPerRow = 2
        let spaceBetweenCells = 10
        
        let width = (editImageCollectionView.frame.width - CGFloat(numItemsPerRow * spaceBetweenCells)) / CGFloat(numItemsPerRow)
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
}
