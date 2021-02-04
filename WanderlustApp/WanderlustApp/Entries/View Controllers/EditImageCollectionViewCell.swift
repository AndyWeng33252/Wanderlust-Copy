//
//  EditImageCollectionViewCell.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/16/20.
//

import UIKit

class EditImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    var delegate:UIViewController!
    var cellIndex:Int!
    var confirmDelete = UIAlertController(title: "Delete", message: "Are you sure you want to delete?", preferredStyle: .alert)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        confirmDelete.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        // if confirm delete use the delegate to access the avalability to delete cells on the edit entry view controller's collection view
        confirmDelete.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(alert:UIAlertAction) in
            let vc = self.delegate as! EditEntryViewController
            vc.deleteImage(index: self.cellIndex)
        }))
        
    }
    
    // present the alert to make sure the user wants to delete photo for sure
    @IBAction func deleteImage(_ sender: Any) {
        delegate.present(confirmDelete, animated: true, completion: nil)
    }
    
}
