
//
//  SearchViewController.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/14/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//

import UIKit
import Firebase
import SystemConfiguration

class SearchViewController: UIViewController {
    
    
    
//    let mToken = FIRInstanceID.instanceID().token()
    var ref: FIRDatabaseReference!
    var userID: String = (FIRAuth.auth()?.currentUser?.uid)!

    
    var boldHighlight: Int = 2;
    
    var SwiftTimer = Timer()
    
    var pool: String!
    var channelID: String!
    
    var passiveUsers: Int = -1
    var aggressiveUsers: Int = -1
    
    var senderName: String = "Test User"
    var senderID: String = "TestID"
//    var senderToken: String = "empty"
    
    var aggressivePool: String = "AggressivePool"
    var passivePool: String = "PassivePool"
    
    var myCurrentPool: String!
    
//    var matchedToUser: String!
    
    @IBOutlet weak var topLeftIndicator: UIView!
    @IBOutlet weak var topRightIndicator: UIView!

    @IBOutlet weak var bottomLeftIndicator: UIView!
    @IBOutlet weak var bottomRightIndicator: UIView!
    
    
    @IBOutlet weak var connectingLbl: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        self.connectingLbl.isHidden = true
        self.topLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
        self.bottomRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.7)
        
        
        self.startIndicator()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToInactive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        
        
        if (self.connectedToNetwork()){
            setPool()
            
        }else{
        
            let alertController = UIAlertController(title: "Warning", message: "No Internet Connection", preferredStyle: .alert)
        
            let defaultAction = UIAlertAction(title: "OK", style: .default){ action in
                

                self.performSegue(withIdentifier: "toStartView", sender: nil)
                
            }
            alertController.addAction(defaultAction)
        
            present(alertController, animated: true, completion: nil)
        
        }
        

        // Do any additional setup after loading the view.
    }
    
    
    
    //send the disconnect signal sequence and kick user back to start screen
    func appMovedToInactive(_ animated: Bool) {
        
        print("App Resigning")
        let refWatch = ref.child(myCurrentPool).child(self.userID)
        refWatch.removeAllObservers()
        refWatch.removeValue()
        performSegue(withIdentifier: "toStartView", sender: nil)
        
    }
    
    func appWillTerminate(_ animated: Bool) {
        
        print("App Terminate")
        let refWatch = ref.child(myCurrentPool).child(self.userID)
        refWatch.removeAllObservers()
        refWatch.removeValue()
        try! FIRAuth.auth()!.signOut()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    
    
    //compares the two pool sizes and sets the users pool to the one with the least users
    func setPool(){
        
        //Get passive users count
        ref.child(passivePool).observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            self.passiveUsers = Int(snapshot.childrenCount)
            self.saveUserToPool()

        }) { (error) in
            print(error.localizedDescription)
        }
        
        //get aggressiveUsers count
        ref.child(aggressivePool).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.aggressiveUsers = Int(snapshot.childrenCount)
            self.saveUserToPool()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
        
    }
    
    //saves users to correct pool in firebase
    func saveUserToPool(){
        
        print("Aggressive users count: " + String(self.aggressiveUsers))
        print("Passive users count: " + String(self.passiveUsers))
        
        if((self.aggressiveUsers != -1) && (self.passiveUsers != -1)){
            
            let defaults = UserDefaults.standard
            let username = defaults.string(forKey: "displayName")

            //Add to aggressive pool if less than or equal to passivePool
            if(self.aggressiveUsers < passiveUsers ){
                
                self.myCurrentPool = self.aggressivePool
                
                let data = ["pool": self.myCurrentPool,
                            "name": username,
//                            "token":mToken
                            "channelID": "none"
                ]
                
                ref.child(aggressivePool).child(userID).setValue(data)
                self.searchForMatch(pool: self.myCurrentPool)
                
                
                
            }
                
            //Add to passivePool
            else{
                
                self.myCurrentPool = self.passivePool
                
                let data = ["pool": self.myCurrentPool,
                            "name": username,
                            "matchedToUserID": "none",
                            "matchedToUserName": "none",
                            "channelID": "none"
//                            "token":mToken
                ]
                
                ref.child(passivePool).child(userID).setValue(data)
                self.searchForMatch(pool: self.myCurrentPool)
            }
            
            
            
            
        }
        
        
        
    }
    
    
    //remove from matched pool upon searching start -- add check to see if you exist in matched pool
    func removeFromMatchedPool(){
        
            ref.child("MatchedUsers").child(userID).removeValue()
        
    
    }
    
    
    
    func searchForMatch(pool: String){
        
        senderName = "Test User"
        senderID = "TestID"
//        senderToken = "empty"
        
        if(pool == aggressivePool){
            
            
            //actively search for passive pool users -- Using a first in first out policy we can just grab the first item in the
            self.ref.child(passivePool).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let passiveDict = snapshot.value as? [String : AnyObject] ?? [:]
                
                if (snapshot.value != nil){
                    
                    print("Looking for user in PassivePool")
                    for item in passiveDict{
                        
                        let retrievedUser = passiveDict[item.key] as! NSDictionary
                        let matchedUserID = retrievedUser["matchedToUserID"] as! String
                        
                        //when a user is found that has no match, set passive matchedToUser key to aggressor userID so another match doesn't happen before data is moved to the matched table
                        
                        if(matchedUserID == "none"){
                            
                            print("found Unmatched User, matching to current user")
                            self.connectingLbl.isHidden = false
                            self.senderID = item.key
                            self.senderName = retrievedUser["name"] as! String
//                            self.senderToken = retrievedUser["token"] as! String
                            
                            self.channelID = self.userID + self.senderID
                            
                            let defaults = UserDefaults.standard
                            let myUsername = defaults.value(forKey: "displayName")
                            
                            let passiveData = ["matchedToUserName": myUsername,
                                               "matchedToUserID": self.userID,
//                                               "matchedToken": self.mToken,
                                                "channelID": self.channelID,
                                               "name": self.senderName,
                                               "pool": self.passivePool]
                            
                            self.ref.child(self.passivePool).child(self.senderID).setValue(passiveData)
                            
                            self.ref.child(self.aggressivePool).child(self.userID).removeValue()

                            
                            
                            break
                        }
                        
                    }

                    self.perform(#selector(self.showMessagingView), with: nil, afterDelay: 1.0)
                    

                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
            
            
            
        }else if(pool == passivePool){
            
            let refWatch = ref.child(passivePool).child(self.userID)
            //wait for match from the aggressive pool
            _ = refWatch.observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]

//                self.matchedToUser = postDict["matchedToUser"] as! String!
                
                if (snapshot.value != nil){
                    
                    let a = postDict["matchedToUserID"] as! String!
                    
                    print("Matched to Aggressor")
                    
                    if (a != "none"){
                        self.connectingLbl.isHidden = false
                        self.senderID = postDict["matchedToUserID"] as! String!
                        self.senderName = postDict["matchedToUserName"] as! String!
                        self.channelID = postDict["channelID"] as! String!
//                        self.senderToken = postDict["matchedToken"] as! String
                        
                        refWatch.removeAllObservers()
                        self.ref.child(self.passivePool).child(self.userID).removeValue()
                        
                        self.perform(#selector(self.showMessagingView), with: nil, afterDelay: 1.0)
                        
                    }
                    
                    
                    
                }
                
            })

            
            
        }
        
        
    }
    
    
    
    
    
    
    func showMessagingView(){
     
        
        performSegue(withIdentifier: "toMessagingView", sender: nil)
    }
    
    
    
    
    //start the custom loading indicator
    func startIndicator(){
        
        self.SwiftTimer = Timer.scheduledTimer(timeInterval: 0.4, target:self, selector: #selector(self.moveSquares), userInfo: nil, repeats: true)
        
    }
    
    
    
    
    
    
    func moveSquares(){
        
        if(self.boldHighlight == 1){
            
            self.topLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
            self.bottomRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.6)
            
            //set other squares back to clear background
            self.topRightIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            self.bottomLeftIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            
            
            self.boldHighlight = 2
            
            
        }
        else if(self.boldHighlight == 2){
            
            self.topRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
            self.bottomLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.6)
            
            
            //set other squares back to clear background
            self.topLeftIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            self.bottomRightIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            
            self.boldHighlight = 3
        }
            
        else if(self.boldHighlight == 3){
            
            self.bottomRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
            self.topLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.6)
            
            
            //set other squares back to clear background
            self.topRightIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            self.bottomLeftIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            
            
            self.boldHighlight = 4
            
        }
            
        else if(self.boldHighlight == 4){
            
            self.bottomLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
            self.topRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.6)
            
            //set other squares back to clear background
            self.topLeftIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            self.bottomRightIndicator.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
            
            self.boldHighlight = 1
            
            
        }
        
        
        
    }
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
                let cxnCheckRef = ref.child(myCurrentPool).child(self.userID)
                    
                    
                cxnCheckRef.removeAllObservers()
                
                performSegue(withIdentifier: "toStartView", sender: nil)
