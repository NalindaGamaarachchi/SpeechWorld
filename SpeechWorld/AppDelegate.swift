//
//  AppDelegate.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        //LaunchViewController -> HomeViewController -> PigLatinViewController (fragile but i don't expect it to change)
        if let pigLatinViewController = window?.rootViewController?.presentedViewController?.presentedViewController as? PigLatinViewController {
            //pig latin has to dismiss because going in background puts the timers out of sync with the audio
            pigLatinViewController.dismiss(animated: true, completion: nil)
        }
    }

}

