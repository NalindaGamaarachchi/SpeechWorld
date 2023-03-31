//
//  PuzzleProgress.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Cal Stephens. All rights reserved.
//

import Foundation

class PuzzleProgress: NSObject, NSCoding {
    
    let puzzleName: String
    var ownedPieces: [[Bool]]
    
    var isComplete: Bool {
        return numberOfPieces == numberOfOwnedPieces
    }
    
    var numberOfPieces: Int {
        return ownedPieces.reduce(0) { previous, column in
            return column.count + previous
        }
    }
    
    var numberOfOwnedPieces: Int {
        return ownedPieces.reduce(0) { previousForRow, column in
            return previousForRow + column.reduce(0) { previousForCol, piece in
                return previousForCol + (piece ? 1 : 0)
            }
        }
    }
    
    init(newFor puzzle: Puzzle) {
        self.puzzleName = puzzle.name
        
        let emptyColumn = [Bool](repeating: false, count: puzzle.colCount)
        self.ownedPieces = [[Bool]](repeating: emptyColumn, count: puzzle.rowCount)
        
        super.init()
    }
    
    @discardableResult func addRandomPiece() -> (row: Int, col: Int)? {
        var unownedPieces = [(row: Int, col: Int)]()
        
        for (row, wholeColumn) in ownedPieces.enumerated() {
            for (col, isOwnedByPlayer) in wholeColumn.enumerated() {
                if !isOwnedByPlayer {
                    unownedPieces.append((row, col))
                }
            }
        }
        
        let piece = unownedPieces.random()
        if let piece = piece {
            self.ownedPieces[piece.row][piece.col] = true
        }
        
        return piece
    }
    
    func isPieceOwned(row: Int, col: Int) -> Bool {
        let rowCount = self.ownedPieces.count
        let colCount = self.ownedPieces.first?.count ?? 0
        
        if row < 0 || row >= rowCount { return false }
        if col < 0 || col >= colCount { return false }
        return self.ownedPieces[row][col]
    }
    
    
    //MARK: - NSCoding
    
    enum Key: String, NSCodingKey {
        case puzzleName = "PuzzleProgress.puzzleName"
        case ownedPieces = "PuzzleProgress.ownedPieces"
    }
    
    required init?(coder decoder: NSCoder) {
        guard let puzzleName = decoder.value(for: Key.puzzleName) as? String else { return nil }
        self.puzzleName = puzzleName
        
        guard let ownedPieces = decoder.value(for: Key.ownedPieces) as? [[Bool]] else { return nil }
        self.ownedPieces = ownedPieces
    }
    
    func encode(with encoder: NSCoder) {
        encoder.setValue(self.puzzleName, for: Key.puzzleName)
        encoder.setValue(self.ownedPieces, for: Key.ownedPieces)
    }
    
}


//MARK: - Accessor

extension Player {
    
    func progress(for puzzle: Puzzle) -> PuzzleProgress {
        if let progress = self.progress(forPuzzleNamed: puzzle.name) {
            return progress
        } else {
            let newProgress = PuzzleProgress(newFor: puzzle)
            self.puzzleProgress[puzzle.name] = newProgress
            return newProgress
        }
    }
    
    func progress(forPuzzleNamed name: String) -> PuzzleProgress? {
        return self.puzzleProgress[name]
    }
    
    func soundsByPuzzleCompletion(with difficulty: Letter.Difficulty) -> (complete: [Sound], incomplete: [Sound]) {
        let allSounds = PHContent.allSoundsSorted(with: difficulty)
        
        let complete = allSounds.filter { sound in
            guard let progress = self.progress(forPuzzleNamed: sound.puzzleName) else { return false }
            return progress.isComplete
        }
        
        let incomplete = allSounds.filter { sound in
            guard let progress = self.progress(forPuzzleNamed: sound.puzzleName) else { return true }
            return !progress.isComplete
        }
        
        return (complete, incomplete)
    }
    
}
