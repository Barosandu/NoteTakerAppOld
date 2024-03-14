//
//  Extensions.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 04.05.2022.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

extension CGPoint: Identifiable {
    public var id: String {
        return "\(self.x)|\(self.y)|\(UUID())"
    }
}

extension Array where Element == CGPoint {
    func scale(by sc: CGFloat, around p: CGPoint) -> Self {
        return self.map { pt in
            CGPoint(x: sc * (pt.x - p.x) + p.x, y: sc * (pt.y - p.y) + p.y)
        }
    }
}

extension Array {
    func combined(with elem: Array.Element) -> [Array.Element] {
        var arr = self
        arr.append(elem)
        return arr
    }
    
    func except(ind: Int) -> Self {
        var arr = [Element]()
        for (n, elem) in self.enumerated() {
            if n != ind {
                arr.append(elem)
            }
        }
        return arr
    }
    
    func split(by indexes: [Int]) -> [Self] {
        var fin = [Self]()
        var arr = [Element]()
        for (n, elem) in self.enumerated() {
            if indexes.contains(n) {
                fin.append(arr)
                arr = [elem]
            } else {
                arr.append(elem)
            }
            if n == self.count - 1 {
                fin.append(arr)
                break
            }
        }
        return fin
    }
}

extension XColor {
    func getComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        #if os(macOS)
        let c = CIColor(color: self)!
        #elseif os(iOS)
        let c = CIColor(color: self)
        #endif
        return (c.red, c.green, c.blue, c.alpha)
    }
}

extension GraphicsContext {
    func drawRoundedRectangle(in rect: CGRect, cornerRadius: CGFloat, with shading: Shading) {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        self.fill(path, with: shading)
    }
    
    
}



enum Math {
    static func calculateOffset(fromMouseScale ms: CGFloat, andOldOffset oldoff: CGPoint, withMousePosition mousePos: CGPoint) -> CGPoint {
        let x = ms * oldoff.x - (ms - 1) * mousePos.x
        let y = ms * oldoff.y - (ms - 1) * mousePos.y
        return CGPoint(x: x, y: y)
    }
    
    
    static func calculateOffsetIOS(fromMouseScale ms: CGFloat, andOldOffset oldoff: CGPoint, withMousePosition mousePos: CGPoint) -> CGPoint {
        let x = oldoff.x
        let y = oldoff.y
        return CGPoint(x: x, y: y)
    }
    
    static func calculateOffsetGraph(fromMouseScale ms: CGFloat, andOldOffset oldoff: CGPoint, withMousePosition mousePos: CGPoint) -> CGPoint {
        let x = ms * oldoff.x - (ms - 1) * mousePos.x
        let y = ms * oldoff.y - (ms - 1) * mousePos.y
        return CGPoint(x: x, y: y)
    }
    
    static func calculateScale(fromMouseScale ms: CGFloat, andOldScale s: CGFloat) -> CGFloat {
        return ms * s
    }
    
    static func calculateScaleGraph(fromMouseScale ms: CGFloat, andOldScale s: CGFloat) -> CGFloat {
        return ms * s
    }
}

extension Array where Element == CGPoint {
    func transformed(by s: CGSize, scale: CGFloat, offset: CGPoint) -> Self {
        let arr = self.map { cgp -> CGPoint in
            let pconv = cgp.convertTo(scale: scale, andOffset: offset)
            let pp = CGPoint(x: pconv.x + s.width, y: pconv.y + s.height)
            let r = pp.convertToDefault(scale: scale, offset: offset)
            return r
        }
        return arr
    }
    
    mutating func transform(by s: CGSize, scale: CGFloat, offset: CGPoint) {
        let arr = self.map { cgp -> CGPoint in
            let pconv = cgp.convertTo(scale: scale, andOffset: offset)
            let pp = CGPoint(x: pconv.x + s.width, y: pconv.y + s.height)
            let r = pp.convertToDefault(scale: scale, offset: offset)
            return r
        }
        self = arr
    }
}

extension Array where Element == CGPoint {
    func convertToDefault(scale: CGFloat, offset: CGPoint) -> Self {
        let newPoints = self.map { pt -> CGPoint in
            let pdefx = (pt.x - offset.x) / scale
            let pdefy = (pt.y - offset.y) / scale
            return CGPoint(x: pdefx, y: pdefy)
        }
        return newPoints
    }
    
