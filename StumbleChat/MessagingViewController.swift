//
//  MessagingViewController.swift
//  WoolyBear
//
//  Created by Justin Hershey on 2/13/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//
//  ViewController that watches for changes to the messagingChannel in Firebase and displays messages while both users are connected
//
//  Segues -> toStartView -- swipe Right to disconnect and return to the StartViewController
//         -> toSearchView -- swipe Left to disconnect and start searching for another person to chat to
//
//
//


import UIKit
import JSQMessagesViewController
import Firebase
import Photos



class MessagingViewController: JSQMessagesViewController, UINavigationControllerDelegate {

    private var alert: UIAlertController? = nil
    var channelID: String!
    var connectedUsersId: String!
    
    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    
    var overlayView: UIView!
    var alreadyDisconnected: Bool = false
    
    var dAlert = UIAlertController()

    
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://stumblechat.appspot.com")
    private lazy var ref: FIRDatabaseReference = FIRDatabase.database().reference()
    private lazy var mRef: FIRDatabaseReference = FIRDatabase.database().reference().child("MessagingChannel")

    
    
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    
    //messages array
    var messages = [JSQMessage]()
    var searchVC: SearchViewController!
    var startView: UIImageView!
    var contentSize = 0.0
    var searchView: UIView!
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //Connected Users displayName Label
    @IBOutlet weak var displayNameLbl: UILabel!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlayView = UIView.init(frame: self.view.bounds)
        self.view.addSubview(overlayView)
        
        mRef = mRef.child(channelID)
        
        self.inputToolbar.contentView.backgroundColor = UIColor.init(red: 0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
        
        self.inputToolbar.contentView.rightBarButtonItem.backgroundColor = UIColor.init(red: 0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
        
        self.inputToolbar.contentView.textView.tintColor = UIColor.init(red: 0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
        
        
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(.white, for: .normal)
//        self.inputToolbar.contentView.leftBarButtonItem.setTitleColor(.white, for: .reserved)
        
        
        //Pan Gesture setup
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.respondToPanGesture))
        self.view.addGestureRecognizer(panGesture)
        
        self.displayNameLbl.text = "chatting with " + self.senderDisplayName + "..."
        self.displayNameLbl.textColor = UIColor.lightGray
        self.displayNameLbl.backgroundColor = UIColor.clear
        self.displayNameLbl.textAlignment = .center
        
        let statusHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        
        self.displayNameLbl.frame = CGRect(x: self.view.frame.origin.x, y: statusHeight, width: self.view.frame.size.width, height: 20)

        self.view.addSubview(self.displayNameLbl)
        self.view.bringSubview(toFront: self.displayNameLbl)

        self.collectionView.collectionViewLayout.springinessEnabled = false
        
        //Add observer to the app terminatingso we can kick the connected user back to the start screen and disconnect cleanly.
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        //App will resign active Observer so we can check to make sure there is an entry in the DB to reconnect properly when the app resumes
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToInactive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        //Did become active Observer to Check to make sure the chat is still active
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        // No Avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        
        
        self.navigationController?.delegate = self;
        //begin messaging Channel Observer
        observeMessages()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.overlayView.isHidden = true
        self.navigationController?.delegate = self;
        
        //setting the pan right image as
        startView = UIImageView.init(frame: CGRect(x: -self.view.frame.width, y: 0, width: self.view.frame.width, height:self.view.frame.height))
        
        searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchView") as! SearchViewController
        searchView = searchVC.view
        searchView.frame = CGRect(x:self.view.frame.width, y: 0, width: self.view.frame.width, height:self.view.frame.height)
        startView.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 0.9)
        startView.contentMode = .scaleToFill
        startView.image = UIImage(named: "startScreen")
        
