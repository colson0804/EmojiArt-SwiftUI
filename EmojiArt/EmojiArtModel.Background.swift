//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by Craig Olson on 5/6/23.
//

import Foundation

extension EmojiArtModel {
    enum Background {
        case blank
        case url(URL)
        case imageData(Data)
        
        var url: URL? {
            switch self {
            case .url(let url):
                return url
            case .blank, .imageData:
                return nil
            }
        }
        
        var imageData: Data? {
            switch self {
            case .imageData(let data):
                return data
            case .blank, .url:
                return nil
            }
        }
    }
}
