//
//  ChannelInfoViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-05-03.
//

import Foundation
import UIKit
import Firebase

class ChannelInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // TODO: Report button
    
    var channel: Channel?
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    
    let user = Auth.auth().currentUser?.uid
    
    var displayNames: Dictionary<String, String>.Values = ["key": "value"].values
    var displayNamesArray: Array<String> = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leaveClass: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leaveClass.layer.cornerRadius = 4
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        channelRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let channelsData = snapshot.value as! Dictionary<String, AnyObject>
            let channelData = channelsData["\(String(describing: self.channel!.id))"] as! Dictionary<String, AnyObject>
            
            if let memberNames = channelData["names"] as! Dictionary<String, String>? {
                self.displayNames = memberNames.values
                for name in self.displayNames {
                    self.displayNamesArray.append(name)
                }
                self.tableView.reloadData()
                
            }
        })
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayNamesArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "DisplayName"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        cell.textLabel?.text = displayNamesArray[(indexPath as NSIndexPath).row]
        
        return cell
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
