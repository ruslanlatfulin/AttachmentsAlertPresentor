//
//  AttachmentSource.swift
//  investmoscow
//
//  Created by Ruslan Latfulin on 11.06.21.
//  Copyright © 2021 Dima Shelkov. All rights reserved.
//

import Foundation

enum AttachmentSource {
    case photoCamera
    case photoLibrary
    case document
    
    var title: String {
        switch self {
        case .photoCamera:  return "Сделать фото"
        case .photoLibrary: return "Выбрать из галереи"
        case .document:     return "Выбрать документ"
        }
    }
}
