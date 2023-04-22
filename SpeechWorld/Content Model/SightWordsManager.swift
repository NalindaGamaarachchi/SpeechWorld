//
//  SightWordsManager.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

import Foundation

class SightWordsManager {
    
    
    //MARK: - Categories
    
    public enum Category {
        case preK, kindergarten
        
        var color: UIColor {
            switch(self) {
            case .preK: return #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
            case .kindergarten: return #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
            }
        }
        
        private var folderNamePrefix: String {
            switch(self) {
            case .preK: return "Pre-K Sight Words"
            case .kindergarten: return "Kindergarten Sight Words"
            }
        }
        
        var audioFolderName: String {
            return self.folderNamePrefix
        }
        
        var imageFolderName: String {
            return self.folderNamePrefix + " Art"
        }
        
        func individualAudioFilePath(for word: SightWord) -> String {
            return self.audioFolderName + "/Individual Words/" + word.text.lowercased()
        }
    }
    
    
    //MARK: - Setup
    
    let category: Category
    let words: [SightWord]
    
    public init(category: Category) {
        self.category = category
        
        guard let mainResourcePath = Bundle.main.resourcePath else {
            self.words = []
            return
        }
        
        let audioFolder = mainResourcePath.appending("/" + category.audioFolderName)
        let imageFolder = mainResourcePath.appending("/" + category.imageFolderName)
        
        let audioFiles = (try? FileManager.default.contentsOfDirectory(atPath: audioFolder)) ?? []
        let imageFiles = (try? FileManager.default.contentsOfDirectory(atPath: imageFolder)) ?? []
        
        
        
        self.words = SightWordsManager.buildSightWords(fromAudio: audioFiles, andImages: imageFiles, for: category)
    }
    
    static func buildSightWords(fromAudio audioFiles: [String],
                                andImages allImageFiles: [String],
                                for category: Category) -> [SightWord] {
        
        var imageFiles = allImageFiles
        
        var completedWords = [SightWord]()
        var temporarySentences = [String : Sentence]()
        
        for audioFileNameWithEnding in audioFiles {
            //audioFileNameWithEnding format: "word-# (Sentence here).mp3"
            guard let audioFileName = audioFileNameWithEnding.components(separatedBy: ".").first else { continue }
            guard let metadata = audioFileName.components(separatedBy: " ").first else { continue }
            guard let highlightWord = metadata.components(separatedBy: "-").first else { continue }
            
            var sentenceText = audioFileName.replacingOccurrences(of: metadata + " ", with: "")
            sentenceText = sentenceText.replacingOccurrences(of: ";", with: ".")
            
            guard let indexOfImageWithSameMetadata = imageFiles.index(where: { $0.hasPrefix(metadata) }) else { continue }
            let imageFileName = imageFiles.remove(at: indexOfImageWithSameMetadata)
            
            let newSentence = Sentence(text: sentenceText,
                                       highlightWord: highlightWord,
                                       audioFileName: category.audioFolderName + "/" + audioFileName,
                                       imageFileName: category.imageFolderName + "/" + imageFileName)
            
            //build completed SightWord
            if let otherSentence = temporarySentences[highlightWord] {
                let newSightWord = SightWord(text: highlightWord, sentence1: otherSentence, sentence2: newSentence)
                completedWords.append(newSightWord)
                temporarySentences.removeValue(forKey: highlightWord)
            } else {
                temporarySentences[highlightWord] = newSentence
            }
        }
        
        if temporarySentences.count != 0 {
            print("\nSOME TEMPORARY SENTENCES WEREN'T ASSIGNED TO WORDS (missing their partner):")
            temporarySentences.forEach {
                print("\($0.key): \($0.value.text)")
            }
            print()
        }
        
        return completedWords.sorted(by: { left, right in
            left.text.lowercased() < right.text.lowercased()
        })
    }
    
}
