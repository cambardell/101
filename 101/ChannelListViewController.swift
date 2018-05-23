 //
//  AddChannelViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-30.

import UIKit
import Firebase
import GoogleMobileAds

var handle: AuthStateDidChangeListenerHandle?

class ChannelListViewController: UITableViewController, GADBannerViewDelegate {
    // MARK: Properties
    var senderDisplayName: String?
    private var channels: [Channel] = []
    
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    // Hold a handle to the reference
    private var channelRefHandle: DatabaseHandle?
    
    // Store a reference to the user's list of channels.
    private lazy var userChannelRef: DatabaseReference = Database.database().reference().child("userChannels")
    // Hold a handle to the reference
    private var userChannelRefHandle: DatabaseHandle?
  
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        // A section for existing classes and for creating new ones, to be removed later. 
        return 1
    }
    
    // Set the number of rows for each section. This is always one for the new channel section, and the number of channels for the existing channels section.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return channels.count
    }
    
    
    // For the first section, store the text field from the cell in the newChannelTextField. For the second section, set the cell's text label as the channel name.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ChannelListCell
         
        cell.classTitle.text = channels[(indexPath as NSIndexPath).row].name
        
        return cell
    }
    
    // MARK: Firebase related methods
    private func observeChannels() {
        // Use the observe method to listen for new channels being written to firebase.
        // observe:with calls the completion block every time a new channel is added to the database.
        channelRefHandle = channelRef.observe(.childAdded, with: {  (snapshot) -> Void in
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            let user = Auth.auth().currentUser
            if let name = channelData["name"] as! String?, name.count > 0, let school = channelData["school"] as! String? {
                
                // Display the current channel only if the username of the user is contained in the channel's list of members.
                if let members = channelData["members"] as! Dictionary<String, String>? {
                    if members.values.contains("\(String(describing: user!.uid))") {
                        self.channels.append(Channel(id: id, name: name, school: school))
                        print("User id contained in members")
                    } else {
                        print("User id not contained in members")
                    }
                }
                
                self.tableView.reloadData()
                
            } else {
                print("Error: could not decode channel data")
            }
        })
    }
    
    // MARK: Actions
   
    
    // MARK: UITableViewDelegate
    // Open a channel when it is tapped
    override func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = channels[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "ShowChannel", sender: channel)
        
    }
    
    // MARK: Navigation
    // Set up the properties needed to initialize ChatViewController just before the segue takes place. 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "ShowChannel" {
            if let channel = sender as? Channel {
                let chatVc = segue.destination as! ChatViewController
                
                // Retrieve the account display name
                let user = Auth.auth().currentUser
                if let user = user {
                    let name = user.displayName
                    senderDisplayName = name
                }
                
                chatVc.channel = channel
                chatVc.channelRef = channelRef.child(channel.id)
                chatVc.senderDisplayName = senderDisplayName
            }
        }
        
        if segue.identifier == "AddChannel" {
            if let channel = sender as? Channel {
                let addVc = segue.destination as! AddChannelViewController
                
                addVc.channel = channel

            }
        }
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "101"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Get information about signed in user
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
        }
        channels = []
        observeChannels()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Detach the listener when the view disappears.
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
    
        }
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    
    // Stop observing database changes when the view controller dies.
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
        
    }
    
    
}













