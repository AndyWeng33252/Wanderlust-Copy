//
//  SelectTripCoverViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 11/21/20.
//

import UIKit

class SelectTripCoverViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var coverImage: UIImageView!
    var delegate: EditTripViewController!
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.allowsEditing = true
        picker.delegate = self
        
        if let image = delegate.tripCoverPhoto {
            coverImage.image = image
        }
    }
    
    /// when choose photo is clicked,
    @IBAction func choosePhotoButton(_ sender: Any) {
        self.present(picker, animated: true, completion: nil)
    }
    
    /// after save pressed, update the edit trip trip cover photo then pop this vc
    @IBAction func saveButton(_ sender: Any) {
        delegate.tripCoverPhoto = coverImage.image
        self.navigationController?.popViewController(animated: true)
    }
    
    /// after picking the image, supdate the coverImage displayed
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {return}
        dismiss(animated: true, completion: nil)
        coverImage.image = image
    }
}
