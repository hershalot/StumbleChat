//
//  StartViewController.swift
//  WoolyBear
//
//  Created by Justin Hershey on 2/13/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//
//
//  ViewController to provide the initial App screen. Allows user to set a displayName.

//  Segues -> toSearchView -> by swipingLeft or pressing startChattingBtn
//

import UIKit
import Firebase
import EAIntroView

class StartViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, EAIntroDelegate {
    
    //variables
    var uid: NSString = ""
    var displayName:String = ""
    var alert: UIAlertController? = nil
    var ref: FIRDatabaseReference!
    var introView: EAIntroView!
    var overlayView: UIView!
    
    
    @IBOutlet weak var bearImage: UIImageView!
    
    //displayLabel
    @IBOutlet weak var displayLbl: UILabel!
    
    //mark Outlets
    @IBOutlet weak var displayNameText: UITextField!
    
    
    //mark Actions
    @IBAction func startChattingAction(_ sender: Any) {
        
        
        startChat()
        
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //View to dim the view moving out of view
        overlayView = UIView.init(frame: self.view.bounds)
        self.view.addSubview(overlayView)
        
        //configure textField border
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: displayNameText.frame.size.height - width, width:  displayNameText.frame.size.width, height: displayNameText.frame.size.height)
        border.borderWidth = width
        displayNameText.layer.addSublayer(border)
        displayNameText.layer.masksToBounds = true
        
        //swipe down gesture recognizer to dismiss keyboard
//        let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer.init(target: self.view, action:dismissKeyboard)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
//        swipeRight.direction = UISwipeGestureRecognizerDirection.right
//        self.view.addGestureRecognizer(swipeRight)
        
        

        
    }
    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        
////        self.dismiss(animated: false, completion: nil)
//        
//    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.overlayView.isHidden = true
        
        //set firebase base reference
        ref = FIRDatabase.database().reference()
        self.displayNameText.delegate = self
        
//        self.navigationController?.isNavigationBarHidden = true
        
        let defaults = UserDefaults.standard;
        displayName = defaults.string(forKey: "displayName")! as String
        
        if(displayName != "") {
            
            displayNameText.text = displayName as String;
            
        }
        
        if (defaults.bool(forKey: "isFirstRun")){
            self.showIntro()
            
        }
    }
    
    /*
    *Center the bearImage between the DisplayNameText and the topLayoutGuide
    */
    override func viewDidLayoutSubviews() {
        
        let statusHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        let bottom = displayLbl.frame.origin.y
        
        let bearImageHeight = bearImage.frame.size.height / 2.0
        
        let centerY = bottom / 2
        
        bearImage.frame.origin.y = centerY - bearImageHeight + (statusHeight / 2.0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     * startChat() --> Checks to make sure user entered a displayName, performs toSearchView segue if so
     */
    
    func startChat(){
        
        if(displayNameText.text != ""){
            
            let defaults = UserDefaults.standard;
            defaults.set(self.displayName, forKey: "displayName")
            defaults.synchronize()
            
            darkenView()

            let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchView") as! SearchViewController
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let navi = appDelegate.navigationController
            
            navi?.pushViewController(searchVC, animated: true)

            
        }else{
            
            let alertController = UIAlertController(title: "Wait!", message: "Enter a display name", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)

            present(alertController, animated: true, completion: nil)
            
        }
        
    }
    

    
    
    /*
     *Utilizes EAIntroView to show basic Intro to use WoolyBear
     */
    
    func showIntro(){
        
        let page1 = EAIntroPage.init()
        page1.title = "Welcome To WoolyBear"
        page1.desc = "Start chatting with random people today";
//        page1.bgImage = UIImage(named: "AppIcon")
        
        let page2 = EAIntroPage.init()
        page2.title = "Swipe Left to Search"
        
        
        let page3 = EAIntroPage.init()
        page3.title = "Swipe Right to Stop"
        
        introView = EAIntroView.init(frame: self.view.bounds, andPages: [page1,page2,page3])
        introView.backgroundColor = UIColor.init(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.8)

        introView.delegate = self
        
        introView.show(in: self.view)
    }
    
    //On intro finished set "isFirstRun" key to false so the introView won't show again on launch
    func introDidFinish(_ introView: EAIntroView!, wasSkipped: Bool) {
        
        let defaults = UserDefaults.standard
        if (wasSkipped) {

            print("Intro Skipped")

            
        } else {
            
            
            print("Intro finished")
        }
        defaults.set(false, forKey: "isFirstRun")
        defaults.synchronize()
    }
    
    
    
    //set 
    func darkenView(){
        
        
        overlayView.backgroundColor = UIColor.init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.5)
        self.overlayView.isHidden = false
        
    }

    

/*
 * On TextFieldShouldReturn save the displayName to UserDefaults with key "displayName"
 * Then resign the keyboard
 */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let defaults = UserDefaults.standard
        self.displayName = textField.text!
        
        if (self.displayName != ""){
            
            defaults.set(self.displayName, forKey: "displayName")
            defaults.synchronize()
            
        }
        
        print(self.displayName)
        textField.resignFirstResponder()
        return true
    }
    
/*
* Swipe Gesture Handler -> call startChat() on swipe left
                        -> resignFirstResponder on swipe down to get rid of the keyboard
                        -> Currently Disabled -- RightSwipe toAboutView
*/
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
                //nothing for now

            case UISwipeGestureRecognizerDirection.down:
                print("Swiped down")
                displayNameText.resignFirstResponder()
                
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
                
                startChat()
                
            case UISwipeGestureRecognizerDirection.up:
                print("Swiped up")
                
            default:
                break
            }
        }
    }
}

