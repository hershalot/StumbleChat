//
//  CustomPresentAnimationController.swift
//  StumbleChat
//
//  Created by Justin Hershey on 2/14/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//

import Foundation


class SegueFromRight: UIStoryboardSegue {
    
        override func perform()
        {
            let src = self.source
            let dst = self.destination
            
            src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
            dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
            

            
            UIView.animate(withDuration: 0.7,
                                       delay: 0.0,
                                       usingSpringWithDamping: 0.4,
                                       initialSpringVelocity: 0.4,
                                       options: UIViewAnimationOptions.curveEaseInOut,
                                       animations: {
                                        dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
            },
                                       completion: { finished in
                                        src.present(dst, animated: false, completion: nil)
            }
            )
        }

}
