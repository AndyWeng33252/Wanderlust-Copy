//
//  SettingsViewController.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/18/20.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    /// Names for each section
    let headerTitles = ["Account", "Privacy and Security"]
    
    /// Names of the settings per section
    let settings = [["Username", "Email", "Bio"], ["Private Account", "Password"]]
    
    /// Current user
    var user:FirebaseAuth.User?
    
    /// Stores user data
    var userData:[[Any?]] = [["", "", ""], [true, "******"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserData(reload: false)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadUserData(reload: true)
    }
    
    
    /// Loads user data form Firebase
    /// - Parameter reload: True to reload table view, false to not
    func loadUserData(reload: Bool) {
        user = Auth.auth().currentUser
        if let user = user {
            let docRef = db?.collection("users").document(user.uid)
            docRef?.getDocument(completion: { (document, error) in
                if let document = document,
                   let data = document.data() {
                    let privacy = data["public"]
                    let bio = data["bio"] ?? "Placeholder Bio"
                    let username = data["username"] ?? "Username"
                    self.userData = [[username, user.email, bio], [privacy, "******"]]
                    if reload {
                        self.tableView.reloadData()
                    }
                }
            })
        }
        else {
            print("No user signed in")
        }
    }
    
    // Pass the setting name, user data for setting, and set the screen title for the edit acount settings screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editAccountSegueIdentifier" {
            let otherVC = segue.destination as? EditAccountSettingsViewController
            let cell = sender as! SettingsTableViewCell
            otherVC?.settingName = cell.settingNameLabel.text!
            otherVC?.data = cell.settingDataLabel.text!
            otherVC?.navTitle = "Edit \(cell.settingNameLabel.text!)"
        }
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: tableView.bounds.size.width, height: 30))
        if section < headerTitles.count {
            label.text = self.headerTitles[section]
                    
        }
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
        headerView.backgroundColor = UIColor(red: CGFloat(152.0/255.0), green: CGFloat(203.0/255.0), blue: CGFloat(255.0/255.0), alpha: 1.0)
        headerView.addSubview(label)
            return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerTitles.count
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(userData)
        // Hard coded to make first row of Privacy and Security section to be the account privacy cell
        if indexPath.section == tableView.numberOfSections - 1 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountPrivacyCell", for: indexPath as IndexPath) as! AccountPrivacyTableViewCell
            let isPrivate = userData[indexPath.section][indexPath.row]
                        
            cell.titleLabel.text = "Private Account"
            cell.privacySwitch.isOn = !(isPrivate as! Bool)
            cell.privacySwitch.translatesAutoresizingMaskIntoConstraints = false
            cell.privacySwitch.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10).isActive = true
            cell.privacySwitch.topAnchor.constraint(equalTo: cell.topAnchor, constant: 5).isActive = true
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath as IndexPath) as! SettingsTableViewCell
        let setting = settings[indexPath.section][indexPath.row]
        let data = userData[indexPath.section][indexPath.row]
        
        cell.settingNameLabel.text = setting
        cell.settingDataLabel.text = data as? String
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Prevent the account privacy cell from being selectable
        if indexPath.section == tableView.numberOfSections - 1 && indexPath.row == 0 {
            return
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! SettingsTableViewCell
        tableView.deselectRow(at: indexPath, animated: true)
        
        if cell.settingNameLabel.text == "Password" {
            performSegue(withIdentifier: "editPasswordSegueIdentifier", sender: cell)
        }
        else {
            performSegue(withIdentifier: "editAccountSegueIdentifier", sender: cell)
        }
    }
}
