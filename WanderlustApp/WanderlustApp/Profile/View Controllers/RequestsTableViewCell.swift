//
//  RequestsTableViewCell.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/16/20.
//

import UIKit

class RequestsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var denyButton: UIButton!
    
    var delegate:RequestManagement? = nil
    var requestRow:Int = 0
    
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
       acceptButton.translatesAutoresizingMaskIntoConstraints = false
       denyButton.translatesAutoresizingMaskIntoConstraints = false
       
       denyButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
       denyButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
       
       acceptButton.trailingAnchor.constraint(equalTo: denyButton.leadingAnchor, constant: -15).isActive = true
       acceptButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
   }
    

    @IBAction func acceptButtonPressed(_ sender: Any) {
        self.delegate?.acceptRequest(requestRow: requestRow)
    }

    @IBAction func denyButtonPressed(_ sender: Any) {
        self.delegate?.denyRequest(requestRow: requestRow)
    }
}
