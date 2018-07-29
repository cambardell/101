//
//  AddChannelViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-30.
//

import Foundation
import UIKit
import Firebase
import MessageUI

class AddChannelViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    // TODO: Fix checkmarks when searching vs not searching. 
    private var channels: [Channel] = []
    
    var school: String?
    
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private lazy var usersRef: DatabaseReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
    // Hold a handle to the reference
    private var channelRefHandle: DatabaseHandle?
    
    var channel: Channel?
    
    private var newMemberRefHandle: DatabaseHandle?
    
    var handle: AuthStateDidChangeListenerHandle?
    
    // searchResultsController: nil tells the search controller that the same view you're searching will display the results.
    let searchController = UISearchController(searchResultsController: nil)
    // Hold the channels that the user is searching for
    var filteredChannels = [Channel]()
    
    
    // Observes for channels when the view loads.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by course code"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        tableView.rowHeight = 88
    }
    
    // Get information about signed in user when view will appear.
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let data = snapshot.value as! Dictionary<String, AnyObject>
            self.school = data["school"] as? String
            self.channelRef = self.channelRef.child(self.school!)
            self.observeChannels()
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    // Set the number of rows.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredChannels.count
        } else {
            return channels.count
        }
    }
    
    // Set the label text to be the name of the channel
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! AddChannelListCell
        let channel: Channel
        
        if isFiltering() {
            channel = filteredChannels[indexPath.row]
        } else {
            channel = channels[indexPath.row]
        }
        
        cell.classTitle.text = channel.name
        cell.classSchool.text = channel.school
        return cell
    }
    
    @IBAction func reportMissing(_ sender: Any) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setToRecipients(["talk101app@gmail.com"])
        composeVC.setSubject("Missing class")
        composeVC.setMessageBody("Missing a class? Please enter the school and course code.", isHTML: false)
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func observeChannels() {
        // Use the observe method to listen for new channels being written to firebase.
        // observe:with calls the completion block every time a new channel is added to the database.
        channels = []
        let user = Auth.auth().currentUser
        channelRefHandle = channelRef.observe(.childAdded, with: {  (snapshot) -> Void in
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = channelData["name"] as! String?, name.count > 0, let school = channelData["school"] as! String? {
                // Don't display the channel if the user is already a member.
                if let member = channelData["members"] as? Dictionary<String, String> {
                    if member.values.contains((user?.uid)!) == false {
                        self.channels.append(Channel(id: id, name: name, school: school))
                        self.tableView.reloadData()
                    }
                } else {
                    self.channels.append(Channel(id: id, name: name, school: school))
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: could not decode channel data")
            }
        })
    }

    // Add channel to the user's list of channels when it is tapped.
    override func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Channel tapped")
        channelRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let channelsData = snapshot.value as! Dictionary<String, AnyObject>
            var channel: Channel
            
            // Set the channel based on whether the user is searching or not.
            if self.isFiltering() {
                channel = self.filteredChannels[(indexPath as NSIndexPath).row]
            } else {
                channel = self.channels[(indexPath as NSIndexPath).row]
            }
            
            let user = Auth.auth().currentUser
    
            let memberRef: DatabaseReference = self.channelRef.child(channel.id).child("members")
            let newMemberRef = memberRef.childByAutoId()
            
            let memberDisplayNameRef: DatabaseReference = self.channelRef.child(channel.id).child("names")
            
            let channelData = channelsData["\(channel.id)"] as! Dictionary<String, AnyObject>
            
            // Add the user as a member only if they are not already one.
            if let members = channelData["members"] as! Dictionary<String, String>? {
                if members.values.contains("\(String(describing: user?.uid))") {
                    print("User id contained in members")
                } else {
                    print("User id not contained in members")
                    newMemberRef.setValue(user?.uid)
                    let newMemberDisplayNameRef = memberDisplayNameRef.child(user!.uid)
                    newMemberDisplayNameRef.setValue(user?.displayName)

                    // Calling observe channels removes the cell the user just tapped, because the user's id is now in members.
                    self.observeChannels()
                }
            } else {
                print("No members yet")
                newMemberRef.setValue(user?.uid)
                let newMemberDisplayNameRef = memberDisplayNameRef.child(user!.uid)
                newMemberDisplayNameRef.setValue(user?.displayName)
                
                // Calling observe channels removes the cell the user just tapped, because the user's id is now in members.
                self.observeChannels()
            }
        })
        
    }
    
    // MARK: Search methods
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // Search for    the course code. 
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredChannels = channels.filter({( channel : Channel) -> Bool in
            return ("\(channel.name)").lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

extension AddChannelViewController: UISearchResultsUpdating {
    // MARK: UISearchResultsUpdating delegate
    func updateSearchResults(for searchController: UISearchController) {
        // This is the only method that must be implemented to conform to the protocol.
        filterContentForSearchText(searchController.searchBar.text!)
    }
}


