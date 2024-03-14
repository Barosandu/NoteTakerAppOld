//
//  BorderSelection.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 22.04.2022.
//

import Foundation
#if os(iOS)
import UIKit
#endif
var operators = "^+-/*"
var letters = "qwertyuiopasdfghjklzcvbnmx"
var x = "x"
var acolade = "{}"

extension String {
    
    func allIndexes(of charset: String) -> [(i: Int, char: Character)] {
        let chars = Array(self)
        var arr = [(Int, Character)]()
        for (i, char) in chars.enumerated() {
            if charset.contains(where: {$0 == char}) {
                arr.append((i, char))
            }
        }
        return arr
    }
    
    func findClosingBracketIndex(forOpeningIndex ind: Int, openingBracketChar opening: Character = "{", closingBracketChar closing: Character = "}") -> Int {
        let chars = Array(self)
        var alef = 0
        for i in ind..<chars.count {
            if chars[i] == opening {
                alef += 1
            } else if chars[i] == closing {
                alef -= 1
            }
            
            if alef == 0 {
                return i
            }
        }
        return -1
    }
    
    
    func findOpeningBracketIndex(forClosingIndex ind: Int, openingBracketChar opening: Character = "{", closingBracketChar closing: Character = "}") -> Int {
        let chars = Array(self)
        var alef = 0
        var i = ind
        while i >= 0 {
            if chars[i] == opening {
                alef += 1
            }
            if chars[i] == closing {
                alef -= 1
            }
            if alef == 0 {
                return i
            }
            i -= 1
        }
        return -1
    }
    
    subscript(between closedrang: ClosedRange<Int>) -> String {
        get {
            let arr = Array(self)
            var s = ""
            for i in closedrang {
                s.append(arr[i])
            }
            return s
        }
    }
    
    subscript(between openrang: Range<Int>) -> String {
        get {
            let arr = Array(self)
            var s = ""
            for i in openrang {
                s.append(arr[i])
            }
            return s
        }
    }
    
    subscript(before openInd: Int, containing family: String) -> (string: String, firstInd: Int) {
        get {
            let arr = Array(self)
            var s = ""
            
            var i = openInd
            while i >= 0 {
                if family.contains(arr[i]) {
                    s.append(arr[i])
                }
                
                if !family.contains(arr[i]) && arr[i] != "{" && arr[i] != " " {
                    break;
                }
                
                i -= 1
            }
            let sr = s.reversed().map({String($0)}).joined()
            return (sr, i)
        }
    }
    
    func resolveFunctions(openingBracketChar opening: Character, closingBracketChar closing: Character) -> String {
        let arr = Array(self)
//        var lastOpening = 0
        var lastClosing = 0
        var formatString = ""
        var beg = 0
        if self.firstIndex(of: opening) == nil {
            return self
        }
        
        for (n, char) in arr.enumerated() {
            
            if char == opening {
                let openingIndex = n
                let closingIndex = self.findClosingBracketIndex(forOpeningIndex: n)
                let between = self[between: (openingIndex + 1)..<closingIndex]
                let y = self[before: openingIndex, containing: letters]
                let before = y.string
                beg = y.firstInd
                formatString = "FUNCTION(\(between), '\(before)')"
//                lastOpening = openingIndex
                lastClosing = closingIndex
                break
            }
        }
        
        var bef = ""
        var alef = ""
        
        if beg >= 0 {
            bef = self[between: 0...beg]
        }
        
        if lastClosing != self.count - 1 {
            alef = self[between: (lastClosing+1)..<self.count]
        }
        
        var s = ""
        s.append(bef)
        s.append(formatString)
        s.append(alef)
//        //print(s)
        
        return s.resolveFunctions(openingBracketChar: opening, closingBracketChar: closing)
    }
    
}

//extension NSExpressionWithErrorHandler {
//    func getResult(x: Float, y: Float) -> (value: Float, isValid: Bool, isNil: Bool) {
//        let r = self.getResultWithSubstitiutionVariables(["x": NSNumber(floatLiteral: Double(x)), "y": NSNumber(floatLiteral: Double(y))])
//        if r == nil {
//            return (-1, false, false)
//        }
//        return (r!.floatValue, r!.floatValue.isValid(), false)
//    }
//
//    func getResult(x: Float) -> (value: Float, isValid: Bool, isNil: Bool) {
//        let r = self.getResultWithSubstitiutionVariables(["x": NSNumber(floatLiteral: Double(x))])
//        if r == nil {
//            return (-1, false, false)
//        }
//        return (r!.floatValue, r!.floatValue.isValid(), false)
//    }
//}

extension Stroke {
    func pointsForExpression(withStringFormat str1: String, withXFrom lowerXBound: Float = -2, to upperXBound: Float = 2, andYFrom lowerYBound: Float = -2, to upperYBound: Float = 2, insideOffset: CGPoint, insideScale: CGFloat, trueOffset: CGPoint, trueScale: CGFloat) -> (point: [CGPoint], breakAtIndexes: [Int]) {
        let str = str1.replacingOccurrences(of: "{", with: "(").replacingOccurrences(of: "}", with: ")")
        let e = ExpressionEvaluator.initWithExpressionValue(str)
        var x: Float = lowerXBound //+ Float(self.points[0].x)
        let step: Float = 0.01
        var pts = [CGPoint]()
        if e == nil {
            //print("ERROR")
            return ([], []);
        }
        let GRAPHSCALE: Float = 5
        var currInd = 0;
        var breakAt = [Int]()
        if let e = e {
            while x <= upperXBound /*+ Float(self.points[0].x)*/ {
                
                
                let nr = NSNumber(floatLiteral: Double(Int(x * 10 * GRAPHSCALE)) / Double(10 * GRAPHSCALE))
                let result = e.solveExpressionForXEqual(to: nr)
//                //print(Float(Int(x * 100)) / 100.0)
                if let result = result {
                    if !(result.isNil()) {
                        if result.isValid() {
                            if result.floatValue() <= upperYBound && result.floatValue() >= lowerYBound {
                                #if os(macOS)
                                pts.append(CGPoint(
                                    x: CGFloat(10 * GRAPHSCALE * x) + self.points[0].x,
                                    y: CGFloat(10 * GRAPHSCALE * result.floatValue()) + self.points[0].y))
                                #elseif os(iOS)
                                pts.append(CGPoint(
                                    x: CGFloat(10 * GRAPHSCALE * x) + self.points[0].x,
                                    y: -CGFloat(10 * GRAPHSCALE * result.floatValue()) + self.points[0].y))
                                #endif
                                currInd += 1
                            } else {
                                if !breakAt.contains(currInd) {
                                    breakAt.append(currInd)
                                }
                            }
                            
                        } else {
                            if !breakAt.contains(currInd) {
                                breakAt.append(currInd)
                                
                            }
                        }
                    }
            }
                    
                //
                x += step
            }
        }
        
        pts = pts.convertToDefault(scale: trueScale, offset: trueOffset)
        return (pts, breakAt)
    }
    
    
    
    
    
    
    
    
}

extension CGPoint {
    func `is`(inRectangle rect: CGRect) -> Bool {
        let x1 = rect.topLeft.x
        let x2 = rect.bottomRight.x
        
        let y1 = rect.topLeft.y
        let y2 = rect.bottomRight.y
        
        if self.x.is(between: x1, and: x2), self.y.is(between: y1, and: y2) {
            return true
        }
        
        return false
    }
}



