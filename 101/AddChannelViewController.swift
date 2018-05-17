//
//  AddChannelViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-30.
//

import Foundation
import UIKit
import Firebase


class AddChannelViewController: UITableViewController {
    // TODO: Fix checkmarks when searching vs not searching. 
    private var channels: [Channel] = []
    
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
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
        observeChannels()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by course code or school"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    // Get information about signed in user when view will appear.
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let channel: Channel
        
        if isFiltering() {
            channel = filteredChannels[indexPath.row]
        } else {
            channel = channels[indexPath.row]
        }
        
        cell.textLabel?.text = ("\(channel.name) - \(channel.school)")
        return cell
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
            let newMemberDisplayNameRef = memberDisplayNameRef.childByAutoId()
            
            let channelData = channelsData["\(channel.id)"] as! Dictionary<String, AnyObject>
            
            // Add the user as a member only if they are not already one.
            if let members = channelData["members"] as! Dictionary<String, String>? {
                if members.values.contains("\(String(describing: user?.uid))") {
                    print("User id contained in members")
                } else {
                    print("User id not contained in members")
                    newMemberRef.setValue(user?.uid)
                    newMemberDisplayNameRef.setValue(user?.displayName)

                    // Calling observe channels removes the cell the user just tapped, because the user's id is now in members.
                    self.observeChannels()
                }
            } else {
                print("No members yet")
                newMemberRef.setValue(user?.uid)
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
    
    // Search for both the course code and the school. 
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredChannels = channels.filter({( channel : Channel) -> Bool in
            return ("\(channel.name) - \(channel.school)").lowercased().contains(searchText.lowercased())
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


