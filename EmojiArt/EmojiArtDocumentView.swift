//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/6/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            pallette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .position(convertFromEmojiCoordinates((0, 0), geometry: geometry))
                )
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                }
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .font(.system(size: fontSize(for: emoji)))
                        .position(position(for: emoji, geometry: geometry))
                }
            }
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, geometry: geometry)
            }
        }
    }
    
    var pallette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                guard let emoji = string.first, emoji.isEmoji else { return }
                document.addEmoji(String(emoji), at: convertToEmojiCoordinates(location, geometry: geometry), size: defaultEmojiFontSize)
            }
        }
        
        return found
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), geometry: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x),
            y: center.y + CGFloat(location.y)
        )
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: location.x - center.x,
            y: location.y - center.y
        )
        
        return (Int(location.x), Int(location.y))
    }
    
    private let testEmojis = "🦁🦉🪲🌷🌝🥨🍸🍭🏈🚘🦼🧨🦁🦉🪲🌷🌝🥨🍸🍭🏈🚘🦼🧨🦁🦉🪲🌷🌝🥨🍸🍭🏈🚘🦼🧨"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
