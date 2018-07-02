//
//  ChannelInfoViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-05-03.
//

import Foundation
import UIKit
import Firebase
import MessageUI

class ChannelInfoViewController: UIViewController, MFMailComposeViewControllerDelegate {
    // TODO: Report button
    
    var channel: Channel?
    var school: String? 
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels").child(school!)
    
    let user = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var leaveClass: UIButton!
    @IBOutlet weak var reportUser: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leaveClass.layer.cornerRadius = 4
        reportUser.layer.cornerRadius = 4
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    
    // When the leave group button is pressed, delete the userid from the channel's members and return user to ChannelListViewController
    @IBAction func leaveGroup(_ sender: Any) {
        print("Button Pressed")
        channelRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let channelsData = snapshot.value as! Dictionary<String, AnyObject>
            let channelData = channelsData["\(String(describing: self.channel!.id))"] as! Dictionary<String, AnyObject>
            // If members exists and contains the users id, remove the users id from members
            if var members = channelData["members"] as! Dictionary<String, String>? {
                if members.values.contains("\(self.user!)") {
                    let key = members.keysForValue(value: self.user!)[0]
                    print(key)
                    members.removeValue(forKey: key)
                    self.channelRef.child((self.channel?.id)!).child("members").setValue(members)
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        })
    }
    
    // Open an email with instructions for reporting
    @IBAction func reportUser(_ sender: Any) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setToRecipients(["talk101app@gmail.com"])
        composeVC.setSubject("User report")
        composeVC.setMessageBody("Please include the school, course code, and name of the user you are reporting, as well as the behaviour leading to the report.", isHTML: false)
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}

extension Dictionary where Value: Equatable {
    /// Returns all keys mapped to the specified value.
    /// ```
    /// let dict = ["A": 1, "B": 2, "C": 3]
    /// let keys = dict.keysForValue(2)
    /// assert(keys == ["B"])
    /// assert(dict["B"] == 2)
    /// ```
    func keysForValue(value: Value) -> [Key] {
        return compactMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}
