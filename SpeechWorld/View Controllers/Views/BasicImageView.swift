//
//  BasicImageView.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import UIKit

class BasicImageView: UIView {
    
    private let imageView: UIImageView
    
    init(with image: UIImage, targetWidth: CGFloat) {
        imageView = UIImageView()
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        setUpImageView(with: image, targetWidth: targetWidth)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    private func setUpImageView(with image: UIImage, targetWidth: CGFloat) {
        addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.constraintInCenterOfSuperview()
        
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1.0).isActive = true
        
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: targetWidth)
        widthConstraint.priority = UILayoutPriority(rawValue: 900)
        widthConstraint.isActive = true
    }
    
}

