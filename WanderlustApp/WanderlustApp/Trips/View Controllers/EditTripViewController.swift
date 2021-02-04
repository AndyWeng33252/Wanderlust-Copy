//
//  EditTripViewController.swift
//  WanderlustApp
//
//  Created by Hudson  Tran on 10/18/20.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore


// View Controller to edit the trip
class EditTripViewController: UIViewController{

    @IBOutlet weak var editEntryOrderButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tripNameTextField: UITextField!
    @IBOutlet weak var tripMapView: MKMapView!
    @IBOutlet weak var tripTitleTextField: UITextField!
    @IBOutlet weak var notificationLabel: UILabel!
    var tripInfoDelegate:TripInfoViewController!
    var tripID:String?
    var user:FirebaseAuth.User?
    var tripCover:String?
    var loadedToEdit = false
    var tripRoute:MKOverlay?
    var tappedLocationString = ""
    var selectedAnnotation: CustomAnnotation?
    var tripCoverPhoto = UIImage(named: "entryPlaceholder")
    
    var deleteList: [CustomAnnotation] = []
    var entryList:[CustomAnnotation] = [] {
        didSet {
            if entryList.count > 0 {
                print("EntryList:\(entryList)")
                createPolyline()
                tripMapView.showAnnotations(tripMapView.annotations, animated: true)
            }
        }
    }
    
    var emptyFieldAlert = UIAlertController(title: "Empty Field", message: "A trip must contain at least one entry, a cover photo, and a title.", preferredStyle: .alert)
    
    var editOrderAlert = UIAlertController(title: "Add an Entry", message: "To edit the order, there must be at least one entry in the trip.", preferredStyle: .alert)
    
