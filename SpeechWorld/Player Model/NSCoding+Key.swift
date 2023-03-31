//
//  NSCodingKey.swift
//  SpeechWorld
//
//  Created by Nalinda on 31/3/2023.
//  Copyright © 2023 Cal Stephens. All rights reserved.
//
import Foundation

//Any String enum can conform to this protocol
protocol NSCodingKey {
    var rawValue: String { get }
}

extension NSCoder {
    
    func value(for key: NSCodingKey) -> Any? {
        return decodeObject(forKey: key.rawValue)
    }
    
    func setValue(_ value: Any?, for key: NSCodingKey) {
        self.encode(value, forKey: key.rawValue)
    }
    
}
