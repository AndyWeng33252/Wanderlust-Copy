//
//  SelectEntryCoverViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 12/5/20.
//

import UIKit

class SelectEntryCoverViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var coverImage: UIImageView!
    var delegate: EditEntryViewController!
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.allowsEditing = true
        picker.delegate = self
        
        if let image = delegate.entryCoverPhoto {
            coverImage.image = image
        }
    }
    
    // when choose photo is clicked, 
    @IBAction func choosePhotoButton(_ sender: Any) {
        self.present(picker, animated: true, completion: nil)
    }
    
    // after save, update the edit entries cover photo then pop this vc
    @IBAction func saveButton(_ sender: Any) {
        delegate.entryCoverPhoto = coverImage.image
        self.navigationController?.popViewController(animated: true)
    }
    
    // after picking the image, supdate the coverImage displayed
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {return}
        dismiss(animated: true, completion: nil)
        coverImage.image = image
    }

}
