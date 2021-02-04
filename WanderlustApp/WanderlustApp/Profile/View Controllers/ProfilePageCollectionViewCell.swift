//
//  ProfilePageCollectionViewCell.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/17/20.
//

import UIKit
import FirebaseUI

class ProfilePageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var tripCoverPhoto: UIImageView!
    @IBOutlet weak var tripName: UIButton!
        
    func setTripName(name: String) {
        tripName.setTitle(name, for: .normal)
        tripName.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        tripName.isUserInteractionEnabled = false
    }
    
    func setTripCoverPhoto(photo: String, cache: NSCache<NSString, UIImage>? = nil) {
        if let cache = cache, let imageFromCache = cache.object(forKey: photo as NSString) {
            self.tripCoverPhoto.image = imageFromCache
        }
        else {
            let imageRef = storage?.reference(forURL: photo)
                imageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    let image = UIImage(data: data!)
                    if let cache = cache {
                        cache.setObject(image!, forKey: photo as NSString)
                    }
                    self.tripCoverPhoto.image = image
                }
            }
        }
 
}
// extension to create a UIImage filled with a specified color
public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
    let rect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    color.setFill()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    guard let cgImage = image?.cgImage else { return nil }
    self.init(cgImage: cgImage)
  }
}

