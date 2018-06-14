//
//  AccountViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-27.
//

import Foundation
import UIKit
import Firebase

class AccountViewController: UIViewController {
    
    // TODO: Add change email, displayName, display name buttons.
    // TODO: Add email verification
    
    // MARK: Properties
    var handle: AuthStateDidChangeListenerHandle?
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var signOut: UIButton!
    @IBOutlet weak var changeName: UIButton!
    @IBOutlet weak var changePassword: UIButton!
    
    override func viewDidLoad() {
        signOut.layer.cornerRadius = 4
        changeName.layer.cornerRadius = 4
        changePassword.layer.cornerRadius = 4
    }
    
    
    // When the user taps the sign out button
    @IBAction func signOut(_ sender: AnyObject) {
        
        // Remove email and displayName from local storage
        defaults.set(nil, forKey: "jsq_email")
        defaults.set(nil, forKey: "jsq_displayName")
        
        // Move to the login screen.
        self.performSegue(withIdentifier: "signOut", sender: nil)
    }
    
    // Send an alert to change the displayName
    @IBAction func changeDisplayName(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Change display name", message: nil, preferredStyle: .alert)
        
        
        alert.addTextField { newDisplayNameField in
            newDisplayNameField.placeholder = "Enter new display name"
        }
        
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self, weak alert] _ in
            
            if let newDisplayNameField = alert?.textFields![0] {
                print("Action")
                let displayName = (newDisplayNameField.text)
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest!.displayName = displayName
                print("changing display name")
                changeRequest!.commitChanges { (error) in
                    print("Error saving display name \(String(describing: error))")
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // Send a password reset email.
    @IBAction func changePassword(_ sender: AnyObject) {
        let user = Auth.auth().currentUser
        Auth.auth().sendPasswordReset(withEmail: (user?.email)!) { error in
            print("Error sending password reset email", String(describing: error))
        }
    }
}

