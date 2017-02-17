//
//  MessagingViewController.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/13/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import Photos



class MessagingViewController: JSQMessagesViewController {

    
    var channelID: String!
    var connectedUsersId: String!
    
    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    

    var alreadyDisconnected: Bool = false
    
    var dAlert = UIAlertController()

    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://stumblechat.appspot.com")
    private lazy var ref: FIRDatabaseReference = FIRDatabase.database().reference()
    private lazy var mRef: FIRDatabaseReference = FIRDatabase.database().reference().child("MessagingChannel")

    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    var messages = [JSQMessage]()
    
    var contentSize = 0.0
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    
    @IBOutlet weak var displayNameLbl: UILabel!
    
    override func viewDidLayoutSubviews() {
        let statusHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        self.collectionView.frame = CGRect(x: 0, y: statusHeight + 20.0, width: self.view.frame.size.width, height: self.collectionView.frame.height - (statusHeight + 20.0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setting mRef to the the current messaging channel firebase ref being used
        mRef = mRef.child(channelID)
        
//        self.scrollToBottom(animated: false)
        
        
        self.displayNameLbl.text = "chatting with " + self.senderDisplayName + "..."
        self.displayNameLbl.textColor = UIColor.lightGray
        self.displayNameLbl.backgroundColor = UIColor.clear
        self.displayNameLbl.textAlignment = .center
//        self.displayNameLbl.font.
        
        let statusHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        
        self.displayNameLbl.frame = CGRect(x: self.view.frame.origin.x, y: statusHeight, width: self.view.frame.size.width, height: 20)

        self.view.addSubview(self.displayNameLbl)
        self.view.bringSubview(toFront: self.displayNameLbl)
        
//        contentSize = self.collectionView.bounds.height + 50.0
        
//        automaticallyScrollsToMostRecentMessage = true
        self.collectionView.collectionViewLayout.springinessEnabled = false
        
        //Add observer to the app resigning so we can kick the user back to the start screen and disconnect cleanly
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToInactive), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        // No Avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
//        self.scrollToBottom(animated: false)
        observeMessages()
        
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
////        contentSize = self.collectionView.contentSize
////        if (contentSize.height > self.collectionView.bounds.size.height) {
////            let targetContentOffset = CGPoint(x:0.0, y:contentSize.height - self.collectionView.bounds.size.height)
////            self.collectionView.setContentOffset(targetContentOffset, animated:true);
////        }
////  
//        print("contentSize: " + String(describing: self.collectionView.contentSize.height))
//        print("Bounds Height: " + String(describing: self.collectionView.bounds.size.height))
//        
//        
////
//    }
    
    //send the disconnect signal sequence and kick user back to start screen
    func appMovedToInactive(_ animated: Bool) {
        
        print("App Moving to Inactive")
        self.mRef.removeAllObservers()
        performSegue(withIdentifier: "toSearchView", sender: nil)
        
        
        
    }
    
    func appMovedToActive(_ animated: Bool) {
        
        self.ref = FIRDatabase.database().reference()
        
        
        ref.child("MessagingChannel").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.hasChild(self.channelID){
                
                print("chat still ongoing")
//                self.observeMessages()
                
            }else{
                
                print("chat no longer exists")
                self.disconnected()
                
            }
            
            
        })
        
    }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            mRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            mRef.removeObserver(withHandle: refHandle)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //UI Setup
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }


    
    
    //JSQMessaging Delegate Methods
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            
            return outgoingBubbleImageView
            
        } else {
            
            return incomingBubbleImageView
        }
    }
    
        
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = mRef.childByAutoId()
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        
        itemRef.setValue(messageItem)
        
//        self.collectionView.contentOffset = CGPoint(x:0, y:self.collectionView.contentSize.height - self.collectionView.bounds.size.height);

        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        

        finishSendingMessage()
        
        
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("pressed Accessory Button")
        
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        
        
        print("pressed Accessory Button")
        
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let sheet = UIAlertController(title: "Photo messages", message: nil, preferredStyle: .actionSheet)
        
        
        let picker = UIImagePickerController()
        
        picker.delegate = self
        let takePhotoAction = UIAlertAction(title: "Take a photo", style: .default) { (action) in
            
            picker.sourceType = UIImagePickerControllerSourceType.camera
            self.present(picker, animated: true, completion:nil)
            
        }
        
        let attatchPhotoAction = UIAlertAction(title: "Attach a photo", style: .default) { (action) in
            
            
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(picker, animated: true, completion:nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        sheet.addAction(takePhotoAction)
        sheet.addAction(attatchPhotoAction)
        sheet.addAction(cancelAction)
        
        self.present(sheet, animated: true, completion: nil)
        
        
        
        
//        let picker = UIImagePickerController()
//        picker.delegate = self
//        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
//            
//            picker.sourceType = UIImagePickerControllerSourceType.camera
//            
//            
//        } else {
//            
//            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
//        }
//        
//        present(picker, animated: true, completion:nil)
    }
    
    
 
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = mRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    func sendPhotoMessage() -> String? {
        let itemRef = mRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    func addMedia(_ media:JSQMediaItem) {
        let message = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: media)
        self.messages.append(message!)
        
        //Optional: play sent sound
        
        self.finishSendingMessage(animated: true)
    }
    
    private func observeMessages() {

        // 1.
        let messageQuery = mRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                // 4
                
                if(text == "-1-2-3-4-5"){
                    self.disconnected()
                    
                }
                
                else{

                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.addMessage(withId: id, name: name, text: text)
                    
//                    self.collectionView.contentOffset = CGPoint(x:0, y:self.collectionView.contentSize.height - self.collectionView.bounds.size.height);

                    self.finishReceivingMessage()
                    
              
                    
                }
                
            }else if let id = messageData["senderId"] as String!,
                let photoURL = messageData["photoURL"] as String! { // 1
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    // 4
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
            
            
            
            else {
                print("Error! Could not decode message data")
            }
        })
        
        updatedMessageRefHandle = mRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData["photoURL"] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
    
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
       
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        
        // 2
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
//                if (metadata?.contentType == "image/gif") {
////                    mediaItem.image = UIImage.gifWithData(data!)
//                    mediaItem.image = UIImage.init(data: data!)
//                }
                else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    
    
    // MARK: Navigation
    
    //Swipe Gesture Method
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
            case UISwipeGestureRecognizerDirection.down:
                print("Swiped down")

            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
                
                self.mRef.removeAllObservers()
                performSegue(withIdentifier: "toSearchView", sender: nil)
                
