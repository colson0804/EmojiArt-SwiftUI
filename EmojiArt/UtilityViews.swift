//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/7/23.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}
