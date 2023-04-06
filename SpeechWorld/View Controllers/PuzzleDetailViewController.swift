//
//  PuzzleDetailViewController.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import UIKit

class PuzzleDetailViewController : UIViewController {
    
    @IBOutlet weak var puzzleView: PuzzleView!
    @IBOutlet weak var puzzleViewCenterHorizontally: NSLayoutConstraint!
    
    @IBOutlet weak var rhymeText: UITextView!
    @IBOutlet weak var rhymeTextHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrim: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var bankButton: UIButton!
    
    var oldPuzzleView: UIView!
    var puzzleShadow: UIView!
    var animationImage: UIImageView!
    var sound: Sound!
    var notifyOfDismissal: (() -> Void)?
    
    
    //MARK: - Presentation
    
    static func present(for sound: Sound, from puzzleView: UIView, withPuzzleShadow puzzleShadow: UIView, in source: UIViewController, onDismiss: (() -> Void)?) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let puzzleDetail = storyboard.instantiateViewController(withIdentifier: "puzzle detail") as? PuzzleDetailViewController else { return }
        
        puzzleDetail.oldPuzzleView = puzzleView
        puzzleDetail.puzzleShadow = puzzleShadow
        puzzleDetail.sound = sound
        puzzleDetail.notifyOfDismissal = onDismiss
        
        puzzleDetail.modalPresentationStyle = .overCurrentContext
        
