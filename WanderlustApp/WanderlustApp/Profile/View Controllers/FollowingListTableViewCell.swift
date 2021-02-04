//
//  FollowingListTableViewCell.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/16/20.
//

import UIKit

class FollowingListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var unfollowButton: UIButton!
    
    var delegate:FollowingManagement? = nil
    var followingRow:Int = 0
    
    override func awakeFromNib() {
           super.awakeFromNib()
       }
       
       override func layoutSubviews() {
           super.layoutSubviews()
           cellLayout()
       }
       
       override func setSelected(_ selected: Bool, animated: Bool) {
           super.setSelected(selected, animated: animated)
       }
       
       func cellLayout() {
           unfollowButton.translatesAutoresizingMaskIntoConstraints = false
           unfollowButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
           unfollowButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true

       }

    @IBAction func unfollowButtonPressed(_ sender: Any) {
        self.delegate?.unfollow(followingRow: self.followingRow)
    }
}
