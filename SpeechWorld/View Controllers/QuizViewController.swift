//
//  QuizViewController.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import Foundation
import UIKit

class QuizViewController : InteractiveGrowViewController {
    
    var sound: Sound?
    var totalAnswerWordPool: [Word]!
    var remainingAnswerWordPool: [Word]!
    
    var onlyShowThreeWords: Bool = false
    var dismissOnReturnFromModal = false
    var difficulty: Letter.Difficulty?
    
    var currentLetter: Letter!
    var currentSound: Sound!
    var answerWord: Word!
    
    @IBOutlet weak var soundLabel: UILabel!
    @IBOutlet var wordViews: [WordView]!
    @IBOutlet weak var topLeftWordLeading: NSLayoutConstraint!
    @IBOutlet weak var fourthWord: WordView!
    
    @IBOutlet weak var puzzleView: PuzzleView!
    @IBOutlet weak var puzzleShadow: UIView!
    
    var originalCenters = [WordView : CGPoint]()
    var timers = [Timer]()
    var state: QuizState = .waiting
    var attempts = 0
    var index = 0 //the index of the previous word in the total array
    
    enum QuizState {
        case waiting, playingQuestion, transitioning
    }
    
    
    //MARK: - Transition
    
    static func presentQuiz(customSound: Sound?, showingThreeWords: Bool, difficulty: Letter.Difficulty?, onController controller: UIViewController) {
        let quiz = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "quiz") as! QuizViewController
        quiz.sound = customSound
        quiz.onlyShowThreeWords = showingThreeWords
        quiz.difficulty = difficulty
        controller.present(quiz, animated: true, completion: nil)
    }
    
    
    //MARK: - Content Setup
    
    override func viewWillAppear(_ animated: Bool) {
        if let sound = self.sound {
            totalAnswerWordPool = sound.allWords
            
            //this starts out the same as Total,
            //but will have values removed if correct on first try
            remainingAnswerWordPool = sound.allWords
        }
        
        if let difficulty = self.difficulty {
            self.view.backgroundColor = difficulty.color
        }
        
        if self.onlyShowThreeWords {
            enum TopLeftLeadingPriority: Float {
                case centerView = 850
                case leftAlignView = 950
                
                var priority: UILayoutPriority {
                    return UILayoutPriority(rawValue: self.rawValue)
                }
            }
            
            self.topLeftWordLeading.priority = TopLeftLeadingPriority.centerView.priority
            self.fourthWord.removeFromSuperview()
            self.interactiveViews.remove(at: self.interactiveViews.index(of: self.fourthWord)!)
            self.wordViews.remove(at: self.wordViews.index(of: self.fourthWord)!)
        }
        
        self.view.layoutIfNeeded()
        sortOutletCollectionByTag(&wordViews)
        wordViews.forEach{ originalCenters[$0] = $0.center }
        
        setupForRandomSoundFromPool()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopAnimations(stopAudio: true)
    }
    
    func setupForRandomSoundFromPool() {
        let isFirst = (currentSound == nil)
        attempts = 0
        
        
        if let sound = self.sound {
            //if there is one specific sound
            
            self.currentSound = sound
            self.currentLetter = PHContent[self.currentSound.sourceLetter]!
            
            if remainingAnswerWordPool.isEmpty {
                //start over from beginning, just in case.
                remainingAnswerWordPool = totalAnswerWordPool
            }
            
            if index >= remainingAnswerWordPool.count {
                //loop from beginning again, but avoiding any First-Try's
                index = 0
            }
            
            answerWord = remainingAnswerWordPool[index]
            index += 1
            
        } else {
            //if global quiz
            
            let randomLetter = PHLetters.random()!
            self.currentLetter = PHContent[randomLetter]
            self.currentSound = self.currentLetter.sounds(for: difficulty ?? .standardDifficulty).random()
            self.answerWord = self.currentSound.allWords.random()
        }
        
        //get other (wrong) word choices
        let allWords = PHContent.allWordsNoDuplicates
        let blacklistedSound = currentSound.ipaPronunciation ?? currentSound.displayString.lowercased()
        let additionalBlacklist = currentSound.blacklist
        
        let possibleWords = allWords.filter { word in
            
            for character in blacklistedSound {
                if word.pronunciation?.contains("\(character)") == true {
                    return false
                }
            }
            
            for blacklist in additionalBlacklist {
                if word.text.lowercased().contains(blacklist) {
                    return false
                }
            }
            
            if let sound = sound, sound.soundId == "schwa" && sound.displayString.lowercased() == "i" {
                //special case: remove hatchet, basket,
                //and any other two- syllable word in which the vowel in the second syllable is a, e, i, or u.
                var vowels = 0
                for letter in word.text {
                    if (letter == "a" || letter == "e" || letter == "i" || letter == "u")
                        || (letter == "o" && vowels == 0) {
                        vowels += 1
                        if vowels > 1 {
                            return false
                        }
                    }
                }
            }
            
            return true
        }
        
        
        var selectedWords: [Word] = [answerWord]
        while selectedWords.count != wordViews.count {
            if let candidateWord = possibleWords.random(), !selectedWords.contains(candidateWord) {
                selectedWords.append(candidateWord)
            }
        }
        
        selectedWords = selectedWords.shuffled()
        
        for (index, wordView) in wordViews.enumerated() {
            wordView.center = self.originalCenters[wordView]!
            wordView.showingText = false
            wordView.layoutIfNeeded()
            wordView.transform = CGAffineTransform.identity
            wordView.alpha = 1.0
            wordView.useWord(selectedWords[index], forSound: currentSound, ofLetter: currentLetter)
        }
        
        soundLabel.text = self.currentSound.displayString.lowercased()
        
        //update puzzle
        puzzleView.puzzleName = self.currentSound.puzzleName
        
        if let puzzle = puzzleView.puzzle {
            let puzzleProgress = Player.current.progress(for: puzzle)
            
            puzzleView.isPieceVisible = puzzleProgress.isPieceOwned
        }
        
        transitionToCurrentSound(isFirst: isFirst)
    }
    
    
    //MARK: - Question Animation
    
    func transitionToCurrentSound(isFirst: Bool) {
        //animate if not first
        if !isFirst {
            var viewsToAnimate = [wordViews.first!.superview!]
            
            //only transition the sound label and puzzle if animating from all sounds
            if self.sound == nil {
                viewsToAnimate.append(self.soundLabel.superview!)
            }
            
            for view in viewsToAnimate {
                playTransitionForView(view, duration: 0.5, transition: kCATransitionPush, subtype: kCATransitionFromTop,
                                      timingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            }
        }
        
        delay(0.5) {
            self.playQuestionAnimation()
        }
    }
    
    func playQuestionAnimation() {
        
        self.state = .playingQuestion
        self.wordViews.first!.superview!.isUserInteractionEnabled = true
        
        var startTime: TimeInterval = 0.0
        let timeBetween = 0.85
        
        Timer.scheduleAfter(startTime, addToArray: &timers) {
            shakeView(self.soundLabel)
        }
        
        Timer.scheduleAfter(startTime - 0.3, addToArray: &timers) {
            PHContent.playAudioForInfo(self.currentSound.pronunciationTiming)
        }
        
        startTime += (self.currentSound.pronunciationTiming?.wordDuration ?? 0.5) + timeBetween
        
        for (index, wordView) in self.wordViews.enumerated() {

            Timer.scheduleAfter(startTime, addToArray: &self.timers) {
                self.playSoundAnimationForWord(index, delayAnimationBy: 0.3)
            }
            
            startTime += (wordView.word?.audioInfo?.wordDuration ?? 0.0) + timeBetween
            
            if (wordView == self.wordViews.last) {
                Timer.scheduleAfter(startTime - timeBetween, addToArray: &self.timers) {
                    self.state = .waiting
                }
            }
        }
    }
    
    func playSoundAnimationForWord(_ index: Int, delayAnimationBy delay: TimeInterval = 0.0, extendAnimationBy extend: TimeInterval = 0.0) {
        if index >= self.wordViews.count { return }
        
        let wordView = self.wordViews[index]
        guard let word = wordView.word else { return }
        word.playAudio()
        
        UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [.allowUserInteraction], animations: {
            wordView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            wordView.alpha = 1.0
        }, completion: nil)
        
        let shrinkDelay = delay + extend + (word.audioInfo?.wordDuration ?? 0.5)
        UIView.animate(withDuration: 0.5, delay: shrinkDelay, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.allowUserInteraction], animations: {
            wordView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func stopAnimations(stopAudio: Bool = true) {
        if self.state != .waiting {
            self.timers.forEach{ $0.invalidate() }
            if stopAudio { UAHaltPlayback() }
            self.state = .waiting
        }
    }
    
    
    //MARK: - User Interaction
    
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func repeatSound(_ sender: UIButton) {
        if self.state == .playingQuestion { return }
        
        sender.isUserInteractionEnabled = false
        delay(1.0) {
            sender.isUserInteractionEnabled = true
        }
        
        //sender.tag = 0  >>  repeat Sound Animation
        //sender.tag = 1  >>  repeat pronunciation
        
        if (sender.tag == 0) {
            playQuestionAnimation()
        } else if sender.tag == 1 {
            PHContent.playAudioForInfo(currentSound.pronunciationTiming)
            shakeView(self.soundLabel)
        }
    }
    
    func wordViewSelected(_ wordView: WordView) {
        self.attempts += 1
        
        // DELETED - may be necessary to avoid clipping, but does not seem to.
        // deleting this is necessary to avoid "jumping" the words superview
        // wordView.superview?.bringSubview(toFront: wordView)
        
        if wordView.word == answerWord {
            if attempts == 1 {
                index -= 1
                if remainingAnswerWordPool != nil {
                    remainingAnswerWordPool.remove(at: index)
                }
            }
            correctWordSelected(wordView)
        } else {
            wordView.setShowingText(true, animated: true)
            shakeView(wordView)
        }
    }
    
    @IBAction func showPuzzleDetail(_ sender: Any) {
        //don't allow the user to show the puzzle during a transition (but allow if spawned from other action)
        if sender is UIButton && self.state == .transitioning { return }
        
        self.view.isUserInteractionEnabled = false
        PuzzleDetailViewController.present(
            for: self.currentSound,
            from: self.puzzleView,
            withPuzzleShadow: self.puzzleShadow,
            in: self,
            onDismiss: {
                self.view.isUserInteractionEnabled = true
                
                if self.dismissOnReturnFromModal {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        )
    }
    
    func correctWordSelected(_ wordView: WordView) {
        self.state = .transitioning
        self.wordViews.first!.superview!.isUserInteractionEnabled = false
        
        wordView.setShowingText(true, animated: true, duration: 0.5)
        
        func hideOtherWords() {
            UIView.animate(withDuration: 0.2, animations: {
                self.wordViews.filter{ $0 != wordView }.forEach{ $0.alpha = 0.0 }
            }) 
        }
        
        func animateAndContinue() {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [.beginFromCurrentState], animations: {
                wordView.center = wordView.superview!.superview!.convert(wordView.superview!.center, to: wordView.superview!)
            }, completion: nil)
            
            PHPlayer.play("correct", ofType: "mp3")
            
            let pieceSpawnPoint = self.view.convert(wordView.center, from: wordView.superview)
            Timer.scheduleAfter(0.8, addToArray: &self.timers, handler: self.addNewPuzzlePiece(spawningAt: pieceSpawnPoint))
            
            var puzzleWasAlreadyComplete = false
            if let puzzle = self.puzzleView.puzzle {
                puzzleWasAlreadyComplete = Player.current.progress(for: puzzle).isComplete
            }
            
            //if the puzzle goes from Incomplete to Complete, show the puzzle detail
            //Otherwise continue to next sound
            Timer.scheduleAfter(1.45, addToArray: &self.timers, handler: {
                
                if !puzzleWasAlreadyComplete, let puzzle = self.puzzleView.puzzle {
                    if Player.current.progress(for: puzzle).isComplete {
                        self.dismissOnReturnFromModal = true
                        self.showPuzzleDetail(self)
                        return
                    }
                }
                
                self.setupForRandomSoundFromPool()
            })
        }
        
        if (UAIsAudioPlaying()) {
            UAWhenDonePlayingAudio {
                hideOtherWords()
                Timer.scheduleAfter(0.1, addToArray: &self.timers, handler: animateAndContinue)
            }
        } else {
            Timer.scheduleAfter(0.45, addToArray: &self.timers, handler: hideOtherWords)
            Timer.scheduleAfter(0.55, addToArray: &self.timers, handler: animateAndContinue)
        }
    }
    
    
    //MARK: - Puzzle Pieces
    
    //partial-application so it can passed as () -> () to Timer.scheduleAfter
    func addNewPuzzlePiece(spawningAt spawnPoint: CGPoint) -> () -> () {
        return {
            guard let puzzle = self.puzzleView.puzzle else { return }
            let progress = Player.current.progress(for: puzzle)
            
            func animate(piece newPiece: (row: Int, col: Int)) {
                
                //find subview for specific piece
                guard let newPieceView = self.puzzleView.subviews.first(where: { subview in
                    guard let pieceView = subview as? PuzzlePieceView else { return false }
                    
                    return (pieceView.piece.row == newPiece.row)
                        && (pieceView.piece.col == newPiece.col)
                }) as? PuzzlePieceView else { return }
                
                //set up initial state
                guard let pieceImageView = newPieceView.imageView else { return }
                let animationImage = UIImageView(image: pieceImageView.image)
                
                let pieceScale: CGFloat = iPad() ? 1.5 : 2.25
                animationImage.alpha = 0.0
                animationImage.frame.size = CGSize(width: pieceImageView.frame.width * pieceScale,
                                                   height: pieceImageView.frame.height * pieceScale)
                animationImage.center = spawnPoint
                
                self.view.addSubview(animationImage)
                
                //animate
                UIView.animate(withDuration: 0.1) {
                    animationImage.alpha = 1.0
                }
                
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
                
                    let finalFrame = self.view.convert(pieceImageView.bounds, from: pieceImageView)
                    animationImage.frame = finalFrame
                    
                }, completion: { _ in
                    animationImage.removeFromSuperview()
                    newPieceView.isHidden = false
                })
                
                
            }
            
            let numberOfPieces: Int
            switch(self.attempts) {
                case 0...1: numberOfPieces = 2
                case 2: numberOfPieces = 1
                default: numberOfPieces = 0
            }
            
            for _ in 0 ..< numberOfPieces {
                if let piece = progress.addRandomPiece() {
                    animate(piece: piece)
                }
            }
            
            Player.current.save()
        }
    }
    
    
    //MARK: - Interactive Grow behavior
    
    override func interactiveGrowScaleFor(_ view: UIView) -> CGFloat {
        return 1.1
    }
    
    override func interactiveViewWilGrow(_ view: UIView) {
        if let wordView = view as? WordView {
            
            if self.state == .playingQuestion {
                self.stopAnimations(stopAudio: false)
            }
            
            wordView.word?.playAudio()
        }
    }
    
    override func shouldAnimateShrinkForInteractiveView(_ view: UIView, isTouchUp: Bool) -> Bool {
        if view is WordView {
            return !isTouchUp
        }
        
        return true
    }
    
    override func totalDurationForInterruptedAnimationOn(_ view: UIView) -> TimeInterval? {
        if let wordView = view as? WordView, let duration = wordView.word?.audioInfo?.wordDuration {
            if wordView.word == self.answerWord { return 4.0 }
            return duration + 0.5
        } else { return 1.0 }
    }
    
    override func touchUpForInteractiveView(_ view: UIView) {
        if let wordView = view as? WordView {
            self.wordViewSelected(wordView)
        }
    }
    
}
