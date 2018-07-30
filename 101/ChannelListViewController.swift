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

    var school: String?
    var timer = Timer()
    
    let refresh = UIRefreshControl()
    
    var bannerView: GADBannerView!
    
    
    // Store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private lazy var usersRef: DatabaseReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
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
        print("observing channels")
        channelRef.observe( .childAdded, with: {  (snapshot) -> Void in
           
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            let user = Auth.auth().currentUser
            
            if let name = channelData["name"] as! String?, name.count > 0, let school = channelData["school"] as! String? {
                print(school)
                // Display the current channel only if the username of the user is contained in the channel's list of members.
                if let members = channelData["members"] as! Dictionary<String, String>? {
                    if members.values.contains("\(String(describing: user!.uid))") {
                        self.channels.append(Channel(id: id, name: name, school: school))
                        self.tableView.tableFooterView?.isHidden = true
                        
                    } else {
                        
                    }
                }
                print(self.channels)
                self.tableView.reloadData()
                self.refresh.endRefreshing()
                
            } else {
                print("Error: could not decode channel data")
                self.refresh.endRefreshing()
            }
        })
    }
    
    // MARK: Actions
   
    
    // MARK: UITableViewDelegate
    // Open a channel when it is tapped
    override func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print((indexPath as NSIndexPath).row)
        print(channels)
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
                chatVc.school = channel.school
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
        tableView.rowHeight = 88
        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let data = snapshot.value as! Dictionary<String, AnyObject>
            self.school = data["school"] as? String
            self.channelRef = self.channelRef.child(self.school!)
            self.channels = []
            self.observeChannels()
        })
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(refreshChannels(_:)), for: .valueChanged)
        
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.delegate = self
        addBannerViewToView(bannerView)
        let request = GADRequest()
        
        bannerView.load(request)
    }
    
    @objc func refreshChannels(_ sender: Any) {
        self.channels = []
        observeChannels()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Get information about signed in user
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
        }
        observeChannels()
        print("refreshing")
        
        let request = GADRequest()
        
        bannerView.load(request)
    
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
    
    // MARK: Advertisements
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        /*view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])*/
        tableView.tableHeaderView?.frame = bannerView.frame
        tableView.tableHeaderView = bannerView
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
}













