
//
//  SearchViewController.swift
//  WoolyBear
//
//  Created by Justin Hershey on 2/14/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//
//  ViewController that displays a searching animation. Provides a medium to connect to another user

//  Segues -> toMessagingView -> On connection, shows MessagingViewController with a unique messaging channel with the other user
//         -> toStartView -> bySwipingRight - cancels search and returns to startView
//
//

import UIKit
import Firebase
import SystemConfiguration

class SearchViewController: UIViewController {
    
    
    //Firebase Data
    var ref: FIRDatabaseReference!
    var userID: String = (FIRAuth.auth()?.currentUser?.uid)!

    var overlayView: UIView!
    var boldHighlight: Int = 2;
    
    //Timer for searching animation
    var SwiftTimer = Timer()
    
    
    // Once connected to another user, will contain the MessagingChannel ID between the two users
    var channelID: String!
    var rotateLabel: UILabel!
    
    //initially set to -1 so we can know when both pools have returned (will return with int > 0)
    var passiveUsers: Int = -1
    var aggressiveUsers: Int = -1
    
    var senderName: String = "Test User"
    var senderID: String = "TestID"
    
    //Pool Strings - Constant
    let aggressivePool: String = "AggressivePool"
    let passivePool: String = "PassivePool"
    
    //Current Users pool, will be either "AggressivePool" or "PassivePool"
    var myCurrentPool: String!
    var startImage: UIImageView!
    var rightView: UIView!

    
    //Views used for the searching animation
    @IBOutlet weak var topLeftIndicator: UIView!
    @IBOutlet weak var topRightIndicator: UIView!
    @IBOutlet weak var bottomLeftIndicator: UIView!
    @IBOutlet weak var bottomRightIndicator: UIView!
    
    //Label that displays once a connection has begun to establish
    @IBOutlet weak var connectingLbl: UILabel!
    
    @IBOutlet weak var mainSearchLbl: UILabel!
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        overlayView = UIView.init(frame: self.view.bounds)
        
        self.view.addSubview(overlayView)

        rotateSearchLbl()
        self.rotateLabel.isHidden = false
        self.connectingLbl.isHidden = true
        self.mainSearchLbl.isHidden = true
        
    
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToInactive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        
//        self.topLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
//        self.bottomRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.7)
//       
//        
//        
//    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ref = FIRDatabase.database().reference()
//        self.navigationController?.delegate = self;
        self.overlayView.isHidden = true
        self.rotateLabel.isHidden = true
        self.mainSearchLbl.isHidden = false
        
        
        
        //setting the pan right image as
        startImage = UIImageView.init(frame: CGRect(x: -self.view.frame.width, y: 0, width: self.view.frame.width, height:self.view.frame.height))
        
        rightView = UIView.init(frame: CGRect(x: self.view.frame.width, y: 0, width: self.view.frame.width, height:self.view.frame.height))
        
        rightView.backgroundColor = UIColor.init(red: 0.0/255.0, green: 122.0/255.0, blue: 161.0/255.0, alpha: 1.0)
        startImage.contentMode = .scaleToFill
        startImage.image = UIImage(named: "startScreen")

        
        
        //Pan Gesture setup
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.respondToPanGesture))
        self.view.addGestureRecognizer(panGesture)
        

        self.connectingLbl.isHidden = true
        self.topLeftIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
        self.bottomRightIndicator.backgroundColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 0.7)
        
        //start searching animation
        self.startIndicator()
        
        //If network connection is active, call setPool() to determine the pool to add to
        if (self.connectedToNetwork()){
            
            setPool()
            
        }else{
            
            let alertController = UIAlertController(title: "Warning", message: "No Internet Connection", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default){ action in
                
                self.showStartView(animated: true)
//                self.perform(#selector(self.showStartView), with: nil, afterDelay: 0.0)
                
                
            }
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    func rotateSearchLbl(){
        
        rotateLabel = UILabel(frame: CGRect(x:10, y:(self.view.frame.size.height/2 - 75), width:40, height:200))
        
        rotateLabel.textAlignment = .right
        rotateLabel.font = UIFont.init(name: "Arial", size: 35)
        rotateLabel.text = "Search"
        
        rotateLabel.textColor = UIColor.init(red: 53.0/255.0, green: 214.0/255.0, blue: 132.0/255.0, alpha: 1.0)
        
        self.view.addSubview(rotateLabel)
        
        rotateLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        
        rotateLabel.frame = CGRect(x:10, y:self.view.frame.size.height/2 - 75, width:40, height:200)
        
    }
    
    
    
    //Deletes User's Pool data and kicks user back to start screen
    func appMovedToInactive(_ animated: Bool) {
        
        print("App Resigning")
        self.showStartView(animated: true)
//        self.perform(#selector(self.showStartView), with: nil, afterDelay: 0.0)
        
    }
    
    //Performs DB cleanup on app Termination, removes user's Pool data
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
                ]
                
                ref.child(passivePool).child(userID).setValue(data)
                self.searchForMatch(pool: self.myCurrentPool)
            }
            
            
            
            
        }
        
        
        
    }
    

    func searchForMatch(pool: String){
        
        senderName = "Test User"
        senderID = "TestID"

        
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
                            
                            self.channelID = self.userID + self.senderID
                            
                            let defaults = UserDefaults.standard
                            let myUsername = defaults.value(forKey: "displayName")
                            
                            let passiveData = ["matchedToUserName": myUsername,
                                               "matchedToUserID": self.userID,
                                                "channelID": self.channelID,
                                               "name": self.senderName,
                                               "pool": self.passivePool]
                            
                            self.ref.child(self.passivePool).child(self.senderID).setValue(passiveData)
                            
                            self.ref.child(self.aggressivePool).child(self.userID).removeValue()

                            
                            break
                        }
                        
                    }
