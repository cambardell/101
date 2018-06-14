//
//  AddChannelViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-30.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
  @IBOutlet weak var errorText: UILabel!
    let defaults = UserDefaults.standard
  
  // MARK: View Lifecycle
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    errorText.isHidden = true
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
  
  // When the login button is tapped
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    // Check if fields are empty, if not, log in and move to ChannelListViewController
    if emailField?.text != "" && passwordField?.text != "" {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if let err = error {
                print(err.localizedDescription)
                self.errorText.text = err.localizedDescription
                self.errorText.isHidden = false
                return
            }
            
            // Save email and password to device, if they haven't been stored already.
            self.defaults.set(self.emailField.text!, forKey: "jsq_email")
            self.defaults.set(self.passwordField.text!, forKey: "jsq_password")
            
           
            self.defaults.synchronize()
            
            self.performSegue(withIdentifier: "LoginToChat", sender: nil)
        }
        
    }
    
  }
    
    // When the create account button is tapped, move to the create account screen.
    @IBAction func createAccount(_ sender: Any) {
        
        self.performSegue(withIdentifier: "createAccount", sender: nil)
    }
    
    // Send a password reset email.
    @IBAction func changePassword(_ sender: AnyObject) {
        Auth.auth().sendPasswordReset(withEmail: (emailField.text)!) { error in
            print("Error sending password reset email", String(describing: error))
        }
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
    }
  
  // MARK: - Notifications
  
  @objc func keyboardWillShowNotification(_ notification: Notification) {
    let keyboardEndFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
    bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
  }
  
  @objc func keyboardWillHideNotification(_ notification: Notification) {
    bottomLayoutGuideConstraint.constant = 48
  }
    
    // Hide the keyboard when hitting the return key. 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

