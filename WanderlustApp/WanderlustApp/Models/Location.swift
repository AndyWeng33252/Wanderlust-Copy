//
//  Location.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/20/20.
//

import MapKit

class Location: NSObject {
    let title: String?
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
       self.title = title
       self.name = locationName
       self.coordinate = coordinate
    }
}
