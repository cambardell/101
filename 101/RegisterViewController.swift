//
//  RegisterViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-26.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth

class RegisterViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
    @IBOutlet weak var schoolPicker: UIPickerView!
    
    let defaults = UserDefaults.standard
    
    let schools = ["Select your school", "University of Waterloo", "Queen's University", "Wilfrid Laurier University", "Trent University"]
    
    // MARK: View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        self.nameField.delegate = self
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.errorLabel.isHidden = true
        schoolPicker.delegate = self
        schoolPicker.dataSource = self
    }
    
    // When the sign up button is tapped
    @IBAction func loginDidTouch(_ sender: AnyObject) {
        // Check if fields are empty, if not, create a new user and move to ChannelListViewController
        if nameField?.text != "" && emailField?.text != "" && passwordField?.text != "" && self.schoolPicker.selectedRow(inComponent: 0) != 0 {
            
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
                if let err = error {
                    print(err.localizedDescription)
                    self.errorLabel.text = err.localizedDescription
                    self.errorLabel.isHidden = false

                    return
                }
                
                // Set the display name for the account.
                let displayName = (self.nameField.text)
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest!.displayName = displayName
                changeRequest!.commitChanges { (error) in
                    print("Error saving display name \(String(describing: error))")
                }
                
                // Set the users school based on the picker view
                var selectedSchool = self.schools[self.schoolPicker.selectedRow(inComponent: 0)]
                if selectedSchool == "Queen's University" {
                    selectedSchool = "Queens University"
                }
                let userSchool = ["school": selectedSchool]
                Database.database().reference().child("users").child(user!.uid).setValue(userSchool)
                
                // Save the email and password to device for automatic login
                self.defaults.set(self.emailField.text, forKey: "jsq_email")
                self.defaults.set(self.passwordField.text, forKey: "jsq_password")
                
                self.performSegue(withIdentifier: "LoginToChat", sender: nil)
            }
            
            defaults.synchronize()
        }
    }
    @IBAction func viewTos(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://101-software.com/terms-of-service")!)
        
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "LoginToChat" {
            let navVc = segue.destination as! UINavigationController
            let channelVc = navVc.viewControllers.first as! ChannelListViewController
            // Set the display name as the name given in the text field.
            channelVc.senderDisplayName = nameField?.text
        }
        
    }
    
    // MARK: Picker View

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return schools.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return schools[row]
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
    
    // Dismiss the text field when hitting return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        if schoolPicker.isHidden {
            
        }
    }
}