    func convertTo(scale: CGFloat, andOffset offset: CGPoint) -> Self {
        let newPoints = self.map { pdef -> CGPoint in
            let px = pdef.x * scale + offset.x
            let py = pdef.y * scale + offset.y
            return CGPoint(x: px, y: py)
        }
        return newPoints
    }
}

extension CGPoint {
    func convertToDefault(scale: CGFloat, offset: CGPoint) -> Self {
        let pdefx = (self.x - offset.x) / scale
        let pdefy = (self.y - offset.y) / scale
        return CGPoint(x: pdefx, y: pdefy)
    }
    
    func convertTo(scale: CGFloat, andOffset offset: CGPoint) -> Self {
        let px = self.x * scale + offset.x
        let py = self.y * scale + offset.y
        return CGPoint(x: px, y: py)
    }
}

extension Array where Element == Int {
    func toString() -> String {
        var str = ""
        for (_, elem) in self.enumerated() {
            str.append(contentsOf: "\(elem)|")
        }
        return str
    }
}

extension String {
    func toIntArray() -> [Int] {
        var ia = [Int]()
        for ss in self.split(separator: "|") {
            
            ia.append(Int(ss) ?? 0)
        }
        return ia
    }
}

public class CGPointArray: NSObject {
    var arr: [CGPoint]
    init(_ arr: [CGPoint]) {
        self.arr = arr
    }
    
    func toString() -> String {
        var str = ""
        for (_, elem) in self.arr.enumerated() {
            str.append(contentsOf: "\(elem.x) \(elem.y)|")
        }
        return str
    }
    
    func convertToDefault(scale: CGFloat, offset: CGPoint) -> CGPointArray {
		var pts = Array<CGPoint>(repeating: .zero, count: self.arr.count)
		DispatchQueue.concurrentPerform(iterations: self.arr.count) { i in
			pts[i] = self.arr[i]
		}
        let newPoints = self.arr.map { pt -> CGPoint in
            let pdefx = (pt.x - offset.x) / scale
            let pdefy = (pt.y - offset.y) / scale
            return CGPoint(x: pdefx, y: pdefy)
        }
		DispatchQueue.concurrentPerform(iterations: self.arr.count) { i in
			pts[i] = (self.arr[i] - offset) / scale
		}
        return CGPointArray(newPoints)
    }
    
    func convertTo(scale: CGFloat, andOffset offset: CGPoint) -> CGPointArray {
		var pts = Array<CGPoint>(repeating: .zero, count: self.arr.count)
		DispatchQueue.concurrentPerform(iterations: self.arr.count) { i in
			pts[i] = self.arr[i]
		}
		let newPoints = self.arr.map { pt -> CGPoint in
			let pdefx = (pt.x - offset.x) / scale
			let pdefy = (pt.y - offset.y) / scale
			return CGPoint(x: pdefx, y: pdefy)
		}
		DispatchQueue.concurrentPerform(iterations: self.arr.count) { i in
			pts[i] = (self.arr[i] * scale) + offset
		}
        return CGPointArray(newPoints)
    }
}

extension String {
    func toPointArray() -> CGPointArray {
        var arr: [CGPoint] = []
        for elem in self.split(separator: "|") {
            let coorinates = elem.split(separator: " ")
            let x = CGFloat(Float(coorinates[0]) ?? 0)
            let y = CGFloat(Float(coorinates[1]) ?? 0)
            
            arr.append(CGPoint(x: x, y: y))
        }
        return CGPointArray(arr)
    }
    
