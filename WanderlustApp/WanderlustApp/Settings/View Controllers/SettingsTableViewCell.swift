//
//  SettingsTableViewCell.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/18/20.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    /// Current user setting
    @IBOutlet weak var settingDataLabel: UILabel!
    
    /// Name of the setting
    @IBOutlet weak var settingNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
