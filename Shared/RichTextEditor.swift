//
//  RichTextEditor.swift
//  NoteTakerApp (iOS)
//
//  Created by Alexandru Ariton on 09.09.2022.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
import SwiftUI
public protocol RichTextFieldRepresentable {
    var attributedString: NSAttributedString { get }
    
}

public class RichTextView: NSTextView, RichTextFieldRepresentable {
    public var attributedString: NSAttributedString {
        get {
            attributedString()
        }
        
        set {
            textStorage?.setAttributedString(newValue)
        }
    }
    
    
}


public struct RichTextEditor: NSViewRepresentable {
    public init(text: Binding<NSAttributedString>) {
        self._attributedString = text
    }
    
    
    @Binding
    public var attributedString: NSAttributedString
    
    public let scrollView = RichTextView.scrollableTextView()
    
    public var textView: RichTextView {
        scrollView.documentView as? RichTextView ?? RichTextView()
    }

    
    public func makeNSView(context: Context) -> some NSView {
        textView.attributedString = attributedString
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
    
    
}