    func toCGColor() -> CGColor {
        let spl = self.split(separator: "|")
        let rs = spl[0]
        let gs = spl[1]
        let bs = spl[2]
        let aa = spl[3]
        
        let r = CGFloat(Float(rs) ?? 0)
        let g = CGFloat(Float(gs) ?? 0)
        let b = CGFloat(Float(bs) ?? 0)
        let a = CGFloat(Float(aa) ?? 0)
        
        return CGColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func toXColor() -> XColor {
        let spl = self.split(separator: "|")
        let rs = spl[0]
        let gs = spl[1]
        let bs = spl[2]
        let aa = spl[3]
        
        let r = CGFloat(Float(rs) ?? 0)
        let g = CGFloat(Float(gs) ?? 0)
        let b = CGFloat(Float(bs) ?? 0)
        let a = CGFloat(Float(aa) ?? 0)
        
        return XColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension XColor {
    func toString() -> String {
        let red = self.getComponents().red
        let green = self.getComponents().green
        let blue = self.getComponents().blue
        let a = self.getComponents().alpha
        
        let str = "\(red)|\(green)|\(blue)|\(a)"
        return str
    }
}

class DefaultValues {
    static let defaultColorString = "0|1|0|1"
    static let defaultSwatches = [XColor.red, XColor.systemBlue, XColor.yellow, XColor.green, XColor.systemMint, XColor.systemPurple, XColor.systemPink]
    static let NaN = NSNumber(floatLiteral: sqrt(-1))
    static let infinity = NSNumber(floatLiteral: 1 / 0.0)
}

struct Stroke {
    var points: [CGPoint] = []
    var color: XColor = .red
    var width: CGFloat = 2
    var originalScale: CGFloat = 1
    var id: UUID
    var createdAt = Date()
    var typeOfStroke: ToolInUse = .line
    var textValue: String = ""
    var imageData: Data?
    var skipIndexes: [Int] = []
    var selected: Bool
    
    var boldArr: [NSRange] = []
    var italicArr: [NSRange] = []
    
    var fontSize: CGFloat = 30
    
    func graph(o: CGPoint, s ss: CGFloat) -> Stroke {
        var a = [self.points[0]]
        let s = Float(ss)
        let p = self.pointsForExpression(withStringFormat: self.textValue,
                                         withXFrom: -2, to: 2,
                                         andYFrom: -2, to: 2,
                                         insideOffset: .zero, insideScale: 1, trueOffset: .zero, trueScale: 1)
        a.append(contentsOf: p.point.scale(by: CGFloat(s), around: self.points[0]))
        
        var ds = self
        ds.points = a
        ds.skipIndexes = p.breakAtIndexes
        return ds
    }
    
    func convertToDefault(scale: CGFloat, offset: CGPoint) -> Stroke {
		var pts = Array<CGPoint>(repeating: .zero, count: self.points.count)
		DispatchQueue.concurrentPerform(iterations: self.points.count) { i in
			pts[i] = self.points[i]
		}
		
		DispatchQueue.concurrentPerform(iterations: self.points.count) { i in
			pts[i] = (self.points[i] - offset) / scale
		}
        var s = self
        s.points = pts
        return s
    }
    
    func convertTo(scale: CGFloat, andOffset offset: CGPoint) -> Stroke {
		var pts = Array<CGPoint>(repeating: .zero, count: self.points.count)
		DispatchQueue.concurrentPerform(iterations: self.points.count) { i in
			pts[i] = self.points[i]
		}
		
		DispatchQueue.concurrentPerform(iterations: self.points.count) { i in
			pts[i] = (self.points[i] * scale) + offset
		}
	
        var s = self
        s.points = pts
        return s
    }
    
    func contains(pointToDefault pt: CGPoint, viewScale sc: CGFloat, andOffset offs: CGPoint, threshold tht: CGFloat = 10) -> Bool {
        let threshold = self.width
        let ptdef = CGPointArray([pt]).convertToDefault(scale: sc, offset: offs).arr[0]
        if self.typeOfStroke == .pencil {
            if self.points.count <= 1 {
                return false
            }
            
            if ptdef.distance(to: self.points[0]) <= threshold {
                return true
            }
            
            for i in 1 ..< self.points.count {
                if ptdef.is(between: self.points[i - 1], and: self.points[i], threshold: threshold) || ptdef.distance(to: self.points[i]) <= threshold {
                    return true
                }
            }
        } else if self.typeOfStroke == .circle {
            if self.points.count >= 2 {
            if ptdef.is(onEllipsisRect: CGRect(origin: self.points[0], size: CGSize(width: self.points[1].x - self.points[0].x, height: self.points[1].y - self.points[0].y)), threshold: CGFloat(threshold)) {
                return true
            }
            }
        } else if self.typeOfStroke == .line {
            if self.points.count > 1 {
                return ptdef.is(between: self.points[0], and: self.points[1], threshold: threshold)
            }
        } else if self.typeOfStroke == .rectangle {
            //            //print("Hello")
            if self.points.count >= 2 {
            if ptdef.is(onRect: CGRect(origin: self.points[0], size: CGSize(width: self.points[1].x - self.points[0].x, height: self.points[1].y - self.points[0].y)), threshold: CGFloat(threshold)) {
                return true
            }
            }
        } else if self.typeOfStroke == .text {
            let r = self.rect(s: 1)
            
            
            if ptdef.is(inRectangle: r) {
                return true
            }
        } else if self.typeOfStroke == .graph {
            if ptdef.distance(to: self.points[0]) <= 100 {
                return true
            }
        } else if self.typeOfStroke == .image {
            return ptdef.is(inRectangle: self.rect(s: 1))
        }
        
        return false
    }
    
    
    func contains(rectToDefault rect: CGRect, viewScale sc: CGFloat, andOffset offs: CGPoint, threshold tht: CGFloat = 10) -> Bool {
        let ptdefOrigin = CGPointArray([rect.topLeft]).convertToDefault(scale: sc, offset: offs).arr[0]
        let ptdefOther = CGPointArray([rect.bottomRight]).convertToDefault(scale: sc, offset: offs).arr[0]
        
        let rectdef = CGRect(origin: ptdefOrigin, size: CGSize(width: ptdefOther.x - ptdefOrigin.x, height: ptdefOther.y - ptdefOrigin.y))
        
        if self.typeOfStroke == .pencil {
            if self.points.count <= 1 {
                return false
            }
            
            if self.points[0].is(inRectangle: rectdef) {
                return true
            }
            
            for i in 1 ..< self.points.count {
                if self.points[i].is(inRectangle: rectdef) {
                    return true
                }
            }
        } else if self.typeOfStroke == .circle {
            if self.points.count >= 2 {
            let r = CGRect(origin: self.points[0], size: CGSize(width: self.points[1].x - self.points[0].x, height: self.points[1].y - self.points[0].y))
            if r.intersects(rectdef) {
                return true
            }
            }
            
        } else if self.typeOfStroke == .line {
            if self.points.count >= 2 {
                return rectdef.intersects(self.rect(s: sc))
            }
        } else if self.typeOfStroke == .rectangle {
            //            //print("Hello")
            if self.points.count >= 2 {
            let r = CGRect(origin: self.points[0], size: CGSize(width: self.points[1].x - self.points[0].x, height: self.points[1].y - self.points[0].y))
            if r.intersects(rectdef) {
                return true
            }
            }
        } else if self.typeOfStroke == .text {
            return self.rect(s: 1).intersects(rectdef)
        } else if self.typeOfStroke == .graph {
            return self.points[0].is(inRectangle: rectdef)
        }
        
        return false
    }
    
    
    
}

extension CGFloat {
    func `is`(between n1: CGFloat, and n2: CGFloat, threshhold: CGFloat) -> Bool {
        let mare = n1 > n2 ? n1 : n2
        let mic = n1 < n2 ? n1 : n2
        if mic - threshhold <= self && self <= mare + threshhold {
            return true
        }
        
        return false
    }
    
    func `is`(between n1: CGFloat, and n2: CGFloat) -> Bool {
        let mare = n1 > n2 ? n1 : n2
        let mic = n1 < n2 ? n1 : n2
        if mic <= self && self <= mare {
            return true
        }
        
        return false
    }
}

extension CGRect {
    var topLeft: CGPoint {
        get {
            let p1 = self.origin
            let p2 = CGPoint(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
            let R = CGPoint(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
            return R
        }
    }
    
    var bottomRight: CGPoint {
        get {
            let p1 = self.origin
            let p2 = CGPoint(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
            let R = CGPoint(x: max(p1.x, p2.x), y: max(p1.y, p2.y))
            return R
        }
    }
    
    //    func intersects(withRect rect: CGRect) -> Bool {
    //        let r1 = self
    //        let r2 = rect
    //        if r1.topLeft.x < r2.bottomRight.x, r1.bottomRight.x > r2.topLeft.x,
    //           r1.topLeft.y < r2.bottomRight.y, r1.bottomRight.y > r2.topLeft.y {
    //            return true
    //        }
    //        return false
    //    }
}

extension CGPoint {
    func `is`(between p1: CGPoint, and p2: CGPoint, threshold: CGFloat) -> Bool {
        if p1.x == p2.x {
            if self.y.is(between: p1.y, and: p2.y, threshhold: threshold), abs(p1.x - self.x) <= threshold {
                return true
            } else {
                return false
            }
        }
        
        guard self.x.is(between: p1.x, and: p2.x, threshhold: threshold) else {
            // //print("Ya foll X \(p1.x) \(p2.x) || \(self.x)")
            return false
        }
        
        guard self.y.is(between: p1.y, and: p2.y, threshhold: threshold) else {
            return false
        }
        
        let a = (p1.y - p2.y) / (p1.x - p2.x)
        let b = p1.y - a * p1.x
        
        let yywanna = self.x * a + b
        if abs(self.y - yywanna) <= threshold {
            return true
        }
        return false
    }
    
    func `is`(onEllipsisRect rect: CGRect, threshold: CGFloat) -> Bool {
        let end = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        
        let x1 = rect.origin.x
        let x2 = end.x
        
        let y1 = rect.origin.y
        let y2 = end.y
        
        let minx = min(x1, x2)
        let miny = min(y1, y2)
        
        let maxx = max(x1, x2)
        let maxy = max(y1, y2)
        
        let w = abs(rect.width)
        let h = abs(rect.height)
        
        let x0 = Float((minx + maxx) / 2)
        let y0 = Float((miny + maxy) / 2)
        let a = Float(w / 2)
        let b = Float(h / 2)
        let selfx = Float(self.x)
        
        let bb = 1 - (selfx - x0) * (selfx - x0) / (a * a)
        
        if bb < 0 {
            return false
        }
        
        let bp = b * sqrt(bb)
        
        let pos_Y = bp + y0
        let neg_Y = y0 - bp
        
        if abs(pos_Y - Float(self.y)) <= Float(threshold) || abs(neg_Y - Float(self.y)) <= Float(threshold) {
            return true
        }
        
        return false
    }
    
    func `is`(onRect rect: CGRect, threshold: CGFloat) -> Bool {
        //        //print(CGFloat(2).is(between: 1, and: 1, threshhold: 5))
        
        if self.is(between: rect.origin, and: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height), threshold: threshold) {
            return true
        }
        
        if self.is(between: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height), and: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height), threshold: threshold) {
            return true
        }
        
        if self.is(between: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height), and: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y), threshold: threshold) {
            return true
        }
        
        if self.is(between: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y), and: rect.origin, threshold: threshold) {
            return true
        }
        
        return false
    }
}

extension CGPoint {
    func distance(to p: CGPoint) -> CGFloat {
        let xx = self.x - p.x
        let yy = self.y - p.y
        let d = sqrt(xx * xx + yy * yy)
        return CGFloat(d)
    }
}

extension CGColor {
    static var red = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
}

extension View {
    @ViewBuilder func labelled<Content: View>(with v: () -> Content) -> some View {
        HStack {
            v()
            self
        }
    }
}

extension XColor {
    func with(alpha: CGFloat) -> XColor {
        return XColor(red: self.getComponents().red, green: self.getComponents().green, blue: self.getComponents().blue, alpha: alpha)
    }
    
    func with(red: CGFloat) -> XColor {
        return XColor(red: red, green: self.getComponents().green, blue: self.getComponents().blue, alpha: self.getComponents().alpha)
    }
    
    func with(blue: CGFloat) -> XColor {
        return XColor(red: self.getComponents().red, green: self.getComponents().green, blue: blue, alpha: self.getComponents().alpha)
    }
    
    func with(green: CGFloat) -> XColor {
        return XColor(red: self.getComponents().red, green: green, blue: self.getComponents().blue, alpha: self.getComponents().alpha)
    }
}

extension XColor: Identifiable {}