//                    self.darkenView()
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
//                        self.darkenView()
                        self.perform(#selector(self.showMessagingView), with: nil, afterDelay: 1.0)
                        
                    }
                    
                    
                    
                }
                
            })
            
        }
        
    }
    
    
    func showMessagingView(){
        
        
        
        let messagingVC = self.storyboard?.instantiateViewController(withIdentifier: "messagingView") as! MessagingViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navi = appDelegate.navigationController
        
        messagingVC.senderId = self.userID
        messagingVC.senderDisplayName = self.senderName
        messagingVC.connectedUsersId = self.senderID
        messagingVC.channelID = self.channelID
        
        
        stopIndicator()
        print("pushing search onto stack")
        
        
        navi?.pushViewController(messagingVC, animated: true)
        self.removeFromParentViewController()
        
    }
    
    
    
    
    func showStartView(animated: Bool){
     
        
        let cxnCheckRef = ref.child(myCurrentPool).child(self.userID)
        
        cxnCheckRef.removeAllObservers()
        
        
        ref.child(self.myCurrentPool).child(self.userID).removeValue()
        
        darkenView()
        stopIndicator()
        
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navi = appDelegate.navigationController

        _ = navi?.popViewController(animated: animated)
    }
    
    
    
    
    //start the custom loading indicator
    func startIndicator(){
        
        self.SwiftTimer = Timer.scheduledTimer(timeInterval: 0.4, target:self, selector: #selector(self.moveSquares), userInfo: nil, repeats: true)
        
    }
    
    
    
    
    
/*
* Move squares for loading animation > Uses a timer
*/
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
    
    
    
/*
 * Swipe Direction Handler
 * Right -> toStartView
 * Left -> toSearchView
 */
    
    
    
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
            
            self.view.addSubview(startImage)
            self.view.addSubview(rightView)


            gesture.view!.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y)
                
            gesture.setTranslation(CGPoint.zero, in: self.view)

                
        
            
            
        }
        else if (gesture.state == .changed){
            

                gesture.view!.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y)
                
                
                gesture.setTranslation(CGPoint.zero, in: self.view)

            
            
            
            
        }
            
        else if (gesture.state == .ended){
            
            //on fast pan, go back to startView
            if (velocity.x > 1300){
                
                print("animation velocity reached")
//                let tempCenter = gesture.view!.center.x
                darkenView()
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.4,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {
                                

                                
                                 self.view.transform = CGAffineTransform(translationX: self.view.frame.width - self.view.frame.minX, y: 0)
                                
                },
                               completion: { finished in
                                
                                print("Completed")
                                self.showStartView(animated: false)
                                
                                
                })
                
                
            }

            //on before middle of screen, stay in search view
            else if (self.view.frame.midX <= self.view.frame.width){
                
                let tempCenter = gesture.view!.center.x
                
                UIView.animate(withDuration: 0.9,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.4,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               animations: {
                                
                                
                                self.view.transform = CGAffineTransform(translationX: self.view.frame.size.width/2 - tempCenter, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed")
                                
                                
                })
            }
            //On passed middle of screen, goto start view
            else if (self.view.frame.midX > self.view.frame.width){

                darkenView()
                UIView.animate(withDuration: 0.8,
                               delay: 0.0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.3,
                               options: UIViewAnimationOptions.curveEaseInOut,
                               
                               animations: {

                                self.view.transform = CGAffineTransform(translationX: self.view.frame.width - self.view.frame.minX, y: 0)
                                
                },
                               completion: { finished in
                                print("Completed")
                                self.showStartView(animated: false)
                                
                                
                })
                
            }
            
            
            
            
        }
        
    }

    
    
    //stop the custom loading indicator
    func stopIndicator(){
        
        self.SwiftTimer.invalidate()
        
    }
    

    func darkenView(){
        
        //darken this view
        
        overlayView.backgroundColor = UIColor.init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.3)
        self.overlayView.isHidden = false

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
        
        
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
            stopIndicator()
            
            
        }
        if(segue.identifier == "toStartView"){
            
            stopIndicator()
            ref.child(self.myCurrentPool).child(self.userID).removeValue()

            
        }
        
    }
    
    func navigationController(_ navigationController:UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC:UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        
        
        if (operation == UINavigationControllerOperation.push){
            return PushAnimator.init()
        }
        
        if (operation == UINavigationControllerOperation.pop){
            return PopAnimator.init()
        }
        return nil
        
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