    var savedSuccessfulAlert = UIAlertController(title: "Trip Saved Successfully", message: "", preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = Auth.auth().currentUser
        tripMapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        tripMapView.addGestureRecognizer(longTapGesture)
        if tripID != nil {
            loadCoverPhoto()
        }
        
        savedSuccessfulAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in self.resetViewController()}))
        editOrderAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        emptyFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ///When ciew appears recreate the map with the newest annotations and routes
        let entryIdList:[String] = entryList.map{
            $0.entryID!
        } ?? []
        if tripID != nil && !loadedToEdit {
            loadEntries()
            loadedToEdit = true
        }
        if tripRoute != nil {
            tripMapView.removeOverlays(tripMapView.overlays)
            createPolyline()
        }
    }
    
    
    ///Loads the trips cover photo so it'll be avaliable for the user to change later on
    func loadCoverPhoto(){
        let docRef = db?.collection("trips").document(tripID!)
        docRef?.getDocument(completion: {(document, error) in
            if let document = document, document.exists, let tripData = document.data() {
                let imageRef = storage?.reference(forURL: tripData["coverPhoto"] as! String)
                imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("error")
                        return
                    }
                    self.tripCoverPhoto = UIImage(data: data!)
                }
            }
        })
    }
    
    // Loads the data for each entry on the map
    func loadEntryData(entryIds:[String]) {
        // Temporary container for custom annotations
        // When all entries are loaded, update the list
        var tempAnnotations:[CustomAnnotation] = [] {
            didSet {
                if tempAnnotations.count == entryIds.count {
                    tempAnnotations.sort(by: {$0.order! < $1.order!})
                    self.entryList = tempAnnotations
                }
            }
        }
        for entryId in entryIds {
            let entryRef = db?.collection("entries").document(entryId)
            entryRef?.getDocument(completion: { (document, error) in
                if let error = error {
                    print("Error occured when retrieving entry data: \(error.localizedDescription)")
                    return
                }
                
                let result = Result {
                  try document?.data(as: Entry.self)
                }
                switch result {
                case .success(let entry):
                    if let entry = entry {
                        ///Create a custom annotaion object for each entry so it can be displayed on the map
                        let annotation = CustomAnnotation(entry: entry)
                        let urls = document?.data()!["mediaList"] as! [String]
                        annotation.numPhotos = urls.count
                        annotation.imageUrls = urls
                        annotation.tripID = document?.data()!["tripID"] as! String
                        annotation.coverPhoto = document?.data()!["coverPhoto"] as! String
                        
                        ///Load Entry Cover Photo
                        let imageRef = storage?.reference(forURL: document?.data()!["coverPhoto"] as! String)
                        imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("error")
                                return
                            }
                            annotation.coverPhotoImage = UIImage(data: data!)
                        }
                        
                        var doneCounter = 0 {
                            didSet {
                                if doneCounter == urls.count {
                                    self.tripMapView.addAnnotation(annotation)
                                    tempAnnotations.append(annotation)
                                }
                            }
                        }
                        
                        ///Load images for this entry
                        for image in urls as! [String] {
                            let imageRef = storage?.reference(forURL: image)
                            imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                                if let error = error {
                                    print("error")
                                    return
                                }
                                annotation.images.append(UIImage(data: data!)!)
                                doneCounter = doneCounter + 1
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                case .failure(let error):
                    print("Error decoding entry: \(error)")
                }
            })
        }
    }
    
    // Loads the entries from the given trip into view
    func loadEntries() {
        let docRef = db?.collection("trips").document(tripID!)
        docRef?.getDocument(completion: {(document, error) in
            if let document = document, document.exists,
               let tripData = document.data() {
                // set the Trip title field
                self.tripNameTextField.text = tripData["tripName"] as? String
                if let entries = tripData["entries"] as? [String] {
                    self.loadEntryData(entryIds: entries)
                }
            }
        })
    }
    
    /// Draw a line connecting each of the pins
    func createPolyline() {
        let coordinates: [CLLocationCoordinate2D] = self.entryList.map({
            CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        })
        tripRoute = MKPolyline(coordinates: coordinates, count: coordinates.count)
        tripMapView.addOverlay(tripRoute!)
    }
    
    // Adds a CustomAnnotation to the map, given the location with the title set to title and subitle set to description
    func addAnnotation(location: CLLocationCoordinate2D, title: String, text: String, images: [UIImage], locationName:String, coverPhotoURL:String, coverPhotoImage:UIImage) {
        let annotation = CustomAnnotation(image: images, locationName: locationName, coordinate: location, title: title, text: text, order: entryList.count)
        annotation.coverPhoto = coverPhotoURL
        annotation.coverPhotoImage = coverPhotoImage
        self.tripMapView.addAnnotation(annotation)
        entryList.append(annotation)
        tripMapView.selectAnnotation(annotation, animated: true)
    }
    
    ///Removes a CustomAnnotation in the map and from the list of entries we keep
    func deleteAnnotation(annotation : CustomAnnotation) {
        //remove from map
        self.tripMapView.removeAnnotation(annotation)
        self.tripMapView.removeOverlays(self.tripMapView.overlays)
        //remove from entry list
        var index = 0;
        for entry in entryList {
            if entry.entryID == annotation.entryID {
                entryList.remove(at: index)
                deleteList.append(annotation)
                break
            }
            index += 1
        }
    }
    
    // Checks to present an alert if the trip has no entries
    @IBAction func editOrderButtonPressed(_ sender: Any) {
        if entryList.count == 0 {
            present(editOrderAlert, animated: true, completion: nil)
        }
    }
    
    // Handles the saving of a new trip/ update of an existing trip
    @IBAction func saveButtonPressed(_ sender: Any) {
        self.view.endEditing(true)
        
        // checks to see if anything is empty
        if entryList.count == 0 || tripNameTextField.text == "" || tripCoverPhoto == UIImage(named: "entryPlaceholder") {
            present(emptyFieldAlert, animated: true, completion: nil)
            return
        }
        
        ///Once this tempEntryList is the same as the entry list count then we are good to save everything and pop
        var tempEntryList:[CustomAnnotation] = [] {
            didSet {
                if tempEntryList.count == entryList.count {
                    tempEntryList.sort(by: {$0.order! < $1.order!})
                    
                    let entryIdList:[String] = entryList.map{
                        $0.entryID!
                    }

                    // Need to create new trip
                    let userRef = db?.collection("users").document(user!.uid)
                    userRef?.getDocument { (document, error) in
                        if let document = document, let userData = document.data() {
                            // new trip case, need to create a new one and add everything to it
                            if self.tripID == nil {
                                // add new trip to trip page
                                if let newTrip = db?.collection("trips").addDocument(data:
                                    ["tripName" : self.tripNameTextField.text!,
                                    "entries" : entryIdList,
                                    "userID" : self.user!.uid,
                                    "timestamp" : FieldValue.serverTimestamp()
                                    ]) {
                                    
                                    // update tripsArray on current user
                                    var currentTrips = userData["trips"] as! [String]
                                    currentTrips.append(newTrip.documentID)
                                    userRef?.updateData(["trips" : currentTrips])
                                    self.updateTripID(entryIdList: entryIdList, tripID: newTrip.documentID)
                                    
                                    /// update trip cover in firebase firestore
                                    self.uploadTripCoverPhoto(tripID: newTrip.documentID) {
                                        newTrip.setData(["coverPhoto" : self.tripCover], merge: true)
                                    }
                                    self.present(self.savedSuccessfulAlert, animated: true, completion: nil)
                                }
                                
                            // update existing trip
                            } else {
                                if let updateTrip = db?.collection("trips").document(self.tripID!) {
                                    updateTrip.updateData(
                                    [
                                    "tripName" : self.tripNameTextField.text!,
                                    "entries" : entryIdList
                                    ]) {_ in
                                        // Everything else happens in completion handler
                                        
                                        /// update trip cover in firebase firestore
                                        self.uploadTripCoverPhoto(tripID: self.tripID!) {
                                            updateTrip.updateData(["coverPhoto" : self.tripCover])
                                        }
                                        self.updateTripID(entryIdList: entryIdList, tripID: self.tripID!)
                                        print("updated trip successfully")
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Regardless of if entries are changed, update the order and title
        updateTripInfo()
        
        // Delete the entries from firebase
        for entry in deleteList {
            print("delete \(entry.entryID)")
            entry.deleteEntry()
        }
        
        // Adds the entries to firebase
        for entry in entryList {
            entry.addEntryToFirestore(completion: {
                tempEntryList.append(entry)
                print("tempEntryList count: \(tempEntryList.count)")
            })
        }
                
    }

    ///Function used to update the trip cover photo in firebase storage
    func  uploadTripCoverPhoto(tripID: String, completion: (() -> Void)?) {
        guard let imageData = tripCoverPhoto?.jpegData(compressionQuality: 0.2) else {return}
        // Create a reference to the file you want to upload
        let storageRef = storage!.reference()
        let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/tripCovers/\(tripID)")
        // Upload the file to the path imageRef
        let uploadTask = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
          // You can also access to download URL after upload.
            imageRef.downloadURL { (url, error) in
                if let downloadURL = url{
                    self.tripCover = downloadURL.absoluteString
                    completion!()
                }
               
            }
        }
    }
    
    // Updates tripInformation regardless of entry changes, the things that are always updates includes: tripname, entries, and trip cover
    func updateTripInfo() {
        
        var tempEntryList:[CustomAnnotation] = [] {
            didSet{
                if tempEntryList.count == tripMapView.annotations.count {
                    tempEntryList.sort(by: {$0.order! < $1.order!})
                    let entryIdList:[String] = entryList.map {
                        $0.entryID!
                    }
                    
                    if tripID != nil {
                        if let updateTrip = db?.collection("trips").document(self.tripID!) {
                            updateTrip.updateData(
                                [
                                "tripName" : self.tripNameTextField.text!,
                                 "entries" : entryIdList
                                ])
                            self.uploadTripCoverPhoto(tripID: self.tripID!) {
                                updateTrip.updateData(["coverPhoto" : self.tripCover])
                            }
                        }
                        // Calls the updateTripID function to make sure each entry has an updated tripID
                        updateTripID(entryIdList: entryIdList, tripID: tripID!)
                    }
                    print("updated tripID")
                }
            }
        }
        
        for annotation in entryList {
            tempEntryList.append(annotation)
        }
    }

    // Updates tripID field for each entry
    func updateTripID(entryIdList: [String], tripID : String) {
        var tempEntryList:[String] = [] {
            didSet {
                if(tempEntryList.count == entryIdList.count) {
                    updateEntryOrder(entryIdList: entryIdList, newTripId: tripID)
                }
            }
        }
        
        for id in entryIdList {
            db?.collection("entries").document(id).updateData(
                ["tripID" : tripID]) { _ in
                    tempEntryList.append(id)
                
            }
        }
        for entry in entryList {
            entry.tripID = tripID
        }
    }
    
    // Updates orderEntry field in each entry
    func updateEntryOrder(entryIdList: [String], newTripId: String) {
        var tempEntryList:[Int] = [] {
            didSet {
                if(tempEntryList.count == entryIdList.count) {
                    self.tripID = newTripId
                }
            }
        }
        for orderIndex in 0...entryIdList.count - 1 {
            db?.collection("entries").document(entryIdList[orderIndex]).updateData(
                ["entryOrder" : orderIndex]) { _ in
                tempEntryList.append(orderIndex)
            }
        }
    }
    
    // # Long press gesture recognizor when you click the map.
    // # In here the location of the tap is recorded and is converted to coordinates by mapview.
    // # Then We use GLGeocoder to get the address of this location tapped by us.
    // # Then We initialize the segue to the edit entry view controller
    @objc func longTap(sender: UIGestureRecognizer){
        //makes sure that the long press is the initial one
        if sender.state == .began {
            
            //tappedlocation on the map view is converted to coordinates
            let locationInView = sender.location(in: tripMapView)
            let locationOnMap = tripMapView.convert(locationInView, toCoordinateFrom: tripMapView)
            
            //.reverseGeocodeLocation is used to convert from coordinate to addresss
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: locationOnMap.latitude, longitude: locationOnMap.longitude)
            geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in
                
                // Place details
                guard let placeMark = placemarks?.first else { return }
                let mkPlacemark = MKPlacemark(placemark: placeMark)
                let address = mkPlacemark.title!
                self.tappedLocationString = address
                
                self.performSegue(withIdentifier: "goEdit", sender: self)
            })
        }
    }
    
    // A function that instantiates a new EditTripVC and jumps to Newsfeed
    // This is only called when a new trip is created, otherwise the VC is just popped
    func resetViewController() {
        let vc = storyboard!.instantiateViewController(identifier: "EditTrip") as! EditTripViewController
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    
    ///Function used to pass needed information for segues from this edit trip screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editOrderSegue" {
            if let dest = segue.destination as? EditEntryOrderViewController {
                dest.delegate = self
                dest.entryList = self.entryList
                if tripRoute != nil {
                    tripMapView.removeOverlay(tripRoute!)
                }
            }
        }
        else if segue.identifier == "goEdit", let dest = segue.destination as? EditEntryViewController {
            dest.delegate = self
            dest.initialLocation = self.tappedLocationString
            self.tappedLocationString = ""
            
        }
        
        else if segue.identifier == "fromEditBtn", let dest = segue.destination as? EditEntryViewController {
            dest.delegate = self
            let annotation = self.selectedAnnotation
            dest.initialLocation = annotation?.locationName
            dest.entryImage = annotation!.images
            dest.initialTitle = annotation?.title!
            dest.initialDescription = annotation?.text!
            dest.currentAnnotation = annotation
            dest.addNew = false
            dest.mapView = self.tripMapView
        }
        
        else if segue.identifier == "goSearch", let dest = segue.destination as? SeachLocationViewController {
            dest.delegate = self
        }
        
        else if segue.identifier == "selectPhoto", let dest = segue.destination as? SelectTripCoverViewController {
            dest.delegate = self
        }
        

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

// MARK: MKMapViewDelegate Implementation

// Extension of EditTripViewController to handle the MapView
extension EditTripViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if(overlay is MKPolyline) {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            polylineRender.lineWidth = 5
            
            return polylineRender
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // Adds a view for the annotations when clicked on
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is CustomAnnotation else { return nil }
        let currAnnotation = annotation as! CustomAnnotation
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: currAnnotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
            
            ///Creates view and fill in the view with the appropraite information like image, title and description
            let view = Bundle.main.loadNibNamed("AnnotationCalloutView", owner: self, options: nil)![0] as! AnnotationCalloutView
            view.delegate = self
            view.nameLabel.text = currAnnotation.text
            if let coverPhotoUrl = currAnnotation.coverPhoto{
                let ref = storage?.reference(forURL: coverPhotoUrl)
                            ref?.getData(maxSize: 500000, completion: { (data, error) in
                                if let error = error {
                                    print("Error downloading image: \(error.localizedDescription)")
                                }
                                else {
                                    let image = UIImage(data: data!)
                                    view.imageView.image = image
                                }
                            })
            }
            view.translatesAutoresizingMaskIntoConstraints = false
            var newFrame = view.frame
            newFrame.size.width = 1000
            newFrame.size.height = 1000
            view.frame = newFrame
            annotationView!.detailCalloutAccessoryView = view
            
        }
        
        else {
            annotationView!.annotation = currAnnotation
        }
        return annotationView
    }
    
    // Keep track of the last selected Annotation (so when edit pressed we know which annoation to pass data for)
    // Used to refresh the annoations's view when changes are saved
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as! CustomAnnotation
        
        ///Creates view and fill in the view with the appropraite information like image, title and description
        let newView = view.detailCalloutAccessoryView as! AnnotationCalloutView
        newView.nameLabel.text = selectedAnnotation!.text
        if let coverPhotoUrl = selectedAnnotation!.coverPhoto{
            let ref = storage?.reference(forURL: coverPhotoUrl)
                        ref?.getData(maxSize: 500000, completion: { (data, error) in
                            if let error = error {
                                print("Error downloading image: \(error.localizedDescription)")
                            }
                            else {
                                let image = UIImage(data: data!)
                                self.selectedAnnotation?.coverPhotoImage = image
                                newView.imageView.image = image
                            }
                        })
        }
        view.detailCalloutAccessoryView = newView
    }
}
