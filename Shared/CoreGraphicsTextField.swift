//
//  CoreGraphicsTextField.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 05.07.2022.
//

import Foundation
import CoreGraphics
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct CoreGraphicsTextField: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    var theTextView = NSTextView.scrollableTextView()
    
    @Binding var text: String
    @State var fontSizeScale: CGFloat
    
    func setAttributedString(to attrStr: NSAttributedString) {
//        let location = (theTextView.documentView as! NSTextView).selectedRange().location
        let range = (theTextView.documentView as! NSTextView).selectedRange()
        
        let textView = (theTextView.documentView as! NSTextView)
        textView.textStorage?.setAttributedString(attrStr)
        
//        let location2 = (theTextView.documentView as! NSTextView).selectedRange().location
        
        (theTextView.documentView as! NSTextView).setSelectedRange(range)
        
        
    }
    
    func offsetSelection(by offset: Int) {
        let range = (theTextView.documentView as! NSTextView).selectedRange()
        
        let otherRange = NSRange(location: range.location + offset, length: range.length)
        
        (theTextView.documentView as! NSTextView).setSelectedRange(otherRange)
    }
    
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = (theTextView.documentView as! NSTextView)
        textView.delegate = context.coordinator
        NotificationCenter.default.addObserver(forName: .didChangeTextfieldScale, object: nil, queue: nil) { not in
            let obj = not.object as! CGFloat
            self.fontSizeScale = obj
//            print(self.fontSizeScale)
            textView.textStorage?.addAttributes([.font: NSFont(name: "Avenir", size: 30 * obj)], range: .init(location: 0, length: textView.attributedString().length))
        }
        textView.textStorage?.setAttributedString(text.nsAttributedStringForEditingInTextField(scale: self.fontSizeScale))
        
        
        return theTextView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
    }
    
    
}

extension CoreGraphicsTextField {
    
    class Coordinator: NSObject, NSTextViewDelegate {
        
        var parent: CoreGraphicsTextField
        var affectedCharRange: NSRange?
        var selectedRangeText: NSRange = NSRange()
        var oldSelectedRangeText: NSRange = NSRange()
        init(_ parent: CoreGraphicsTextField) {
            
            self.parent = parent
            super.init()
            
//            print("Removed")
            NotificationCenter.default.removeObserver(self, name: .encircleSelectionWithCaracters, object: nil)
//            print("added")
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleTextBUI(_:)), name: .encircleSelectionWithCaracters, object: nil)
        }
        
        
        
        @objc func handleTextBUI(_ notification: Notification) {
            let obj = notification.object as! String
            let range = self.selectedRangeText
            
            
            let ind0 = range.location - 1
            let ind1 = range.upperBound
            
            if (ind0 < 0 || ind1 >= self.parent.text.count) {
//                print("AAA")
                self.parent.text.insert(contentsOf: "\(obj.at(0))", at: self.parent.text.index(self.parent.text.startIndex, offsetBy: range.location))
                
                self.parent.text.insert(contentsOf: "\(obj.at(1))", at: self.parent.text.index(self.parent.text.startIndex, offsetBy: range.location + range.length + 1))
                
                
                self.parent.setAttributedString(to: self.parent.text.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale))
                
                self.parent.offsetSelection(by: 1)
                return
            }
            if self.parent.text.at(ind0) == obj.at(0) && self.parent.text.at(ind1) == obj.at(1) {
                self.parent.text.remove(atInt: ind0)
                self.parent.text.remove(atInt: ind1 - 1)
                self.parent.setAttributedString(to: self.parent.text.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale))
                self.parent.offsetSelection(by: -1)
            } else {
                self.parent.text.insert(contentsOf: "\(obj.at(0))", at: self.parent.text.index(self.parent.text.startIndex, offsetBy: range.location))
                
                self.parent.text.insert(contentsOf: "\(obj.at(1))", at: self.parent.text.index(self.parent.text.startIndex, offsetBy: range.location + range.length + 1))
                
                
                self.parent.setAttributedString(to: self.parent.text.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale))
                
                self.parent.offsetSelection(by: 1)
            }
        }
        

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            
            let willText = textView.textStorage?.string ?? ""
            var pastText = self.parent.text
            
            let selection = self.selectedRangeText
            let oldSelection = self.oldSelectedRangeText
            
            let decidingChar = willText.at(selection.location - 1)
            
            if oldSelection.length >= 1 && (decidingChar == "{" || decidingChar == "[" || decidingChar == "<") {
                pastText.insert(paranthesis: "\(decidingChar)", at: oldSelection)
                self.parent.setAttributedString(to: pastText.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale))
                self.parent.text = pastText
            } else {
                let _attributedString = textView.string.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale)
                self.parent.setAttributedString(to: _attributedString)
                self.parent.text = textView.string
            }
        }
        
        
        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            self.oldSelectedRangeText = oldSelectedCharRange
            self.selectedRangeText = newSelectedCharRange
            return newSelectedCharRange
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
        
        
    }
    
    
}

//MARK: TEXTFIELD VIEW



struct SelectedTextFieldView: View {
    var line: Stroke
    @EnvironmentObject var scrollEnv: ScrollEnv
    var trueScale: CGFloat
    @State var stest: String = "no"
    @State var textSelection = NSRange()
    
    func ln() -> Stroke? {
        self.scrollEnv.strokes.first(where: {$0.id == line.id})
    }
    
    var body: some View {
        return VStack {
            
            GeometryReader { geo in
                VStack {
                    CoreGraphicsTextField(text: self.$scrollEnv.selectedTextText,
                                fontSizeScale: (geo.size.width / (ln()?.textValue.stringSizeAtAvenir30.width ?? 10)))
                        .textFieldStyle(.plain)
                        .foregroundColor(Color(ln()?.color ?? .red))
                        .background(.ultraThinMaterial, in: Rectangle())
                        .border(Color(nsColor: ln()?.color ?? .blue))
                        .onChange(of: (geo.size.width / (ln()?.textValue.stringSizeAtAvenir30.width ?? 10))) { newValue in
                            NotificationCenter.default.post(name: .didChangeTextfieldScale, object: newValue)
                        }
                }
            }
        }
    }
}
