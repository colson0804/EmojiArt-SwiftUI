//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/6/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    @Environment(\.undoManager) var undoManager
    @State private var selectedEmojiIds = Set<String>()
    @State private var alertToShow: IdentifiableAlert?
    @State private var autoZoom = false
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooserView(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0, 0), geometry: geometry))
                .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTapToRemoveSelection()))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis, id: \.self) { emoji in
                        ZStack {
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .scaleEffect(zoomScale)
                                .position(position(for: emoji, geometry: geometry))
                                .overlay(
                                    VStack {
                                        if selectedEmojiIds.contains(emoji.id) {
                                            Circle()
                                                .stroke(Color.blue, lineWidth: 4)
                                                .frame(width: selectedStateOverlaySize(for: emoji), height: selectedStateOverlaySize(for: emoji))
                                                .position(position(for: emoji, geometry: geometry))
                                        }
                                    }
                                )
                                .onTapGesture {
                                    handleEmojiSelection(emoji)
                                }
                                .gesture(moveEmojiGesture(emoji))
                        }
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, geometry: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                case .idle, .fetching:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autoZoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                UndoButton(
                    undo: undoManager?.optionalUndoMenuItemTitle,
                    redo: undoManager?.optionalRedoMenuItemTitle
                )
            }
        }
    }
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed \(url.absoluteString)", alert: {
            Alert(title: Text("Background Image Fetch"),
                  message: Text("Couldn't load image from \(url)"),
                  dismissButton: .default(Text("OK"))
            )
        })
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            autoZoom = true
            document.setBackground(EmojiArtModel.Background.url(url.imageURL), undoManager: undoManager)
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autoZoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                guard let emoji = string.first, emoji.isEmoji else { return }
                document.addEmoji(String(emoji),
                                  at: convertToEmojiCoordinates(location, geometry: geometry),
                                  size: defaultEmojiFontSize / zoomScale,
                                  undoManager: undoManager)
            }
        }
        
        return found
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func selectedStateOverlaySize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        fontSize(for: emoji) * zoomScale + 10
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), geometry: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        
        return (Int(location.x), Int(location.y))
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    @GestureState private var emojiPanOffset: CGSize = .zero
    
    private func moveEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($emojiPanOffset) { latestDragGestureValue, emojiPanOffset, _ in
                guard selectedEmojiIds.contains(emoji.id) else { return }
                for emoji in document.emojis where selectedEmojiIds.contains(emoji.id) {
                    document.moveEmoji(emoji, by: latestDragGestureValue.translation, undoManager: undoManager)
                }
            }
            .onEnded { finalDragGestureValue in
                guard selectedEmojiIds.contains(emoji.id) else { return }
                        
                for emoji in document.emojis where selectedEmojiIds.contains(emoji.id) {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation, undoManager: undoManager)
                }
            }
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, ourGestureStateInOut, _ in
                ourGestureStateInOut = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func singleTapToRemoveSelection() -> some Gesture {
        TapGesture()
            .onEnded {
                if !selectedEmojiIds.isEmpty {
                    selectedEmojiIds.removeAll()
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        guard let image = image, image.size.width > 0, image.size.height > 0,
            size.width > 0, size.height > 0 else {
                return
            }
        let hZoom = size.width / image.size.width
        let vZoom = size.height / image.size.height
        steadyStatePanOffset = .zero
        steadyStateZoomScale = min(hZoom, vZoom)
    }
    
    private func handleEmojiSelection(_ emoji: EmojiArtModel.Emoji) {
        if selectedEmojiIds.contains(emoji.id) {
            selectedEmojiIds.remove(emoji.id)
        } else {
            selectedEmojiIds.insert(emoji.id)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
