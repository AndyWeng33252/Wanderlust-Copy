//
//  EntryInfoCollectionViewCell.swift
//  WanderlustApp
//
//  Created by Hudson  Tran on 10/20/20.
//

import UIKit
import FirebaseUI

class EntryInfoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var entryImage: UIImageView!
            
    func setImage(photo: String) {
        let ref = storage?.reference(forURL: photo)
        ref?.getData(maxSize: 500000, completion: { (data, error) in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
            }
            else {
                let image = UIImage(data: data!)
                self.entryImage.image = image
            }
        })
    }
}
