//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/6/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
