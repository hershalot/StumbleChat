//
//  ViewController.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/13/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//

import UIKit
import Firebase

class StartViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var uid: NSString = ""
    var displayName:String = ""
    var alert: UIAlertController? = nil
    var ref: FIRDatabaseReference!
    
    
    
    //mark Outlets
    @IBOutlet weak var displayNameText: UITextField!
    
    
    //mark Actions
    @IBAction func startChattingAction(_ sender: Any) {
        
        
        startChat()
        
    }
    
    func startChat(){
        if(displayNameText.text != ""){
            
            let defaults = UserDefaults.standard;
            defaults.set(self.displayName, forKey: "displayName")
            defaults.synchronize()
            
            performSegue(withIdentifier:"toSearchView", sender: nil)
            
        }else{
            
            let alertController = UIAlertController(title: "Wait!", message: "Enter a display name", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    
    
    //Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        self.displayNameText.delegate = self
        
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
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        
        let defaults = UserDefaults.standard;
        displayName = defaults.string(forKey: "displayName")! as String
        
        if(displayName != "") {
            
            displayNameText.text = displayName as String;
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("Segue Identifier: " + segue.identifier!)
        
        //decide which pool to add user too -- add to pool with least users, Default to aggressive pool when the same
        
        
        
        
        if(segue.identifier == "toSearchView"){
//            var userID: String = (FIRAuth.auth()?.currentUser?.uid)!
            
            print("To Search View")
            
            
//            let searchView:SearchViewController = segue.destination as! SearchViewController
        }
        
            
    }
    

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
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
                performSegue(withIdentifier: "toAboutView", sender: nil)
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

