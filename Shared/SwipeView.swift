//
//  SwipeView.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 18.04.2022.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

struct PrimaryBackground: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        if self.colorScheme == .dark {
            Color.black
        } else {
            Color.white
        }
    }
}

struct TranslucentBackground: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        #if os(macOS)
            if self.colorScheme == .dark {
                ZStack {
                    
                    Color.black.opacity(0)
                        .background(.thinMaterial, in: Rectangle())
                    Color.black.opacity(0.3)
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                        .background(.thinMaterial, in: Rectangle())
                }
            }
        #elseif os(iOS)
        if self.colorScheme == .dark {
            ZStack {
                
                Color.black.opacity(0)
                    .background(.thinMaterial, in: Rectangle())
            }
        } else {
            ZStack {
                Color.gray.opacity(0)
                    .background(.thinMaterial, in: Rectangle())
            }
        }
        #endif
    }
}

struct HighlightedBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State var cornerRadius: CGFloat = 0
    var body: some View {
        if self.colorScheme == .dark {
            ZStack {
                Color.gray.opacity(0.1)
                
            }.clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
        } else {
            Color.white.opacity(0.5).clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
        }
    }
}
