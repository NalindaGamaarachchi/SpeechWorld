//
//  LaunchViewController.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Cal Stephens. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        PHPlayer.play("brainy phonics", ofType: "mp3")
        
        UAWhenDonePlayingAudio {
            let homeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "home") as! HomeViewController
            homeViewController.modalTransitionStyle = .coverVertical
            self.present(homeViewController, animated: true, completion: nil)
        }
    }
    
}
