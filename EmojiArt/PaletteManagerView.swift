//
//  PaletteManagerView.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/12/23.
//

import SwiftUI

struct PaletteManagerView: View {
    @EnvironmentObject var store: PaletteStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink(destination: PaletteEditorView(palette: $store.palettes[palette])) {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                            Text(palette.emojis)
                        }
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .dismissable {
                presentationMode.wrappedValue.dismiss()
            }
            .toolbar {
                ToolbarItem { EditButton() }
            }
            .environment(\.editMode, $editMode)
        }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {  }
    }
}

struct PaletteManagerView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManagerView()
            .previewDevice("iPhone 14")
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
