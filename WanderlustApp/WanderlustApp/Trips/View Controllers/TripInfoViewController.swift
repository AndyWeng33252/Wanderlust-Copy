//
//  TripInfoViewController.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/20/20.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class TripInfoViewController: UIViewController {
    
    /// Map view
    @IBOutlet weak var mapView: MKMapView!
    
    /// favorite button
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    
    /// settings button
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    /// Label that displays trip title
    @IBOutlet weak var tripTitleLabel: UILabel!
    
    /// Label for the timestamp
    @IBOutlet weak var tripTimestampLabel: UILabel!
    
    /// Button that displays name of user that created the trip
    @IBOutlet weak var userNameButton: UIButton!
    
    /// Logged in user
    var user:FirebaseAuth.User?
    
    /// is this trip is one of the user's favorites
    var favorite = false
    
    /// Static trip id for testing
    var tripId: String = "" {
        didSet {
            print("Trip id is \(tripId)")
        }
    }

    
    /// List of customAnnotations to render mapView
    var customAnnotations:[CustomAnnotation] = [] {
        didSet {
            if customAnnotations.count > 0 {
                print(customAnnotations)
                createPolyline()
                mapView.showAnnotations(mapView.annotations, animated: true)
            }
        }
    }

    /// Current trip
    var trip:Trip? {
        didSet {
            tripTitleLabel.text = trip?.tripName
        }
    }
    
    /// User that created the trip
    var tripUser:User? {
        didSet {
            print("Trip user is \(tripUser?.username ?? "empty")")
            userNameButton.setTitle(tripUser?.username, for: .normal)
        }
    }
    
    /// Id of selected entry
    var entryId:String?
    
    /// Recognize callout tap
    var tapGestureRecognizer:UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
                
        self.tripTitleLabel.font = UIFont.boldSystemFont(ofSize: 40)
        self.tripTitleLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadTripData()
        print(self.mapView.annotations)
        print("Custom Annotations: \(customAnnotations)")
    }
    
    /// Load trip data from database
    func loadTripData() {
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.customAnnotations.removeAll()
        user = Auth.auth().currentUser
        if let _ = user {
            let docRef = db?.collection("trips").document(tripId)
            docRef?.getDocument(completion: { (document, error) in
                if let document = document,
                   document.exists,
                   let tripData = document.data(){
                    self.trip = Trip(tripName: (tripData["tripName"] as? String)!, coverPhoto: (tripData["coverPhoto"] as? String)!, userId: (tripData["userID"] as? String)!, timestamp: (tripData["timestamp"] as? Timestamp)!, entries: (tripData["entries"] as? [String]) ?? nil)
                    self.trip?.tripId = document.documentID
                    let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMM dd, yyyy"
                    self.tripTimestampLabel.text = dateFormatter.string(from: (self.trip?.timestamp?.dateValue()) as! Date)
                    self.favorite = ((currentUser?.favorites?.contains((self.trip?.tripId)!))!)
                    self.favoriteButton.image =  UIImage(systemName: self.favorite ? "heart.fill" : "heart")
                    fetchUser(uid: self.trip!.userId) { [self]
                        (user) in
                        self.tripUser = user
                        if self.tripUser?.uid != self.user?.uid {
                            self.navigationItem.rightBarButtonItem = nil
                            self.navigationItem.rightBarButtonItem = self.favoriteButton
                        } else {
                            self.navigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[1] = self.settingsButton
                            self.navigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[0] = self.favoriteButton
                        }
                    }
                    if let entryIds = tripData["entries"] as? [String] {
                        self.loadEntryData(entryIds: entryIds)
                    }
                }
            })
        }
        else {
            print("No user signed in")
        }
    }
    
    /// Load entry data from list of entry references
    func loadEntryData(entryIds:[String]) {
        print("Begin getting entries")
    
        // Temporary container for custom annotations
        // When all entries are loaded, update the list
        var tempAnnotations:[CustomAnnotation] = [] {
            didSet {
                if tempAnnotations.count == entryIds.count {
                    tempAnnotations.sort(by: {$0.order! < $1.order!})
                    self.customAnnotations = tempAnnotations
                }
            }
        }
        
        for entryId in entryIds {
            print("EntryID: \(entryId)")
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
                        let annotation = CustomAnnotation(entry: entry)
                        self.mapView.addAnnotation(annotation)
                        tempAnnotations.append(annotation)
                        print("Added \(String(describing: entry.locationName))")
                    } else {
                        print("Document does not exist")
                    }
                case .failure(let error):
                    print("Error decoding entry: \(error)")
                }
            })
        }

    }
    
    /// Add a pin on the map
    func addAnnotation(entry: Entry) {
        let pin = MKPointAnnotation()
        pin.title = entry.entryName
        pin.subtitle = entry.locationName
        pin.coordinate = CLLocationCoordinate2D(latitude: entry.coordinates!.latitude , longitude: entry.coordinates!.longitude)
        self.mapView.addAnnotation(pin)
    }
    
    /// Draw a line connecting each of the pins
    func createPolyline() {
        let coordinates: [CLLocationCoordinate2D] = self.customAnnotations.map({
            CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        })
        
        let aPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        mapView.addOverlay(aPolyline)
    }
    
    /// Add trip to favorites
    @IBAction func favoriteButtonPressed(_ sender: Any) {
        favorite = !favorite
        self.navigationItem.rightBarButtonItem?.buttonGroup?.barButtonItems[0].image = UIImage(systemName: favorite ? "heart.fill" : "heart")
        if favorite {
            addToUsersFavorites(tripId: tripId)
        } else {
            removeFromUsersFavorites(tripId: tripId)
        }
    }
    
    // Implements action sheet
    @IBAction func barButtonPressed(_ sender: Any) {
        let controller = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        let EditAction = UIAlertAction(title: "Edit",
                                         style: .default,
                                         handler: {
                                            (action) in
                                            let storyboard = UIStoryboard(name: "EditTrip", bundle: nil)
                                            let vc = storyboard.instantiateViewController(withIdentifier: "EditTrip") as! EditTripViewController
                                            vc.tripID = self.tripId
                                            vc.navigationItem.title = "Edit Trip"
                                                   self.navigationController?.pushViewController(vc, animated: true)
                                         })
        controller.addAction(EditAction)
        
        let deleteAction = UIAlertAction(title: "Delete",
                                         style: .destructive,
                                         handler: {
                                            (action) in
                                            self.sureToDelete()
                                         })
        
        controller.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                        style: .cancel,
                                        handler: nil)
        controller.addAction(cancelAction)

        present(controller, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProfilePageSegue" {
            let otherVC = segue.destination as? ProfilePageViewController
            print("SEGUE: \(trip?.userId ?? "trip user id is empty")")
            otherVC?.otherUserUid = trip?.userId
        }
        if segue.identifier == "EntryInfoSegue" {
            let otherVC = segue.destination as? EntryInfoViewController
            otherVC?.entryID = entryId
        }
    }
    
    /// Displays alert to confirm delete
    func sureToDelete() {
        let controller = UIAlertController(title: "Delete Trip",
                                            message: "Are you sure you want to delete?",
                                            preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete",
                                         style: .destructive,
                                         handler: {
                                            (action) in
                                            self.deleteTrip(tripId: self.tripId)})
        
        controller.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                        style: .cancel,
                                        handler: nil)
        
        controller.addAction(cancelAction)
        
        present(controller, animated: true, completion: nil)
    }
    
    func deleteTrip(tripId: String) {
        print("DELETING TRIPID: \(tripId)")
        fetchTrip(tripId: tripId) { trip in
            // delete all entries
            for entry in (trip?.entries)! {
                self.deleteEntry(entryId: entry)
            }
            // delete from users trip array
            var newTripArray = currentUser?.trips
            newTripArray = newTripArray?.filter { $0 != tripId }
            db!.collection("users").document((currentUser?.uid!)!).updateData([
                "trips": newTripArray

            ]) {
                (error:Error?) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
            //delete from collection
            db?.collection("trips").document(tripId).delete()
            
        }
    }
    
    func deleteEntry(entryId: String) {

        //delete from followers
        var followersUids = currentUser?.followers
        followersUids?.append((currentUser?.uid)!)
        for followerUid in followersUids! {
            db?.collection("users").document(followerUid).collection("newsfeed").document(entryId).delete()
        }
        
        fetchEntry(entryId: entryId) { entry in
            let storageRef = storage!.reference()
            for index in 0 ... (entry?.mediaList!.count)! {
                // Create a reference to the file you want to delete
                let imageRef = storageRef.child("/users/\((currentUser?.uid)!)/\(entryId)/image\(index)")

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
            //delete from entries collection
            db?.collection("/entries").document("\(entryId)").delete()
        }

    }
    
}

extension TripInfoViewController: MKMapViewDelegate {
    
    // Renders the route
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if(overlay is MKPolyline) {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            polylineRender.lineWidth = 5
            
            return polylineRender
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // Configures each annotation with a callout
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is CustomAnnotation else { return nil }
        let currAnnotation = annotation as! CustomAnnotation
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        annotationView = MKPinAnnotationView(annotation: currAnnotation, reuseIdentifier: identifier)
        annotationView!.canShowCallout = true
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
        
        view.editButton.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        var newFrame = view.frame
        newFrame.size.width = 1000
        newFrame.size.height = 1000
        view.frame = newFrame
        annotationView!.detailCalloutAccessoryView = view
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TripInfoViewController.calloutTapped))
        view.addGestureRecognizer(tapGestureRecognizer!)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        view.removeGestureRecognizer(tapGestureRecognizer!)
    }

    /// Segue to entry info when callout is tapped
    @objc func calloutTapped(sender:UITapGestureRecognizer) {
        guard let annotation = (sender.view as? MKAnnotationView)?.annotation as? CustomAnnotation else { return }
        entryId = annotation.entryID
        performSegue(withIdentifier: "EntryInfoSegue", sender: self)
        
    }
}
