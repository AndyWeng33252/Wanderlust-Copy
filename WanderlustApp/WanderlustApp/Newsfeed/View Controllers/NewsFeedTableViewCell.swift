//
//  NewsFeedTableViewCell.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/15/20.
//

import UIKit

class NewsFeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var tripdesciption: UILabel!
    @IBOutlet weak var imageCollection: UICollectionView!
    var entry: CustomAnnotation!
    var index:IndexPath!
    var delegate:NewsFeedViewController!
    var photoList:[UIImage] = []
    var caption:String!
    var uid: String?
    
    @IBOutlet weak var date: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //circular progile image
        profileImage.layer.masksToBounds = true
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2
        
        // add segue when tapped on the profile picture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(gesture:)))
        profileImage.addGestureRecognizer(tapGesture)
        profileImage.isUserInteractionEnabled = true
        
        imageCollection.delegate = self
        imageCollection.dataSource = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}


// Extension for styling the collection view
extension NewsFeedTableViewCell: UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @objc func profileImageTapped(gesture: UIGestureRecognizer) {
        if (gesture.view as? UIImageView) != nil {
            self.delegate.pushProfilePage(postUid: self.uid!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollection.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! EntryImageCollectionViewCell
        cell.entryImage.image = photoList[indexPath.row]
        cell.caption.text = caption
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.selectedRow = index
        delegate.performSegue(withIdentifier: "toEntryInfo", sender: self)
    }
    
    //styling on the cells (size is the whole frame of the collection view)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imageCollection.frame.width, height:imageCollection.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ tableView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height)).cgPath

        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 1
        cell.layer.shadowOffset = .zero
        cell.layer.shadowRadius = 10

        cell.setNeedsLayout()
    }

}
        

