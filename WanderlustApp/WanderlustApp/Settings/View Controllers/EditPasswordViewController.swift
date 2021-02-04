//
//  EditPasswordViewController.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/18/20.
//

import UIKit
import FirebaseAuth

/// View controller for edit password screen
class EditPasswordViewController: UIViewController {
    
    /// Text field for current password
    @IBOutlet weak var currentPasswordTextField: UITextField!
    
    /// Text field for new password
    @IBOutlet weak var newPasswordTextField: UITextField!
    
    /// Text field to confirm the new password
    @IBOutlet weak var retypeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    /// Update password in Firebase
    /// - Parameter sender: Sender
    @IBAction func doneButtonPressed(_ sender: Any) {
        let user = Auth.auth().currentUser
        let email = user?.email
        if let currentPassword = currentPasswordTextField.text,
           let newPassword = newPasswordTextField.text,
           let retypePassword = retypeTextField.text {
            let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email!, password: currentPassword)

            // reauthenticate user before changing password
            user?.reauthenticate(with: credential) { result, error in
                if let error = error {
                    self.showEditPasswordError(error: error.localizedDescription)
                }
                else {
                    if newPassword != retypePassword {
                        self.showEditPasswordError(error: "Passwords don't match")
                    }
                    else {
                        Auth.auth().currentUser?.updatePassword(to: newPassword) { (error) in
                            if let error = error {
                                self.showEditPasswordError(error: error.localizedDescription)
                            }
                            else {
                                print("Password succesfully updated!")
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Show edit account error
    func showEditPasswordError(error: String) {
        let controller = UIAlertController(title: "Error updating password",
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