//                cxnCheckRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                    
//                    let uDict = snapshot.value as! [String : String] 
//                    
//                    let channel = uDict["channelID"]
//                    
//                    if (channel != "none"){
//                        
//                        
//                        let itemRef = self.ref.child("MessagingChannel").child(channel!).childByAutoId() // 1
//                        let messageItem = [
//                            "senderId": self.userID,
//                            "senderName": self.senderName,
//                            "text": "-1-2-3-4-5",
//                        ]
//                        
//                        itemRef.setValue(messageItem)
//
//                        
//                    }
//                    
//                })
                
                
                
            case UISwipeGestureRecognizerDirection.down:
                print("Swiped down")
                
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
                
                
                
            //
            case UISwipeGestureRecognizerDirection.up:
                print("Swiped up")
                
            default:
                break
            }
        }
    }
    
    
    //stop the custom loading indicator
    func stopIndicator(){
        
        self.SwiftTimer.invalidate()
        
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        //darken this view
        let overlayView: UIView = UIView.init(frame: self.view.bounds)
        overlayView.backgroundColor = UIColor.init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.5)
        self.view.addSubview(overlayView)
        
        if(segue.identifier == "toMessagingView"){
            
            //remove my pool data
            ref.child(myCurrentPool).child(userID).removeValue()
            
//            let dnc = segue.destination as! UINavigationController
//            let mvc: MessagingViewController = dnc.topViewController as! MessagingViewController
            
            
            let mvc:MessagingViewController = segue.destination as! MessagingViewController
            
            mvc.senderId = self.userID
            mvc.senderDisplayName = self.senderName
            mvc.connectedUsersId = self.senderID
            mvc.channelID = self.channelID
            
            
        }
        if(segue.identifier == "toStartView"){
            
            
            ref.child(self.myCurrentPool).child(self.userID).removeValue()
            
            
            
        }
        
    }
    
    //check for internet connection, returns true if there is a connection
    func connectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    
}