//                
            case UISwipeGestureRecognizerDirection.up:
                print("Swiped up")
                
            default:
                break
            }
        }
    }


    // MARK: - Navigation
    
    
    func disconnected(){
        
        self.mRef.removeAllObservers()
        let alertController = UIAlertController(title: "User Disconnected", message: "Find another chatter", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "Search", style: .default) { action in
            // ...
            
            //                        self.mRef.removeAllObservers()
            self.resignFirstResponder()
            self.alreadyDisconnected = true
            self.performSegue(withIdentifier: "toSearchView", sender: nil)
            
        }
        
        let CancelAction = UIAlertAction(title: "Back", style: .default) { action in
            // ...
            
            //                        self.mRef.removeAllObservers()
            self.resignFirstResponder()
            self.performSegue(withIdentifier: "toStartView", sender: nil)
            
        }
        alertController.addAction(OKAction)
        alertController.addAction(CancelAction)
        
        
        self.present(alertController, animated: true) {
            // ...
        }
        
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "toSearchView"){
            
            
            //TODO: Delete messages thread and send a disconnect message to other user
            if (!alreadyDisconnected){
            
                let itemRef = mRef.childByAutoId() // 1
                let messageItem = [ // 2
                "senderId": senderId!,
                "senderName": senderDisplayName!,
                "text": "-1-2-3-4-5",
                ]
            
                itemRef.setValue(messageItem) // 3
                
            
            
//            JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
            
                finishSendingMessage()
            }
            
            storageRef.delete(completion: { (Void) in
                print("Deleting Photos")
            })
            mRef.removeValue()

            
        }
        if(segue.identifier == "toStartView"){
            
            storageRef.delete(completion: { (Void) in
                print("Deleting Photos")
            })
            mRef.removeValue()
            
            
        }
        
        
    }




}


// MARK: Image Picker Delegate
extension MessagingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // 1
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // 2
        
            
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            if let key = sendPhotoMessage() {

                let manager = PHImageManager.default()
                
                manager.requestImage(for: asset!, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: nil, resultHandler: {(result, info)->Void in
                    // Result is a UIImage
                    // Either upload the UIImage directly or write it to a file
                    
                    print(result!)
                    
                    let path = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    if let imageFileURL = UIImageJPEGRepresentation(result!, 1.0){
                        
                        
                        self.storageRef.child(path).put(imageFileURL, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print("Error uploading photo: \(error.localizedDescription)")
                                return
                            }
                            // 7
                            self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                        }
                        
                    }else{
                        
                        let image = UIImage(named: "noImage")
                        let imageFileURL = UIImageJPEGRepresentation(image!, 1.0)
                        
                        self.storageRef.child(path).put(imageFileURL!, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print("Error uploading photo: \(error.localizedDescription)")
                                return
                            }
                            // 7
                            self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                        }
                    }

//                    let data: NSData = NSData.withData(UIImagePNGRepresentation(result!)!)
//                    let imageFileURL: UIImage = UImage.imageWithData(data)
//                    UIImage *img=[UIImage imageWithData:data];

                    
                    
                    
                    // 6
                    
                })
                
//                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
//                    let imageFileURL = contentEditingInput?.fullSizeImageURL
//                    
//                    
//                    let path = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
//                    
//                    // 6
//                    self.storageRef.child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
//                        if let error = error {
//                            print("Error uploading photo: \(error.localizedDescription)")
//                            return
//                        }
//                        // 7
//                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
//                    }
//                })
            }
        } else {
            
            // Handle picking a Photo from the Camera - TODO
            // 1
            
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2
            if let key = sendPhotoMessage() {
                // 3
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                // 4
                let imagePath = FIRAuth.auth()!.currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                // 5
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6
                storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
