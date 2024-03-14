//
//  UICoreGraphicsTextField.swift
//  NoteTakerApp (iOS)
//
//  Created by Alexandru Ariton on 24.09.2023.
//

import Foundation
import CoreGraphics
import SwiftUI

struct CoreGraphicsTextField: UIViewRepresentable {
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	func makeUIView(context: Context) -> UITextView {
		let textView = theTextView
		textView.delegate = context.coordinator
		NotificationCenter.default.addObserver(forName: .didChangeTextfieldScale, object: nil, queue: nil) { not in
			let obj = not.object as! CGFloat
			self.fontSizeScale = obj
			textView.textStorage.addAttributes([.font: UIFont(name: "Avenir", size: 30 * obj)], range: .init(location: 0, length: textView.attributedText.length))
		}
		textView.textStorage.setAttributedString(text.nsAttributedStringForEditingInTextField(scale: self.fontSizeScale))
		
		
		return theTextView
	}
	
	func updateUIView(_ uiView: UITextView, context: Context) {
		
	}
	
	typealias UIViewType = UITextView
	
	
	var theTextView = UITextView()
	
	@Binding var text: String
	@State var fontSizeScale: CGFloat
	
}

extension CoreGraphicsTextField {
	
	func setAttributedString(to attrStr: NSAttributedString) {
		let range = theTextView.selectedRange
		let textView = (theTextView )
		textView.textStorage.setAttributedString(attrStr)
		theTextView.selectedRange = range
	}
	
	func offsetSelection(by offset: Int) {
		let range = (theTextView as! UITextView).selectedRange
		
		let otherRange = NSRange(location: range.location + offset, length: range.length)
		
		theTextView.selectedRange = otherRange
	}
	
	class Coordinator: NSObject, UITextViewDelegate {
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
		
		
		func textViewDidChange(_ textView: UITextView) {
			let willText = textView.textStorage.string ?? ""
			var pastText = self.parent.text
			
			let selection = self.selectedRangeText
			let oldSelection = self.oldSelectedRangeText
			
			let decidingChar = willText.at(selection.location - 1)
			
			if oldSelection.length >= 1 && (decidingChar == "{" || decidingChar == "[" || decidingChar == "<") {
				pastText.insert(paranthesis: "\(decidingChar)", at: oldSelection)
				self.parent.setAttributedString(to: pastText.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale))
				self.parent.text = pastText
			} else {
				let _attributedString = textView.textStorage.string.nsAttributedStringForEditingInTextField(scale: self.parent.fontSizeScale)
				self.parent.setAttributedString(to: _attributedString)
				self.parent.text = textView.textStorage.string
			}
			NotificationCenter.default.post(name: .iOSTextFieldTextChanged, object: nil)
		}
		
		func textViewDidChangeSelection(_ textView: UITextView) {
			self.oldSelectedRangeText = textView.selectedRange
			self.selectedRangeText = textView.selectedRange
			
		}
		
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			return true
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
	}
}

#if os(iOS)
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
								fontSizeScale: (geo.size.width / (ln()?.textValue.stringSizeAtAvenir30(context: nil).width ?? 10)))
						.textFieldStyle(.plain)
						.foregroundColor(Color(ln()?.color ?? .red))
						.background(.ultraThinMaterial, in: Rectangle())
						.border(Color(ln()?.color ?? .blue))
						.onChange(of: (geo.size.width / (ln()?.textValue.stringSizeAtAvenir30(context: nil).width ?? 10))) { newValue in
							NotificationCenter.default.post(name: .didChangeTextfieldScale, object: newValue)
						}
				}
			}
		}
	}
}
#endif

