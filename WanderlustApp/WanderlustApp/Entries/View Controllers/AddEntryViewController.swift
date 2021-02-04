//
//  AddEntryViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/16/20.
//

import UIKit
import MapKit

class AddEntryViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notificationLabel: UILabel!
    var selectedAnnotation: CustomAnnotation!
    var tappedLocation:CLLocation!
    var tappedLocationString = ""
    var tempLocation = ""
    //array to hold all the annotations (used to add routes and maintain order)
    var annotationArray:[CustomAnnotation] = []
    var delegate:EditTripViewController!
    var entriesChanged:Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = delegate as EditTripViewController
        mapView.addAnnotations(vc.tripMapView.annotations)
        mapView.addOverlays(vc.tripMapView.overlays)
        mapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("EntriesChanged: \(entriesChanged)")

        UIView.animate(withDuration: 3.5, delay: 1.0, options: [.curveEaseOut], animations: {
            self.notificationLabel.alpha = 0.0
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let vc = delegate as EditTripViewController
        print("setting entryList in editTripVC")
        vc.entryList = annotationArray
        vc.entriesChanged = entriesChanged!
    }
        

    // Adds a CustomAnnotation to the map, given the location with the title set to title and subitle set to description
    func addAnnotation(location: CLLocationCoordinate2D, title: String, text: String, images: [UIImage], locationName:String, coverIndex:Int) {
        let annotation = CustomAnnotation(image: images, locationName: locationName, coordinate: location, title: title, text: text, order: annotationArray.count, coverIndex: coverIndex)
        self.mapView.addAnnotation(annotation)
        delegate.tripMapView.addAnnotation(annotation)
        self.addRoute(annotation: annotation)
    }

    // Add route to the mapView using the last annotation in the array as source and the annoation passed
    // in as parameter
    func addRoute(annotation: CustomAnnotation) {
        annotationArray.append(annotation)
        let coordinates: [CLLocationCoordinate2D] = self.annotationArray.map({
            CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        })
        
        let aPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        mapView.addOverlay(aPolyline)
        delegate.tripMapView.addOverlay(aPolyline)
        mapView.setVisibleMapRect(aPolyline.boundingMapRect, animated: true)
        delegate.tripMapView.setVisibleMapRect(aPolyline.boundingMapRect, animated: true)
        let midPoint = calculateMidPoint()
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: midPoint[0], longitude: midPoint[1]), span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)), animated: true)
        delegate.tripMapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: midPoint[0], longitude: midPoint[1]), span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)), animated: true)
    }
    
    func calculateMidPoint() ->[Double] {
        let midLatitude = self.annotationArray.reduce(0.0) {
            return ($0 + $1.coordinate.latitude)
        } / Double(self.annotationArray.count)
        
        let midLongitude = self.annotationArray.reduce(0.0) {
            return ($0 + $1.coordinate.longitude)
        } / Double(self.annotationArray.count)
        
        print("Calculated midpoint: (\(midLatitude), \(midLongitude))")
        
        return [midLatitude, midLongitude]
    }
    
    // # Long press gesture recognizor when you click the map.
    // # In here the location of the tap is recorded and is converted to coordinates by mapview.
    // # Then We use GLGeocoder to get the address of this location tapped by us.
    // # Then We initialize the segue to the edit entry view controller
    @objc func longTap(sender: UIGestureRecognizer){
        //makes sure that the long press is the initial one
        if sender.state == .began {
            
            //tappedlocation on the map view is converted to coordinates
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            
            //.reverseGeocodeLocation is used to convert from coordinate to addresss
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: locationOnMap.latitude, longitude: locationOnMap.longitude)
            geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                    placemarks, error -> Void in
                    // Place details
                    guard let placeMark = placemarks?.first else { return }
                
                    // Street address
                    if let street = placeMark.name {
                        self.tappedLocationString = "\(self.tappedLocationString)\(street) "
                    }
                    // City
                    if let city = placeMark.locality {
                        self.tappedLocationString = "\(self.tappedLocationString) \(city)"
                    }
                    // providence
                    if let providence = placeMark.administrativeArea {
                        self.tappedLocationString = "\(self.tappedLocationString), \(providence) "
                    }
                    // Country
                    if let country = placeMark.country {
                        self.tappedLocationString = "\(self.tappedLocationString) \(country) "
                    }
                
                //RACE CONDITION!!!!!
                self.performSegue(withIdentifier: "goEdit", sender: self)
            })
        }
    }
    
    
    // Edit entry will do different things depending on whether the 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goEdit", let dest = segue.destination as? EditEntryViewController {
            dest.delegate = self
            dest.initialString = self.tappedLocationString
            dest.entriesChanged = self.entriesChanged
            self.tempLocation = self.tappedLocationString
            self.tappedLocationString = ""
            
        }
        
        if segue.identifier == "fromEditBtn", let dest = segue.destination as? EditEntryViewController {
            dest.delegate = self
            let annotation = self.selectedAnnotation
            dest.initialString = annotation?.locationName
            dest.entryImage = annotation!.images
            dest.initialTitle = annotation?.title!
            dest.initialDescription = annotation?.text!
            dest.currentAnnotation = annotation
            dest.addNew = false
            dest.mapView = self.mapView
        }
    }
}


// Conforming to mapview functions
extension AddEntryViewController: MKMapViewDelegate {
    
//    // Configure the route properties
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
//        render.strokeColor = .blue
//        return render
//    }
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
            //view.imageView.image = currAnnotation.images[currAnnotation.coverPhotoIndex!]
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
        let newView = view.detailCalloutAccessoryView as! AnnotationCalloutView
        newView.nameLabel.text = self.selectedAnnotation.text
        print("calling mapvivew func in addEntryVC")
        //newView.imageView.image = self.selectedAnnotation.images[self.selectedAnnotation.coverPhotoIndex!]
        print("accessing coverPhoto: \(selectedAnnotation.coverPhoto)")
        if let coverPhotoUrl = selectedAnnotation.coverPhoto{
            let ref = storage?.reference(forURL: coverPhotoUrl)
                        ref?.getData(maxSize: 500000, completion: { (data, error) in
                            if let error = error {
                                print("Error downloading image: \(error.localizedDescription)")
                            }
                            else {
                                let image = UIImage(data: data!)
                                newView.imageView.image = image
                            }
                        })
        } else {
            newView.imageView.image = self.selectedAnnotation.images[self.selectedAnnotation.coverPhotoIndex!]
        }
        view.detailCalloutAccessoryView = newView
    }
}