        source.present(puzzleDetail, animated: false, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if rhymeText.contentSize.height > view.frame.height - 100 {
            rhymeTextHeight.constant = self.view.frame.height - 50 // 50 = padding on top/bottom
            rhymeText.setContentOffset(.zero, animated: false)
        }
        rhymeText.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.view.layoutIfNeeded()
        
//        rhymeText.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)

        updateAccessoryViews(visible: false)
        self.puzzleView.alpha = 0.0
        if let puzzle = self.sound.puzzle {
            self.puzzleView.puzzleName = self.sound.puzzleName
            
            let progress = Player.current.progress(for: puzzle)
            self.puzzleView.isPieceVisible = progress.isPieceOwned
            
            if progress.isComplete, let rhymeText = self.sound.rhymeText {
                self.prepareRhymeText(for: rhymeText)
            } else {
                //center the puzzle and hide the rhyme text
                self.puzzleViewCenterHorizontally.priority = .defaultHigh
                self.rhymeText.isHidden = true
                self.puzzleView.layoutIfNeeded()
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        //create image and then animate
        guard let oldPuzzleView = self.oldPuzzleView else { return }
        let translatedFrame = self.view.convert(oldPuzzleView.bounds, from: oldPuzzleView)
        
        let puzzleImage = puzzleView.asImage
        self.animationImage = UIImageView(image: puzzleImage)
        self.saveAnimationImage(puzzleImage)
        
        
        animationImage.frame = translatedFrame
        self.view.addSubview(animationImage)
        oldPuzzleView.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.curveEaseIn], animations: {
            
            self.animationImage.frame = self.puzzleView.frame
            self.updateAccessoryViews(visible: true)
            
        }, completion: { _ in
            if let puzzle = self.puzzleView.puzzle,
               Player.current.progress(for: puzzle).isComplete {
                self.playAudio(self)
            }
            
            self.puzzleView.alpha = 1.0
            UIView.animate(withDuration: 0.225, delay: 0.0, options: [], animations: {
                self.animationImage.alpha = 0.0
            }, completion: nil)
        })
        
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 1.0) {
            self.rhymeText.transform = .identity
        }
    }
    
    func updateAccessoryViews(visible: Bool) {
        let views: [UIView] = [scrim, backButton, repeatButton, blurView, rhymeText]
        let commonAlpha: CGFloat = (visible ? 1.0 : 0.0)
        
        for view in views {
            view.alpha = commonAlpha
        }
        
        self.puzzleShadow.alpha = (visible ? 0.0 : 1.0)
    }
    
    
    //MARK: - Rhyme
    
    func prepareRhymeText(for text: String) {
        rhymeText.clipsToBounds = false
        rhymeText.layer.masksToBounds = false
        self.repeatButton.isHidden = false
        
        //build attributed string
        let attributes = rhymeText.attributedText.attributes(at: 0, effectiveRange: nil)
        let attributedText = NSMutableAttributedString(string: text, attributes: attributes)

        let redHighlightColor = UIColor(hue: 1.0, saturation: 1.0, brightness: 0.73, alpha: 1.0)
        self.addHighlights(of: redHighlightColor, to: attributedText)
        rhymeText.attributedText = attributedText
        view.bringSubview(toFront: rhymeText)
        rhymeText.layoutIfNeeded()
    }
    
    func addHighlights(of color: UIColor, to attributedString: NSMutableAttributedString) {
        var rangesToHighlight = [NSRange]()
        var startForRangeInProgress: Int? = nil
        var parenthesisCount = 0
        
        //find ranges to highlight (knowing that the parenthesis will be removed later)
        for (index, character) in attributedString.string.enumerated() {
            
            if character == Character("(") {
                startForRangeInProgress = index - parenthesisCount
                parenthesisCount += 1
            }
            
            else if character == Character(")"), let rangeStart = startForRangeInProgress {
                let rangeEnd = index - parenthesisCount
                let rangeLength = rangeEnd - rangeStart
                let newRange = NSMakeRange(rangeStart, rangeLength)
                rangesToHighlight.append(newRange)
                
                parenthesisCount += 1
                startForRangeInProgress = nil
            }
        }
        
        //remove parenthesis
        let newString = attributedString.string
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        let fullRange = NSMakeRange(0, attributedString.string.length)
        attributedString.replaceCharacters(in: fullRange, with: newString)
        
        //apply highlights
        for range in rangesToHighlight {
            attributedString.addAttribute(.foregroundColor, value: color, range: range)
        }
    }
    
    
    //MARK: - User Interaction
    
    @IBAction func backTapped(_ sender: Any) {
        
        UAHaltPlayback()
        self.puzzleView.alpha = 0.0
        self.animationImage.alpha = 1.0
        
        //grab new image
        self.animationImage.image = self.oldPuzzleView.asImage
        
        //animate
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
        
            guard let oldPuzzleView = self.oldPuzzleView else { return }
            let translatedFrame = self.view.convert(oldPuzzleView.bounds, from: oldPuzzleView)
            self.animationImage.frame = translatedFrame
            self.bankButton.isHidden = true
            self.updateAccessoryViews(visible: false)
        
        }, completion: { _ in
            self.oldPuzzleView.alpha = 1.0
            self.dismiss(animated: false, completion: nil)
            
            self.notifyOfDismissal?()
        })
    }
    
    @IBAction func playAudio(_ sender: Any) {
        let audioName = sound.rhymeAudioName
        PHPlayer.play(audioName, ofType: "mp3")
        self.repeatButton.isEnabled = false
        UAWhenDonePlayingAudio {
            self.repeatButton.isEnabled = true
        }
    }
    
    @IBAction func bankTapped(_ sender: UIButton) {
        UAHaltPlayback()
        
        let overThreshold = Player.current.sightWordCoins.gold >= 50
        let celebrate = overThreshold && !Player.current.hasSeenSightWordsCelebration

        self.view.isUserInteractionEnabled = false

        BankViewController.present(
            from: self,
            goldCount: Player.current.sightWordCoins.gold,
            silverCount: Player.current.sightWordCoins.silver,
            playCelebration: celebrate,
            onDismiss: {
                self.view.isUserInteractionEnabled = true
        })
    }
    
    
    
    //MARK: - Save Image to Disk
    //this will help decrease the load when displaying puzzles in a collection view
    
    func saveAnimationImage(_ image: UIImage) {
        if !Puzzle.imageExists(forPuzzleNamed: sound.puzzleName) {
            Puzzle.save(image: image, asPuzzleNamed: sound.puzzleName)
        }
    }
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        var topCorrect : CGFloat = (rhymeText.frame.height - rhymeText.contentSize.height);
//        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect / 2
//        rhymeText.contentOffset = CGPoint(x: 0, y: -topCorrect)
//    }
    
}


extension UIView {
 
    var asImage: UIImage {
        let previousAlpha = self.alpha
        self.alpha = 1.0
        
        let deviceScale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, deviceScale)
        
        let context = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        self.alpha = previousAlpha
        return image
    }
    
}




