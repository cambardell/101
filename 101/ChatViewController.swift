//
//  AddChannelViewController.swift
//  101
//
//  Created by Cameron Bardell on 2018-04-30.
//
import UIKit
import Firebase
import JSQMessagesViewController
import Photos

final class ChatViewController: JSQMessagesViewController {
  
  // MARK: Properties
    var channelRef: DatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    
    var school: String? 
    
    var selectedImage: UIImage?
    
    
    // Array to store the messages
    var messages = [JSQMessage]()
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    private lazy var messageRef: DatabaseReference = self.channelRef!.child("Messages")
    private var newMessageRefHandle: DatabaseHandle?
    
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://app-31003.appspot.com")
    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    
    private var updatedMessageRefHandle: DatabaseHandle?
    
    // Handle for signed in user.
    var handle: AuthStateDidChangeListenerHandle?
  
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    observeMessages()
    // Remove avatars. Can add back later. 
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
  }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.senderId = user.uid
                self.senderDisplayName = user.displayName
               
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
  
  
  // MARK: Collection view data source (and related) methods
    // Like cellForItemAtIndexPath but for messages
    override func collectionView (_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // Standard way to return number of items in a section.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Asks the data source for the message bubble image data that corresponds to incoming and outgoing messages.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    
    // Disables avatar support. Can add back later if I get to it.
    override func collectionView (_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // MARK: Navigation
    // Set up the properties needed to initialize ChannelInfoViewController just before the segue takes place.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showMedia" {
            if let pageDeDestination = segue.destination as? ShowMediaViewController {
                pageDeDestination.image = selectedImage!
            } else {
                print("type destination not ok")
            }
        } else {
            let infoVc = segue.destination as! ChannelInfoViewController
            infoVc.channel = channel
            infoVc.school = school
        }
       
    }
  
  // MARK: Firebase related methods
    
    // Get a reference to the stored image, get the image data, use the metadata to determine if it is a gif, and remove the key now that the image data has been fetched.
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        storageRef.getData(maxSize: INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            storageRef.getMetadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print ("Error downloading metadata \(error)")
                    return
                }
                
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage.gifWithData(data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
           
            })
        }
    }
  
  
  // MARK: UI and User Interaction
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    // Display the name above the bubble
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return messages[indexPath.item].senderId == senderId ? 0 : 15
    }
    
    
    // Store the JSQPhotoMediaItem in new property if the image key hasn't yet been set. This way it can be retrieved and updated later on when the image is set.
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    // Send a message to the database
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
        ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
    
    // Synchronize messages with the database.
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        // Limits the synchronization to the last 25 messages.
        let messageQuery = messageRef.queryLimited(toLast: 25)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // Extract the message data from the snapshot
            let messageData = snapshot.value as! Dictionary<String, String>
            
            // Add the new message to the data source
            if let id = messageData["senderId"] as String?, let name = messageData["senderName"] as String?, let text = messageData["text"] as String?, text.count > 0 {
                self.addMessage(withId: id, name: name, text: text)
                
                self.finishReceivingMessage()
                
            }  else if let id = messageData["senderId"] as String??,
                let photoURL = messageData["photoURL"] as String? {
                    
                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                        
                        self.addPhotoMessage(withId: id!, key: snapshot.key, mediaItem: mediaItem)
                        
                        if photoURL.hasPrefix("gs://") {
                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                        }
                    }
            
            } else {
                print("Error, could not decode message data.")
            }
        })
        
        // Listens for updates to existing messages, so when a photo has been stored the message data is updated.
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let photoURL = messageData["photoURL"] as String? {
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] {
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
            }
        })
        
    }
    
    // Similar to didPressSend
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
        ]
        
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    // Open the image in a new view controller.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        if let test = self.getImage(indexPath: indexPath) {
            selectedImage = test
            self.performSegue(withIdentifier: "showMedia", sender: self)
        }
    }
    
    func getImage(indexPath: IndexPath) -> UIImage? {
        let message = self.messages[indexPath.row]
        if message.isMediaMessage == true {
            let mediaItem = message.media
            if mediaItem is JSQPhotoMediaItem {
                let photoItem = mediaItem as! JSQPhotoMediaItem
                if let test: UIImage = photoItem.image {
                    let image = test
                    return image
                }
            }
        }
        return nil
    }
    
    // When the accessory button is pressed, present a camera if the device supports it and the photo library if not.
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let picker = UIImagePickerController()
        picker.delegate = self
        let alert = UIAlertController(title: "Camera or Library", message: "Take a photo with the camera or select it from your library.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: "Default action"), style: .default, handler: { _ in
            picker.sourceType = UIImagePickerControllerSourceType.camera
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Library", comment: "Default action"), style: .default, handler: { _ in
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        
    }
    
    //When chatViewController disappears
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }

  
  // MARK: UITextViewDelegate methods
  
}

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Handle the case where the user selects an image or cancels the selection process. When selecting an image, user takes either from the photo library or the camera.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        

        if let photoReferenceUrl = info[UIImagePickerControllerPHAsset] as? URL {
            let assets = PHAsset.fetchAssets(with: nil)
            let asset = assets.firstObject
            
            if let key = sendPhotoMessage() {
                asset?.requestContentEditingInput(with: nil, completionHandler: { (PHContentEditingInput, info) in
                    let imageFileURL = PHContentEditingInput?.fullSizeImageURL
                    
                    let path = "\(String(describing: Auth.auth().currentUser?.uid))/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    self.storageRef.child(path).putFile(from: imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // TODO: Handle picking a photo from the camera
            
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            if let key = sendPhotoMessage() {
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                
                let imagePath = Auth.auth().currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print ("Error uploading photo: \(error)")
                        return
                    }
                    
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}











