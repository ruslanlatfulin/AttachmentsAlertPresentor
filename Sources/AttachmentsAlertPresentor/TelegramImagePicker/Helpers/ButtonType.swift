//
//  ButtonType.swift
//
//
//  Created by Ruslan Latfulin on 11.06.21.
//  Copyright © 2021 Ruslan Latfulin. All rights reserved.
//

#if os(iOS)
import UIKit

enum ButtonType {
    case photoCamera
    case photoLibrary
    case file
    case sendPhotos(count: Int)
    
    var title: String {
        switch self {
        case .photoCamera: return "Сделать фото"
        case .photoLibrary: return "Выбрать из галереи"
        case .file: return "Выбрать документ"
        case .sendPhotos(let count):
            let stringCount = count != 0 ? String(count) : ""
            return String(format: "Отправить %i фото", stringCount)
        }
    }
    
    var font: UIFont {
        switch self {
        case .sendPhotos: return UIFont.boldSystemFont(ofSize: 20)
        default: return UIFont.systemFont(ofSize: 20) }
    }
}
#endif
