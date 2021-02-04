//
//  ViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/5/20.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestoreSwift

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var signedIn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// make sure signed out
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // only perform this segue if the user has successfully signed in
        if(identifier == "loginToNewsfeedPageIdentifier") {
            return self.signedIn
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signUpSegueIdentifier" {
            let signUpVc = segue.destination as! SignUpViewController
            signUpVc.delegate = self
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              !email.isEmpty,
              !password.isEmpty
        else {
            self.showLoginError(error: "Email and password fields cannot be empty")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) {
          user, error in
            if let error = error, user == nil {
                self.signedIn = false
                self.showLoginError(error: error.localizedDescription)
            } else {
                self.signedIn = true
                self.performSegue(withIdentifier: "loginToNewsfeedPageIdentifier", sender: self)
                /// signed up so we can fetch current user and start up app!
                db!.collection("users").document((Auth.auth().currentUser?.uid)!).addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                        }
                    _ = document.metadata.hasPendingWrites ? "Local" : "Server"
                    fetchUser(uid: document.documentID) { user in
                        currentUser = user
                    }
                }
            }
        }
        
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "signUpSegueIdentifier", sender: nil)
    }
    
    func showLoginError(error: String) {
        let controller = UIAlertController(title: "Log In Error",
                                           message: error,
                                           preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: "OK",
                                           style: .default,
                                           handler: nil))

        present(controller, animated: true, completion: nil)
    }

}

extension UITabBarController {
    func increaseBadge(indexOfTab: Int, num: String) {
        let tabItem = tabBar.items![indexOfTab]
        tabItem.badgeValue = num
    }
}
