//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/6/23.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()
    
    init() {}
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try .init(json: data)
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        let id: String
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: String) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: UUID().uuidString))
    }
}