        self.view.addSubview(startView)
        self.view.addSubview(searchView)
        
        
        searchVC = nil
    }
    
    
    //resize the Collection View so it doesn't overlap the displayName label
    override func viewDidLayoutSubviews() {
        
        let statusHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        self.collectionView.frame = CGRect(x: 0, y: statusHeight + 20.0, width: self.view.frame.size.width, height: self.collectionView.frame.height - (statusHeight + 20.0))
        
    }

    
    //send the disconnect signal sequence and kick user back to start screen
    func appWillTerminate(_ animated: Bool) {
        
        print("App Moving to Inactive")
        
        self.mRef.removeAllObservers()

        if (!alreadyDisconnected){
            
            let itemRef = mRef.childByAutoId()
            let messageItem = [
                "senderId": senderId!,
                "senderName": senderDisplayName!,
                "text": "-1-2-3-4-5",
                ]
            
            itemRef.setValue(messageItem)
            finishSendingMessage()
            
        }

        mRef.removeValue()
        try! FIRAuth.auth()!.signOut()
        

    }
    
    //If no messages yet, create a placeholder so user can reconnect when the app becomes active again
    func appMovedToInactive(_ animated: Bool) {
        
        print("App Moving to Inactive, chat still connected")

        
        //if no messages send a placeholder message to backend or when becoming active again chat will disconnect because it may not find any message data
        if (messages.count == 0){
            
            let itemRef = mRef.childByAutoId()
            let messageItem = [
                "senderId": senderId!,
                "senderName": senderDisplayName!,
                "text": "1-2-3-4-5-",
                ]
            
            itemRef.setValue(messageItem)
            finishSendingMessage()
            
            
        }
        
        
    }
    
    
    
    //Check to see if the session is still active. If not display disconnected alert
    
    func appMovedToActive(_ animated: Bool) {
        
        self.ref = FIRDatabase.database().reference()
        
        
        ref.child("MessagingChannel").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.hasChild(self.channelID){
                
                print("chat still ongoing")

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
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.init(red: 0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0))
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }


    
    
    //JSQMessaging/CollectionView Delegate Methods
    
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
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        
        
    }
    
    
    /*
     * Current Functionality -> Attatch Photo, Take/Send Photo. No video or location
     *
     *
     */
    
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
        
    }
    
    
 
    //sets the image URL as the message in the mesageingChannel
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = mRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    //sets the photoMessage in the MessagingChannel without the ImageURL as a placeholder
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
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        self.finishSendingMessage(animated: true)
    }
    
    
    //Messaging Channel Observer
    private func observeMessages() {

        let messageQuery = mRef.queryLimited(toLast:25)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, AnyObject>
            
            if let id = messageData["senderId"] as! String!, let name = messageData["senderName"] as! String!, let text = messageData["text"] as! String!, text.characters.count > 0 {
                
                //disconnected Message
                if(text == "-1-2-3-4-5"){
                    
                    self.disconnected()
                    
                //placeholder message
                }else if (text == "1-2-3-4-5-") {
                    
                    //do not display, this is just so we don't prematurely disconnect the users when one sends the app to the background before sending any messages
                    
                }
                
                //Normal message
                else{

                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.addMessage(withId: id, name: name, text: text)
                    

                    self.finishReceivingMessage()
                    
              
                    
                }
                
            }else if let id = messageData["senderId"] as! String!,
                let photoURL = messageData["photoURL"] as! String! { // 1

                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {

                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)

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

        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        

        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            

            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }

                else {
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
    
    
    // MARK: Navigation
    func showSearchView(animated: Bool){
    
        self.resignFirstResponder()
//        self.removeRefObserver()

        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchView") as! SearchViewController
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navi = appDelegate.navigationController
        
        navi?.pushViewController(searchVC, animated: animated)
        self.removeFromParentViewController()
        
    }
    
    
    
    
    func showStartView(animated: Bool){
        
        self.resignFirstResponder()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navi = appDelegate.navigationController
        
        _ = navi?.popToRootViewController(animated: animated)
        

    }
    
    
    
    func respondToPanGesture(gesture: UIPanGestureRecognizer){
        
        
        let velocity = gesture.velocity(in: self.view)
        let translation = gesture.translation(in: self.view)
        
        
        print("frame coords minX: ")
        print(self.view.frame.minX)
        print("frame coords midX: ")
        print(self.view.frame.midX)
        print("New Center: ")
        print(gesture.view!.center.x + translation.x)
        
        
        if (gesture.state == .began) {
            
            
            
            
            gesture.view!.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y)
            
            gesture.setTranslation(CGPoint.zero, in: self.view)
            
            
            
            
            
        }
        else if (gesture.state == .changed){
            
            
            gesture.view!.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y)
            
            
            gesture.setTranslation(CGPoint.zero, in: self.view)
            
            
            
            
            
        }
            
        else if (gesture.state == .ended){
            
            //on fast pan right, go back to startView
            if (velocity.x > 1500){
                
                print("animation velocity reached")
//                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {
                                
                                
                                self.view.transform = CGAffineTransform(translationX: self.view.frame.width - self.view.frame.minX, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed Pan Right Fast")
                                self.mRef.removeAllObservers()
                                
                                //send disconnnect string as message
                                let itemRef = self.mRef.childByAutoId()
                                let messageItem = [
                                    "senderId": self.senderId!,
                                    "senderName": self.senderDisplayName!,
                                    "text": "-1-2-3-4-5",
                                    ]
                                
                                itemRef.setValue(messageItem)
                                
                                self.finishSendingMessage()
                                
                                self.darkenView()
                                self.showStartView(animated: false)
//                                self.perform(#selector(self.showStartView), with: nil, afterDelay: 0.0)
                                
                                
                })
                
                
            }
            
            //on fast left pan, goto searchView
            else if (velocity.x < -1500){
                
                print("animation velocity reached")
//                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {

                                self.view.transform = CGAffineTransform(translationX:  -(self.view.frame.width + self.view.frame.minX), y: 0)
                                
                                
                },
                               completion: { finished in
                                print("Completed Pan Left Fast")
                                self.mRef.removeAllObservers()
                                
                                if (!self.alreadyDisconnected){
                                    
                                    //send disconnnect string as message
                                    let itemRef = self.mRef.childByAutoId()
                                    let messageItem = [
                                        "senderId": self.senderId!,
                                        "senderName": self.senderDisplayName!,
                                        "text": "-1-2-3-4-5",
                                        ]
                                    
                                    itemRef.setValue(messageItem)
                                    self.finishSendingMessage()
                                    
                                }
                                self.darkenView()
                                self.showSearchView(animated: false)
//                                self.perform(#selector(self.showSearchView), with: nil, afterDelay: 0.0)
                                
                })
                
                
            }
                
                //on before middle of screen, stay in search view
            else if (self.view.frame.minX <= 0 && self.view.frame.minX >= -self.view.frame.width/2){
                
                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {
                                
                                
                                self.view.transform = CGAffineTransform(translationX: self.view.frame.size.width/2 - tempCenter, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed No Change, left Pan (Neg Vel)")
                                
                                
                })
            }
                //On passed middle of screen, goto start view
            else if (self.view.frame.minX <= 0 && self.view.frame.minX <= -self.view.frame.width/2){
                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               
                               animations: {
                                
                                self.view.transform = CGAffineTransform(translationX:-self.view.frame.size.width/2 - tempCenter, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed Left Pan (Neg Vel)")
                                self.mRef.removeAllObservers()
                                
                                if (!self.alreadyDisconnected){
                                    
                                    //send disconnnect string as message
                                    let itemRef = self.mRef.childByAutoId()
                                    let messageItem = [
                                        "senderId": self.senderId!,
                                        "senderName": self.senderDisplayName!,
                                        "text": "-1-2-3-4-5",
                                        ]
                                    
                                    itemRef.setValue(messageItem)
                                    self.finishSendingMessage()
                                    
                                }
                                self.darkenView()
                                self.showSearchView(animated: false)
//                                self.perform(#selector(self.showSearchView), with: nil, afterDelay: 0.0)
                                
                                
                })
                
            }
                
                //on less than half screen pan stay in messageView -----FROM START VC
            else if (self.view.frame.minX >= 0 && self.view.frame.minX <= self.view.frame.width/2){
                
                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {
                                
                                
                                self.view.transform = CGAffineTransform(translationX: self.view.frame.size.width/2 - tempCenter, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed No Change, Right Pan (Pos Vel)")
                                
                                
                })
            }
                
                //on more than half screen pan goto searchView -----FROM START VC
            else if (self.view.frame.minX >= 0 && self.view.frame.minX > self.view.frame.width/2){
                
//                let tempCenter = gesture.view!.center.x
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               
                               animations: {
                                
                                
                                
                                self.view.transform = CGAffineTransform(translationX: self.view.frame.width - self.view.frame.minX, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed Right Pan (Pos Vel)")
                                //check for display Name
                                self.mRef.removeAllObservers()
                                
                                if (!self.alreadyDisconnected){
                                    
                                    //send disconnnect string as message
                                    let itemRef = self.mRef.childByAutoId()
                                    let messageItem = [
                                        "senderId": self.senderId!,
                                        "senderName": self.senderDisplayName!,
                                        "text": "-1-2-3-4-5",
                                        ]
                                    
                                    itemRef.setValue(messageItem)
                                    self.finishSendingMessage()
                                    
                                }
                                self.darkenView()
                                self.showStartView(animated: false)
//                                self.perform(#selector(self.showStartView), with: nil, afterDelay: 0.0)

                                    
                                    
                                
                })
                
            }
            
        }
        
    }


    
    //Handle the disconnected message
    func disconnected(){
        
        self.mRef.removeAllObservers()
//        self.deinit()
        let alertController = UIAlertController(title: "User Disconnected", message: "Find another?", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "Go", style: .default) { action in

            self.resignFirstResponder()
            self.alreadyDisconnected = true
            self.mRef.removeAllObservers()
            self.mRef.removeValue()
            
            self.darkenView()
            self.showSearchView(animated: true)

            
        }
        
        let CancelAction = UIAlertAction(title: "Cancel", style: .default) { action in

            self.mRef.removeAllObservers()
            self.mRef.removeValue()
            
            self.darkenView()
            self.showStartView(animated: true)
            
            
        }
        alertController.addAction(CancelAction)
        alertController.addAction(OKAction)
        
        
        
        self.present(alertController, animated: true) {
        }
        
    }
    
    //set overlayView visible with black alpha background
    func darkenView(){
        
        self.overlayView.backgroundColor = UIColor.init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.3)
        
        self.overlayView.isHidden = false
        
    }
    
