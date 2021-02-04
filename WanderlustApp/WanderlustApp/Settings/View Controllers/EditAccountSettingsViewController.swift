//
//  EditAccountSettingsViewController.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/18/20.
//

import UIKit
import FirebaseAuth

/// View controller for editing account information
class EditAccountSettingsViewController: UIViewController {
    /// Label that displays the setting
    @IBOutlet weak var settingLabel: UILabel!
    
    /// Text field that allows user to edit setting
    @IBOutlet weak var textField: UITextField!
    
    /// Text view used to edit bio
    @IBOutlet weak var bioTextView: UITextView!
    
    /// Navigation bar
    @IBOutlet weak var navItem: UINavigationItem!
    
    /// Name of setting
    var settingName:String = ""
    
    /// Holds user data for given setting
    var data:String = ""
    
    /// Title of the screen
    var navTitle:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingLabel.text = settingName
        textField.text = data
        bioTextView.delegate = self
        navItem.title = navTitle
        
        // Set border for bio text view
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        bioTextView.layer.borderColor = borderColor.cgColor
        bioTextView.layer.borderWidth = 0.5
        bioTextView.layer.cornerRadius = 0.5
        
        // Toggle between bio edit view and default edit view for all the other account settings
        if settingLabel.text == "Bio" {
            bioTextView.isHidden = false
            textField.isHidden = true
            bioTextView.text = data
        }
        else {
            bioTextView.isHidden = true
            textField.isHidden = false
        }
    }
    
    // Save changed settings
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        if textField.text!.isEmpty {
            showEditAccountError(error: "Name cannot be empty")
        }
        else {
            if settingName == "Username" {
                let docRef = db!.collection("users").whereField("username", isEqualTo: textField.text).limit(to: 1)
                docRef.getDocuments { (querysnapshot, error) in
                    if error != nil {
                        print("Document Error: ", error!)
                    } else {
                        if let doc = querysnapshot?.documents, !doc.isEmpty {
                            // username exists
                            print("Username is present.")
                            self.showEditAccountError(error: "Username is taken. Please choose another.")
                        } else {
                            //username does not exist
                            self.changeSettingInFirestore(setting: self.settingName)
                        }
                    }
                }
                
            }
            if settingName == "Bio" {
                changeSettingInFirestore(setting: settingName)
            }
            if settingName == "Email" {
                changeEmail()
            }
        }
    }
    
    /// Change setting if it is stored in Firestore
    /// - Parameter setting: The setting to update
    func changeSettingInFirestore(setting: String) {
        let user = Auth.auth().currentUser
        if let user = user {
            let value = setting == "Bio" ? bioTextView.text! : textField.text!
            print("Updating \(setting) for user \(user.uid) to \(value)")
            db?.collection("users").document(user.uid).setData([
                setting.lowercased(): value
            ], merge: true) { err in
                if let err = err {
                    print("Error updating \(setting.lowercased()): \(err.localizedDescription)")
                    self.showEditAccountError(error: "\(err.localizedDescription)")
                } else {
                    print("\(setting) sucessfully updated!")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        else {
            print("No user signed in")
        }
    }
    
    /// Change email that is stored in Firebase Auth
    func changeEmail() {
        guard let email = textField.text,
              !email.isEmpty
        else {
            showEditAccountError(error: "Email field cannot be empty")
            return
        }
        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
            if let error = error {
                let errorCode:String = (error as NSError).userInfo["FIRAuthErrorUserInfoNameKey"] as! String
                
                // Reauthenticate if user has not signed in recently
                // TODO: Ask user to input credentials
                if errorCode == "FIRAuthErrorCodeRequiresRecentLogin" {
                    let user = Auth.auth().currentUser
                    let credential: AuthCredential = EmailAuthProvider.credential(withEmail: (user?.email)!, password: "1234567")

                    user?.reauthenticate(with: credential) { result, error  in
                      if let error = error {
                        self.showEditAccountError(error: error.localizedDescription)
                      }
                      else {
                        self.navigationController?.popViewController(animated: true)
                      }
                    }
                }
                else {
                    self.showEditAccountError(error: error.localizedDescription)
                }
            }
            else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // Show edit account error
    func showEditAccountError(error: String) {
        let controller = UIAlertController(title: "Error updating \(settingName)",
                                           message: error,
                                           preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: "OK",
                                           style: .default,
                                           handler: nil))

        present(controller, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
          self.view.endEditing(true)
      }
    
}

extension EditAccountSettingsViewController: UITextViewDelegate{
    
    // Prevent user from typing in bio text view if charater limit is reached
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return newText.count <= Bio.CHAR_LIMIT
    }
}
