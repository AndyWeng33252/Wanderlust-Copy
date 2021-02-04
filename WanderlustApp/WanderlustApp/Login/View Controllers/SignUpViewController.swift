//
//  SignUpViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 10/7/20.
//

import UIKit
import FirebaseAuth
import FirebaseFirestoreSwift

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    var newUser: User?
    var delegate:LoginViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let username = usernameTextField.text,
              !email.isEmpty,
              !password.isEmpty,
              !username.isEmpty
        else {
            self.showSigninError(error: "All fields must be filled out")
            return
        }
        
        /// check for a unique username
        let docRef = db!.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        docRef.getDocuments { (querysnapshot, error) in
            if error != nil {
                print("Document Error: ", error!)
            } else {
                if let doc = querysnapshot?.documents, !doc.isEmpty {
                    /// username exists
                    self.showSigninError(error: "Username is taken. Please choose another.")
                } else {
                    /// username does not exist, go ahead and create user
                    self.createUser(email: email, password: password, username: username)
                }
            }
        }
    }
    
    func createUser(email: String, password: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) {
            user, error in
                if let error = error, user == nil {
                    print(error)
                    self.showSigninError(error: error.localizedDescription)
                } else if let _ = user {
                    self.newUser = User(username: username, followers: [], following: [],
                                        requests: [], bio: "Set up Bio!", publicUser: false, trips:[], photoUrl: nil, favorites: [])
                    self.handleSignUp()
                    fetchUser(uid: Auth.auth().currentUser!.uid) { fetchedUser in
                        currentUser = fetchedUser
                    }
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.performSegue(withIdentifier: "loginToNewsfeedPageIdentifier", sender: self.delegate)
                }
        }
    }
    
    func handleSignUp() {
        addUserToFirestore(newUser: newUser!)
    }
    
    func showSigninError(error: String) {
        let controller = UIAlertController(title: "Sign Up Error",
                                           message: error,
                                           preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: "OK",
                                           style: .default,
                                           handler: nil))

        present(controller, animated: true, completion: nil)
    }
    
}
