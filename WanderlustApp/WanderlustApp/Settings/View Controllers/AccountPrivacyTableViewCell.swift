//
//  AccountPrivacyTableViewCell.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/18/20.
//

import UIKit
import FirebaseAuth

/// Custom cell to toggle account privacy setting
class AccountPrivacyTableViewCell: UITableViewCell {
    /// TItle of cell
    @IBOutlet weak var titleLabel: UILabel!
    
    /// Switch to toggle privacy setting
    @IBOutlet weak var privacySwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    /// Update privacy setting using toggle
    @IBAction func switchToggled(_ sender: Any) {
        let privacy = privacySwitch.isOn
        db?.collection("users").document((currentUser?.uid)!).setData([
                "public": !privacy
            ], merge: true) { err in
                if let err = err {
                    print("Error updating account privacy: \(err.localizedDescription)")
                } else {
                    print("Account privacy sucessfully updated!")
                }
            }
       // }
    }
}
