//
//  LoadingViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-28.
//

import Foundation
import UIKit
import Firebase

class LoadingViewController: UIViewController {
    let defaults = UserDefaults.standard
    
    // If email and password are stored, log in. If not, move to login screen. 
    override func viewDidAppear(_ animated: Bool) {
        if let email = defaults.string(forKey: "jsq_email"), let password = defaults.string(forKey: "jsq_password") {
            print("login")
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let err = error {
                    print(err.localizedDescription)
                    self.performSegue(withIdentifier: "loginUnsuccessful", sender: nil)
                }
                
                self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
            }
        } else {
            print("no login")
            self.performSegue(withIdentifier: "loginUnsuccessful", sender: nil)
        }
        
    }
}
