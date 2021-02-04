//
//  AnnotationCalloutView.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/21/20.
//

import UIKit
import MapKit
class AnnotationCalloutView: UIView {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    var annotation:CustomAnnotation!
    var delegate: UIViewController!
    
    // When edit is pressed it brings the user to the edit entry page with the
    @IBAction func edit(_ sender: Any) {
        delegate.performSegue(withIdentifier: "fromEditBtn", sender: self)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

}
