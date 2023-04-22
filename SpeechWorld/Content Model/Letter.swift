//
//  Letter.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Nalinda Gamaarachchi. All rights reserved.
//

struct Letter: Equatable {
    
    enum Difficulty {
        case easyDifficulty //only show the first sound. Alphabet Letters.
        case standardDifficulty //show all sounds.
        
        var color: UIColor {
            switch(self) {
            case .easyDifficulty: return #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
            case .standardDifficulty: return #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
            }
        }
    }
    
    
    let text: String
    private let sounds: [Sound]
    
    init(text: String, sounds: [Sound]) {
        self.text = text
        self.sounds = sounds
    }
    
    
    func sounds(for difficulty: Difficulty) -> [Sound] {
        if difficulty == .easyDifficulty {
            return [self.sounds.first!]
        } else {
            return self.sounds
        }
    }
    
    subscript(soundId: String) -> Sound! {
        return sounds.filter{ $0.soundId == soundId }.first
    }
    
    var isComplete: Bool {
        for sound in sounds {
            if !sound.puzzleIsComplete {
                return false
            }
        }
        
        return true
    }
    
    var thumbnail : UIImage {
        let imageName = "easy-letter-icon-\(text.lowercased()).jpg"
        
        if let thumbnail = UIImage.thumbnail(for: imageName) {
            return thumbnail
        }
        
        return UIImage(named: imageName)!
    }
    
    var audioInfo: AudioInfo? {
        //most letters exist through the sound files -- check if that exists
        if let soundWithAudioForLetter = sounds.first(where: { $0.sourceLetterTiming != nil }) {
            return soundWithAudioForLetter.sourceLetterTiming
        }
        
        //if the letter doesn't exist in the sound files, it should be in "Assets > Audio > Sounds > Extra Letters"
        let extraLetterAudioFile = "extra-letter-\(self.text.uppercased())"
        let duration = UALengthOfFile(extraLetterAudioFile, ofType: "mp3")
        
        if duration != 0 {
            return (fileName: extraLetterAudioFile, wordStart: 0.0, wordDuration: duration)
        } else {
            return nil
        }
    }
    
    func playAudio() {
        if let audioInfo = self.audioInfo {
            PHContent.playAudioForInfo(audioInfo)
        } else {
            print("No audio for \(self.text.uppercased())")
        }
    }
    
}

func ==(left: Letter, right: Letter) -> Bool {
    return left.text == right.text
}
