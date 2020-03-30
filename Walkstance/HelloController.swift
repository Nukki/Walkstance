//
//  HelloController.swift
//  Walkstance
//
//  Created by Nikki Jack on 3/28/20.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit

class HelloController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        leftSwipe.direction = .up
        self.view.addGestureRecognizer(leftSwipe)
    }
    
    @objc func swipeAction(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction.rawValue {
        case 4:
            performSegue(withIdentifier: "swipeUp", sender: self)
        default:
            break
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
