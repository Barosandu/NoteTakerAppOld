//
//  Textensions.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 04.05.2022.
//

import Foundation
import SwiftUI



extension String {
    static var parantheses = ["{": "}", "[": "]", "<": ">"]
    static var CHARWIDTH: Int = 13
    static var CHARHEIGHT: Int = 40
    static var BIAS: CGFloat = 0
    func at(_ ind: Int) -> String.Element {
		if self.count == 0 {
			return Character(".");
		}
        return self[self.index(self.startIndex, offsetBy: ind)]
    }
    
    mutating func remove(atInt index: Int) {
        self.remove(at: self.index(self.startIndex, offsetBy: index))
    }
    
    mutating func insert(paranthesis: String, at range: NSRange) {
        let closing = Self.parantheses[paranthesis]!
        self.insert(contentsOf: "\(closing)", at: self.index(self.startIndex, offsetBy: range.upperBound))
        self.insert(contentsOf: "\(paranthesis)", at: self.index(self.startIndex, offsetBy: range.location))
    }
    
    var lineCount: Int {
        get {
            return self.filter({$0 == "\n"}).count + 1
        }
    }
    
    var columnCount: Int {
        get {
            return self.split(separator: "\n").max(by: {$0.count < $1.count})?.count ?? 1
        }
    }
}

extension String {
    func textension() -> Text {
        Text(self)
        
    }
}

#if os(macOS)
typealias XImage = NSImage
#elseif os(iOS)
typealias XImage = UIImage
#endif

#if os(macOS)
extension String {
    var stringSizeAtAvenir30: CGSize {
        get {
            var textString: NSString = NSString(string: self)
            var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: NSFont(name: "Avenir", size: 30)!])
            
            let size = CGSize(width: labelSize.size.width + WIDTHTEXTBIAS, height: labelSize.size.height + WIDTHTEXTBIAS)
            return size
        }
    }
    
    func stringSize(fontName: String = "Avenir", fontSize: CGFloat = 30) -> CGSize {
        var textString: NSString = NSString(string: self)
        var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: NSFont(name: "Avenir", size: 30)!])
        
        let size = labelSize.size
        return size
    }
}

typealias XFont = NSFont
#elseif os(iOS)
var WIDTHTEXTBIAS: CGFloat = 50
typealias XFont = UIFont
extension String {
	func stringSizeAtAvenir30(context: NSStringDrawingContext?) -> CGSize {
			var textString: NSString = NSString(string: self)
			var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont(name: "Avenir", size: 30)!], context: context)
			
			let size = CGSize(width: labelSize.size.width + WIDTHTEXTBIAS, height: labelSize.size.height + WIDTHTEXTBIAS)
			return size
		
	}
	
	func stringSize(fontName: String = "Avenir", fontSize: CGFloat = 30, context: NSStringDrawingContext) -> CGSize {
		var textString: NSString = NSString(string: self)
		var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont(name: "Avenir", size: 30)!], context: context)
		
		let size = labelSize.size
		return size
	}
}
#endif

extension Stroke {
    func rect(s: CGFloat) -> CGRect {
        
        if self.typeOfStroke == .text {
            let str = self.textValue
//            let size: CGSize = .init(width: CGFloat(str.columnCount * String.CHARWIDTH) * s , height: CGFloat(String.CHARHEIGHT * str.lineCount) * s)
            
            
            var textString: NSString = NSString(string: self.textValue)
			var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: XFont(name: "Avenir", size: 30 * s)!], context: nil)
            
            let size = labelSize.size
            
            
            return CGRect(origin: self.points[0] + .init(x: 0, y: -String.BIAS * s - size.height), size: size)
        }
        
        if self.typeOfStroke == .image {
            if let imageData = imageData {
                let image = XImage(data: imageData)!
                return CGRect(origin: self.points[0] - .init(x: 10 * s, y: 10 * s), size: .init(width: image.size.width / 5 * s + 20 * s, height: image.size.height / 5 * s + 20 * s))
            }
        }
        
        if self.typeOfStroke != .rectangle && self.typeOfStroke != .circle && self.typeOfStroke != .graph {
            var minx: CGFloat = .infinity
            var miny: CGFloat = .infinity
            var maxx: CGFloat = -1 * .infinity
            var maxy: CGFloat = -1 * .infinity
            
            self.points.forEach { pt in
                if minx > pt.x {
                    minx = pt.x
                }
                if miny > pt.y {
                    miny = pt.y
                }
                if maxx < pt.x {
                    maxx = pt.x
                }
                
                if maxy < pt.y {
                    maxy = pt.y
                }
                
            }
            let size = CGSize(width: abs(maxx - minx) + 10 * s, height: abs(maxy - miny) + 10 * s)
        
            return CGRect(origin: CGPoint(x: minx - 5 * s, y: miny - 5 * s), size: size)
        } else if self.typeOfStroke != .graph {
            guard self.points.count >= 2 else {
                return CGRect(origin: .zero, size: .zero)
            }
            
            
            let w = self.points[1].x - self.points[0].x
            let h = self.points[1].y - self.points[0].y
            
            let p0 = CGPoint(x: self.points[0].x - 5 * (w > 0 ? 1 : -1), y: self.points[0].y - 5 * (h > 0 ? 1 : -1))
            
            return CGRect(origin: p0, size: CGSize(width: w + 10 * (w > 0 ? 1 : -1), height: h + 10 * (h > 0 ? 1 : -1)))
        } else {
            let GRAPHSCALE: CGFloat = 5
            return CGRect(x: self.points[0].x - 24 * GRAPHSCALE * s, y: self.points[0].y - 24 * GRAPHSCALE * s, width: 48 * GRAPHSCALE * s, height: 58 * GRAPHSCALE * s)
        }
        
    }
}
