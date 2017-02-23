//
//  SegueFromRight.swift
//  WoolyBear
//
//  Created by Justin Hershey on 2/14/17.
//  Copyright © 2017 Fenapnu. All rights reserved.
//
//  Custom Segue for bringing a viewcontroller into view from the right with bouncing
//
//

import Foundation


class PushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.5;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let toViewController: UIViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
    
        transitionContext.containerView.addSubview(toViewController.view)
        toViewController.view.transform = CGAffineTransform(translationX: toViewController.view.frame.size.width, y: 0)
//        toViewController.view.alpha = 0.0;
//    
//    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
//        toViewController.view.alpha = 1.0;
//    } completion:^(BOOL finished) {
//    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
//    }];
//    }
    
        
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                            delay: 0.0,
            usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.4,
                options: UIViewAnimationOptions.curveEaseInOut,
                animations: {
                    toViewController.view.alpha = 1.0;
                    toViewController.view.transform = CGAffineTransform(translationX: 0, y: 0)
                    
                },
                completion: { finished in
//            src.present(dst, animated: false, completion: nil)
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            })
    }

}
