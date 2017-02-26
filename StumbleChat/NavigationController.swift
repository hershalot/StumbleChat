//
//  NavigationController.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/20/17.
//  Copyright © 2017 Fenapnu. All rights reserved.

//  Main Naviagtion Controller with StartViewController as the Root View Controller.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.isNavigationBarHidden = true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}