//    func navigationController(_ navigationController:UINavigationController,
//                              animationControllerFor operation: UINavigationControllerOperation,
//                              from fromVC: UIViewController,
//                              to toVC:UIViewController) -> UIViewControllerAnimatedTransitioning?
//    {
//        
//        
//        if (operation == UINavigationControllerOperation.push){
//            return PushAnimator.init()
//        }
//        
//        if (operation == UINavigationControllerOperation.pop){
//            return PopAnimator.init()
//        }
//        return nil
//        
//    }

}


// MARK: Image Picker Delegate
extension MessagingViewController: UIImagePickerControllerDelegate {
    

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        
        let chosenImage: UIImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
            
        var data = NSData()
        
        //set data in case user is choosing photo from gallary
        data = UIImageJPEGRepresentation(chosenImage, 1.0)! as NSData
            
        
        
        //this doesn't catch the photo gallary properly -> photo returns nil when representing asset result as JPEG or PNG data
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
  
            
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            if let key = sendPhotoMessage() {

                let manager = PHImageManager.default()
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                
                
                manager.requestImage(for: asset!, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: nil, resultHandler: {(result, info)->Void in

                    
                    
                    
                    let path = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    
                    //oddly this returns nil if the image is from the photo gallary
                    
                    if let imageFileURL = UIImageJPEGRepresentation(result!, 1.0){

                        self.storageRef.child(path).put(imageFileURL, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print("Error uploading photo: \(error.localizedDescription)")
                                return
                            }
                            self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                        }
                        
                    }else{
                        

                            let imageData = data
                        
                            self.storageRef.child(path).put(imageData as Data, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print("Error uploading photo: \(error.localizedDescription)")
                                return
                            }
                            self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                            
                        }
                
                            
                    }

                    
                })
                

            }
        
        } else {
            
  
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
 
            if let key = sendPhotoMessage() {
 
                let imageData = UIImageJPEGRepresentation(image, 1.0)
   
                let imagePath = FIRAuth.auth()!.currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
   
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"

                storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
                    
                    if let error = error {
                        
                        print("Error uploading photo: \(error)")
                        return
                        
                    }
  
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion:nil)
        
    }
    
    
    
    
    
    
}


