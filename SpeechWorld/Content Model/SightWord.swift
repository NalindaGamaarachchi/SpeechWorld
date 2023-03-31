//
//  SightWord.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Cal Stephens. All rights reserved.
//

import Foundation
import AVFoundation

public struct SightWord : Equatable {
    
    var text: String
    var sentence1: Sentence
    var sentence2: Sentence
    
    func playAudio(using manager: SightWordsManager) {
        let audioPath = manager.category.individualAudioFilePath(for: self)
        PHPlayer.play(audioPath, ofType: "mp3")
    }
    
    
    //MARK: - Homophone analysis
    
    static let homophoneGroups = [
        ["to", "too", "two"]
    ]
    
    func hasHomophoneConflict(withWords otherWords: [SightWord]) -> Bool {
        if let homophoneGroup = SightWord.homophoneGroups.first(where: { $0.contains(text) }) {
            for homophone in homophoneGroup {
                if homophone != self.text && otherWords.contains(where: { $0.text == homophone }) {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func arrayHasHomophoneConflicts(_ array: [SightWord]) -> Bool {
        for word in array {
            if word.hasHomophoneConflict(withWords: array) {
                return true
            }
        }
        
        return false
    }

}

public func ==(left: SightWord, right: SightWord) -> Bool {
    return left.text == right.text
}
