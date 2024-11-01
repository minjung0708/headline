//
//  Color+Extension.swift
//  headline
//
//  Created by MinJung on 11/1/24.
//

import Foundation
import SwiftUI

extension Color {
    enum ScrollView {
        static let background = Color("ScrollViewBackground")
    }
    
    enum Item {
        static let background = Color("ItemBackground")
        
        enum Text {
            static let title = Color("ItemTextTitle")
            static let publishedAt = Color("ItemTextPublishedAt")
        }
        
        enum Image {
            static let background = Color("ItemImageBackground")
        }
    }
    
    enum Toast {
        static let background = Color("ToastBackground")
        
        enum Text {
            static let content = Color("ToastTextContent")
        }
    }
}
