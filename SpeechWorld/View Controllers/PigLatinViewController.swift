//
//  PigLatinViewController.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import UIKit
import SwiftUI




//MARK: - PigLatinViewController

class PigLatinViewController: UIViewController {
    @IBOutlet weak var theContainer : UIView!
    
    
    //MARK: Presentation
    
    static func present(from source: UIViewController) {
        let pigLatin = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pig latin") as! PigLatinViewController
        source.present(pigLatin, animated: true, completion: nil)
    }
    
 
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        
        let childView = UIHostingController(rootView: RecordView())
        addChild(childView)
        childView.view.frame = theContainer.bounds
        theContainer.addSubview(childView.view)
    }
    

    
}
