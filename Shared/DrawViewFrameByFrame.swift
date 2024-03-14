//
//  DrawViewFrameByFrame.swift
//  NoteTakerApp (macOS)
//
//  Created by Alexandru Ariton on 10.05.2022.
//

struct GetOffsetAndScale {
	static var offsetX: CGFloat = 0
	static var offsetY: CGFloat = 0
	static var scale: CGFloat = 1
}

struct SetOffsetAndScale {
	static var offsetX: CGFloat = 0
	static var offsetY: CGFloat = 0
	static var scale: CGFloat = 1
}
#if os(macOS)
import AppKit
public extension NSView {
    func toImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}


#elseif os(iOS)
import UIKit

extension UIColor {
    convenience init(calibratedRed: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(red: calibratedRed, green: green, blue: blue, alpha: alpha)
    }
}
#endif
import Combine
import CoreData
import CoreGraphics
import Foundation
import SwiftUI
#if os(macOS)
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
            drawsBackground = true
        }
        
    }
}

extension NSView {
    func toImage(size: NSSize) -> NSImage {
        let representation = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
        representation.size = size
        self.cacheDisplay(in: self.bounds, to: representation)
        
        let image = NSImage(size: size)
        image.addRepresentation(representation)
        return image
    }
}

extension CGPoint {
    static func gradient(a: CGPoint, b: CGPoint) -> CGFloat {
        (b.y - a.y) / (b.x - a.x)
    }
}

extension Array where Element == CGPoint {
    mutating func convertToSmooth(coefficient severity: Int) {
        for (i, _) in self.enumerated() {
            var start = (i - severity > 0 ? i - severity : 0)
            var end = (i + severity < self.count ? i + severity : self.count)
            var sum = CGPoint.zero
            for j in start..<end {
                sum = sum + self[j]
            }
            var avg = sum / CGFloat(end - start)
            self[i] = avg
        }
    }
}

extension CGContext {
    func drawRect(_ rect: CGRect, cornerRadius c: CGFloat) -> NSBezierPath {
        let pat = NSBezierPath(roundedRect: rect, xRadius: c, yRadius: c)
        return pat
    }
    
    func drawSmoothLine(from points: [CGPoint], smooth: Bool = false) {
        if smooth {
            self._drawSmoothLine(from: points)
        } else {
            self._drawLine(from: points)
        }
    }
    
    func _drawSmoothLine(from points: [CGPoint]) {
        self.setLineCap(.round)
        self.setLineJoin(.round)
        var pts = points
        pts.convertToSmooth(coefficient: 3)
        self.addLines(between: pts)
        self.strokePath()
    }
    
    func _drawLine(from points: [CGPoint]) {
        self.setLineCap(.round)
        self.setLineJoin(.round)
        self.addLines(between: points)
        self.strokePath()
    }
}

class NSImageWithConstraints {
    var offsetX: NSLayoutConstraint
    var offsetY: NSLayoutConstraint
    var widthConstraint: NSLayoutConstraint
    var heightConstraint: NSLayoutConstraint
    var image: NSImage
    var view: NSView
    init(offsetX: NSLayoutConstraint, offsetY: NSLayoutConstraint, widthConstraint: NSLayoutConstraint, heightConstraint: NSLayoutConstraint, image: NSImage, view: NSView) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.widthConstraint = widthConstraint
        self.heightConstraint = heightConstraint
        self.image = image
        self.view = view
    }
}


class DrawViewFBF: NSView {
    var moc: NSManagedObjectContext
    var notesFetch: FetchedResults<NoteData>
    var sEnv: EnvironmentObject<ScrollEnv>
    var trueOffset: CGPoint = .zero
    var zoomBias: CGPoint = .zero
    var trueScale: CGFloat = 1
    var dragOffset: CGSize = .zero
    var GRAPHSCALE: CGFloat = 5
    var ctx: CGContext? = nil
    var drawLinesView: DrawRestOfLines!
    var imageDictionary: [UUID: NSImageWithConstraints] = [:] {
        didSet {
            // MARK: DRAW IMAGES
            if imageDictionary.isEmpty {
                for c in self.subviews {
                    if !(c is DrawRestOfLines) {
                        c.removeFromSuperview()
                    }
                }
            }
            for (keyId, imageCon) in imageDictionary {
                if imageCon.view.superview == self {
                     
                } else {
                    self.addSubview(imageCon.view, positioned: .below, relativeTo: self.drawLinesView)
                    imageCon.view.translatesAutoresizingMaskIntoConstraints = false
                    print("Added sub")
                    imageCon.offsetX.isActive = true
                    imageCon.offsetY.isActive = true
                    imageCon.heightConstraint.isActive = true
                    imageCon.widthConstraint.isActive = true
                }
            }
        }
    }
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>, notesFetch: FetchedResults<NoteData>, moc: NSManagedObjectContext) {
        self.moc = moc
        
        self.sEnv = scrollEnv
        self.notesFetch = notesFetch
        
        self.drawLinesView = DrawRestOfLines(scrollEnv: self.sEnv, notesFetch: self.notesFetch, moc: self.moc)
        
        
        
        super.init(frame: XRect(x: 0, y: 0, width: 200, height: 200))
        
        //
        self.addSubview(drawLinesView)
        self.drawLinesView.translatesAutoresizingMaskIntoConstraints = false
        self.drawLinesView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.drawLinesView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.drawLinesView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        self.drawLinesView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        NotificationCenter.default.addObserver(forName: .didChangeNote, object: nil, queue: nil) { not in
            self.updateSelf()
        }
        
        
        NotificationCenter.default.addObserver(forName: .didResetTransform, object: nil, queue: nil) { n in
            self.updateSelf()
            self.trueScale = 1
            self.trueOffset = .zero
            self.drawLinesView.trueScale = 1
            self.drawLinesView.trueOffset = .zero
        }
		
		NotificationCenter.default.addObserver(forName: .getOffsetAndScale, object: nil, queue: nil) { not in
			GetOffsetAndScale.offsetX = self.trueOffset.x
			GetOffsetAndScale.offsetY = self.trueOffset.y
			GetOffsetAndScale.scale = self.trueScale
		}
		
		NotificationCenter.default.addObserver(forName: .setOffsetAndScale, object: nil, queue: nil) { not in
			self.updateSelf()
			Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
//				print(self.trueOffset)
				self.trueOffset.x = self.trueOffset.x + (SetOffsetAndScale.offsetX - self.trueOffset.x) / 10
				self.trueOffset.y = self.trueOffset.y + (SetOffsetAndScale.offsetY - self.trueOffset.y) / 10
				self.trueScale = self.trueScale + (SetOffsetAndScale.scale - self.trueScale) / 10
//				print(SetOffsetAndScale.offsetX, SetOffsetAndScale.offsetY)
				
				
				
				self.updateSelf()
				if abs(self.trueOffset.x - SetOffsetAndScale.offsetX) < 10 && abs(self.trueScale - SetOffsetAndScale.scale) < 0.1 && abs(self.trueOffset.y - SetOffsetAndScale.offsetY) < 10 {
					self.trueOffset.x = SetOffsetAndScale.offsetX
					self.trueOffset.y = SetOffsetAndScale.offsetY
					self.trueScale = SetOffsetAndScale.scale
					timer.invalidate()
					
				}
				
			}
			
			self.updateSelf()
		}
		
		NotificationCenter.default.addObserver(forName: .sliderDidChangeValues, object: nil, queue: nil) { not in
			self.updateSelf()
		}
    
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func endOfEvents() {}
    
    
    func updateSelf() {
        self.drawLinesView.trueScale = self.trueScale
        self.drawLinesView.trueOffset = self.trueOffset
        self.drawLinesView.dragOffset = self.dragOffset
        
    }
    var movingShit = false
    
    override func scrollWheel(with event: NSEvent) {
        self.updateSelf()
        
        if event.deviceID == 0 {
            // TABLET
            self.trueOffset = CGPoint(x: self.trueOffset.x + event.scrollingDeltaX * 5,
                                      y: self.trueOffset.y - event.scrollingDeltaY * 5)
        } else {
            self.trueOffset = CGPoint(x: self.trueOffset.x + event.scrollingDeltaX,
                                      y: self.trueOffset.y - event.scrollingDeltaY)
        }
        
        self.movingShit = true
        
        if event.phase == .ended || event.phase == .cancelled {
            self.movingShit = false
        }
    }
    
    private var scaleVal: CGFloat = 1.0
    
    // MARK: - DRAG
    var scaleDerivative: CGFloat = 1.0
    
    override func magnify(with event: NSEvent) {
        //        self.sEnv.wrappedValue.scale = max(0.5, 1 + event.magnification)
        self.updateSelf()
		
        self.zoomBias = self.convert(XPoint(x: event.locationInWindow.x, y: event.locationInWindow.y), from: nil)
        
        //
        let oldScale = self.trueScale
        self.trueScale = Math.calculateScale(fromMouseScale: max(0.5, 1 + event.magnification), andOldScale: self.trueScale)
        self.scaleDerivative = self.trueScale / oldScale
        self.trueOffset = Math.calculateOffset(
            fromMouseScale: max(0.5, 1 + event.magnification),
            andOldOffset: CGPoint(x: self.trueOffset.x, y: self.trueOffset.y),
            withMousePosition: self.zoomBias
        )
        
        if event.phase == .ended {
            self.sEnv.wrappedValue.currentStroke.originalScale = 1
        }
        self.movingShit = true
        
        if event.phase == .ended || event.phase == .cancelled {
            self.movingShit = false
        }
    }
    
    // MARK: - CLICK
    
    override func mouseDown(with event: NSEvent) {
        self.updateSelf()
        
        
        let location = event.locationInWindow
        
        //        //print("Dragged")
        let loc2 = location
        let loc = XPoint(x: loc2.x, y: loc2.y)
        
        let l3 = self.convert(loc, from: nil)
        // MARK: ADD IMAGE
        if self.sEnv.wrappedValue.toolInUse == .image {
            let url = FileImporter.showOpenPanel()
            if let url = url {
                self.sEnv.wrappedValue.currentStroke.createdAt = Date()
                self.sEnv.wrappedValue.currentStroke.color = self.sEnv.wrappedValue.selectedColor
                self.sEnv.wrappedValue.currentStroke.width = .init(self.sEnv.wrappedValue.selectedWidth)
                self.sEnv.wrappedValue.currentStroke.typeOfStroke = .image
                self.sEnv.wrappedValue.currentStroke.id = UUID()
                self.sEnv.wrappedValue.currentStroke.imageData = try? Data(contentsOf: url)
                self.sEnv.wrappedValue.currentStroke.points = [l3]
                
            } else {
                print("URL IS NIL")
            }
            
        } else if self.sEnv.wrappedValue.toolInUse != .select {
            self.sEnv.wrappedValue.currentStroke.createdAt = Date()
            self.sEnv.wrappedValue.currentStroke.color = self.sEnv.wrappedValue.selectedColor
            self.sEnv.wrappedValue.currentStroke.width = CGFloat(self.sEnv.wrappedValue.selectedWidth)
            self.sEnv.wrappedValue.currentStroke.typeOfStroke = self.sEnv.wrappedValue.toolInUse
            self.sEnv.wrappedValue.currentStroke.id = UUID()
            if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .line || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .circle || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .rectangle {
                self.sEnv.wrappedValue.currentStroke.points = [l3]
            } else if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .text || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .graph {
                self.sEnv.wrappedValue.currentStroke.points = [l3]
                self.sEnv.wrappedValue.currentStroke.textValue = self.sEnv.wrappedValue.selectedTextText
            }
        } else {
            // SELECTION
            if self.sEnv.wrappedValue.selectJustOne {
                for l in self.sEnv.wrappedValue.strokes {
                    if l.selected {
                        self.modify(forStroke: l, ofNoteID: self.sEnv.wrappedValue.currentNoteId)
                    }
                }
                
                if self.sEnv.wrappedValue.editGraph, self.sEnv.wrappedValue.selectedLinesCount() == 1 {
                    
                } else {
                    
                    self.sEnv.wrappedValue.clearSelection()
                    selarr = []
                    
                    if self.sEnv.wrappedValue.selectJustOne {
                        for (ind, st) in self.sEnv.wrappedValue.strokes.enumerated() {
                            if st.contains(pointToDefault: l3, viewScale: self.trueScale, andOffset: self.trueOffset) {
                                self.selarr.append(ind)
                            }
                        }
                        
                        if selarr != [] {
                            print(selarr)
                            if currentInd >= selarr.count {
                                currentInd = 0
                            }
                            self.sEnv.wrappedValue.strokes[selarr[currentInd]].selected = true
                            currentInd += 1
                            if currentInd >= selarr.count {
                                currentInd = 0
                            }
                        }
                        
                    } else {
                        for (ind, st) in self.sEnv.wrappedValue.strokes.enumerated() {
                            if st.contains(pointToDefault: l3, viewScale: self.trueScale, andOffset: self.trueOffset) {
                                    self.sEnv.wrappedValue.strokes[ind].selected = true
                            }
                        }
                    }
                }
                if self.sEnv.wrappedValue.selectedLinesCount() >= 1 {
                    let f = self.sEnv.wrappedValue.firstSelected()
                    self.sEnv.wrappedValue.selectedTextText = f.textValue
                }
            }
            if self.sEnv.wrappedValue.selectJustOne == false, self.sEnv.wrappedValue.selectedLinesCount() == 0 {
                self.sEnv.wrappedValue.selectedRect.origin = l3
            }
        }
    }
    
    var selarr = [Int]()
    var currentInd = 0
    
    // MARK: - DRAG
    
    override func mouseDragged(with event: NSEvent) {
        self.updateSelf()
        let location = event.locationInWindow
        
        //        //print("Dragged")
        let loc2 = location
        let loc = XPoint(x: loc2.x, y: loc2.y)
        
        let l3 = self.convert(loc, from: nil)
        
        if self.sEnv.wrappedValue.toolInUse != .select {
            if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .line || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .circle || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .rectangle {
                self.sEnv.wrappedValue.currentStroke.points = [self.sEnv.wrappedValue.currentStroke.points[0], l3]
            } else if self.sEnv.wrappedValue.currentStroke.typeOfStroke != .text || self.sEnv.wrappedValue.currentStroke.typeOfStroke != .image {
                self.sEnv.wrappedValue.currentStroke.points.append(l3)
            }
        } else {
            self.dragOffset.width = event.deltaX
            self.dragOffset.height = -event.deltaY
            for n in 0 ..< self.sEnv.wrappedValue.strokes.count {
                if self.sEnv.wrappedValue.strokes[n].selected {
                    self.sEnv.wrappedValue.strokes[n].points.transform(by: self.dragOffset, scale: self.trueScale, offset: self.trueOffset)
                }
            }
            if self.sEnv.wrappedValue.selectedLinesCount() == 0, self.sEnv.wrappedValue.selectJustOne == false {
                self.sEnv.wrappedValue.selectedRect.size = CGSize(width: self.sEnv.wrappedValue.selectedRect.size.width + event.deltaX, height: self.sEnv.wrappedValue.selectedRect.size.height - event.deltaY)
            }
        }
    }
    
    // MARK: - UP
    
    override func mouseUp(with event: NSEvent) {
        
        self.updateSelf()
        
        
        if self.sEnv.wrappedValue.toolInUse != .select {
            let currentStroke = self.sEnv.wrappedValue.currentStroke
            if currentStroke.points != [] {
                if currentStroke.typeOfStroke == .graph {
                    self.sEnv.wrappedValue.strokes.append(currentStroke.graph(o: self.trueOffset, s: self.trueScale).convertToDefault(scale: self.trueScale, offset: self.trueOffset))
                    
                } else {
                    self.sEnv.wrappedValue.strokes.append(currentStroke.convertToDefault(scale: self.trueScale, offset: self.trueOffset))
                }
                
                let stroke = StrokeData(context: self.moc)
                
                if self.sEnv.wrappedValue.currentStroke.typeOfStroke != .graph {
                    stroke.pointSet = CGPointArray(self.sEnv.wrappedValue.currentStroke.points).convertToDefault(scale: self.trueScale, offset: self.trueOffset).toString()
                } else {
                    var arr = [CGPoint]()
                    arr.append(self.sEnv.wrappedValue.currentStroke.points[0].convertToDefault(scale: self.trueScale, offset: self.trueOffset))
                    
                    let aa = self.sEnv.wrappedValue.currentStroke.pointsForExpression(
                        withStringFormat: self.sEnv.wrappedValue.selectedTextText,
                        insideOffset: .zero, insideScale: 1,
                        trueOffset: self.trueOffset, trueScale: self.trueScale
                    )
                    arr.append(contentsOf: aa.point.scale(by: self.trueScale, around: arr[0]))
                    //                    //print(arr)
                    stroke.pointSet = CGPointArray(arr).toString()
                    stroke.skipIndexes = aa.breakAtIndexes.toString()
                }
                
                stroke.color = self.sEnv.wrappedValue.currentStroke.color.toString()
                //        stroke.documentScale = Float(Double(trueScale))
                if !self.sEnv.wrappedValue.customSwatches.contains(where: { ns in
                    ns.getComponents() == self.sEnv.wrappedValue.currentStroke.color.getComponents()
                }) {
                    self.sEnv.wrappedValue.customSwatches.append(self.sEnv.wrappedValue.currentStroke.color)
                }
                
                //        //print("OWNED")
                
                stroke.createdAt = self.sEnv.wrappedValue.currentStroke.createdAt
                
                stroke.width = Float(self.sEnv.wrappedValue.currentStroke.width)
                
                stroke.typeOfStroke = self.sEnv.wrappedValue.currentStroke.typeOfStroke.rawValue
                
                stroke.strokeId = self.sEnv.wrappedValue.currentStroke.id
                
                stroke.textValue = self.sEnv.wrappedValue.currentStroke.textValue
                
                
                
                //        //print(stroke.typeOfStroke)
                if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .image {
                    print("saved")
                    stroke.imageData = self.sEnv.wrappedValue.currentStroke.imageData!
                    print(stroke.imageData)
                }
                //MARK: Creation Action
                //                let action = NoteAction(env: self.sEnv, strokeProperty: nil, type: .creation, strokeID: stroke.strokeId, str: currentStroke)
                //                action.insert()
                
                stroke.ownedByNote = self.notesFetch.first(where: { $0.noteId == self.sEnv.wrappedValue.currentNoteId })
                
                //                //print("OWNED; \(stroke.ownedByNote?.name ?? "None")")
                
                do {
                    try self.moc.save()
                } catch {
                    //print(error.localizedDescription)
                }
            }
            self.sEnv.wrappedValue.currentStroke = Stroke(points: [], originalScale: self.sEnv.wrappedValue.currentStroke.originalScale, id: UUID(uuid: UUID_NULL), textValue: "", skipIndexes: [], selected: false, boldArr: [], italicArr: [])
        } else if self.sEnv.wrappedValue.selectJustOne == false {
            self.sEnv.wrappedValue.strokes.forEach { i in
                self.modify(forStroke: i, ofNoteID: self.sEnv.wrappedValue.currentNoteId)
            }
            self.sEnv.wrappedValue.clearSelection()
            for (j, st) in self.sEnv.wrappedValue.strokes.enumerated() {
                if st.contains(rectToDefault: self.sEnv.wrappedValue.selectedRect, viewScale: self.trueScale, andOffset: self.trueOffset) {
                    self.sEnv.wrappedValue.strokes[j].selected = true
                }
            }
            self.sEnv.wrappedValue.selectedRect = .zero
        } else if self.sEnv.wrappedValue.selectJustOne == true {
            if self.sEnv.wrappedValue.selectedLinesCount() != 0 {
                let fs = self.sEnv.wrappedValue.firstSelected()
                
                self.sEnv.wrappedValue.selectedColorArr = [fs.color.getComponents().red, fs.color.getComponents().green, fs.color.getComponents().blue, fs.color.getComponents().alpha]
                NotificationCenter.default.post(name: .didChangeColorFromSelection, object: nil)
            }
        }
    }
    
    func modify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionColor.insert()
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionWidth.insert()
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionPoints.insert()
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionText.insert()
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    
    func whenInRevertedModify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    //                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, primordialType: .reverted)
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    //                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, primordialType: .reverted)
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    //                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, primordialType: .reverted)
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    //                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, primordialType: .reverted)
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
}

var WIDTHTEXTBIAS: CGFloat = 50

class DrawRestOfLines: NSView {
    var moc: NSManagedObjectContext
    
    var notesFetch: FetchedResults<NoteData>
    
    var sEnv: EnvironmentObject<ScrollEnv>
    
    var trueOffset: CGPoint = .zero
    var zoomBias: CGPoint = .zero
    var trueScale: CGFloat = 1
    var dragOffset: CGSize = .zero
    
    var GRAPHSCALE: CGFloat = 5
    
    var ctx: CGContext? = nil
    
    // MARK: - DRAW GUIDES
    
    var imageDictionary: [UUID: NSImageWithConstraints] = [:] {
        didSet {
            let sv = self.superview as! DrawViewFBF
            sv.imageDictionary = imageDictionary
        }
    }
    
    
    func drawGuides() {
        guard let context = NSGraphicsContext.current?.cgContext else {
            //            //print("No")
            return
        }
        
        if self.ctx == nil {
            self.ctx = context
        }
        
        context.saveGState()
        if self.sEnv.wrappedValue.showGrid {
            let geo = CGSize(width: self.bounds.width, height: self.bounds.height)
            let facInt = Double(Int(log2(1 / self.trueScale)))
            let scalePow: CGFloat = .init(pow(2, facInt))

            let multi: CGFloat = .init(40 * scalePow)
            let step = multi

            let modx = CGFloat(fmod(Double(self.trueOffset.x), Double(multi * self.trueScale)))
            let mody = CGFloat(fmod(Double(self.trueOffset.y), Double(multi * self.trueScale)))

            for i in stride(from: 0, to: max(geo.width, geo.height) / self.trueScale, by: step) {
                context.setStrokeColor(XColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.2).cgColor)
                context.addLines(between: CGPointArray([
                    CGPoint(x: i, y: 0),
                    CGPoint(x: i, y: max(geo.width, geo.height) / self.trueScale + 0)
                ]).convertTo(scale: self.trueScale, andOffset: CGPoint(x: modx, y: mody)).arr)
                context.strokePath()

                context.addLines(between: CGPointArray([
                    CGPoint(x: 0, y: i),
                    CGPoint(x: max(geo.width, geo.height) / self.trueScale + 0, y: i)
                ]).convertTo(scale: self.trueScale, andOffset: CGPoint(x: modx, y: mody)).arr)

                context.strokePath()
            }
        }
        context.restoreGState()
    }
    
    // MARK: - DRAW

    var movingShit = false
    
    func drawShit() {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        
        if self.sEnv.wrappedValue.resetScaleAndOffset {
            self.trueScale = 1
            self.trueOffset = .zero
            self.sEnv.wrappedValue.resetScaleAndOffset = false
        }
        
        let strokes = self.sEnv.wrappedValue.strokes
        let all = strokes
        
        
        if self.sEnv.wrappedValue.removeFromSuperView {
            self.imageDictionary = [:]
            self.sEnv.wrappedValue.removeFromSuperView = false
        }
        
        let ALL = all.combined(with: self.sEnv.wrappedValue.currentStroke.convertToDefault(scale: trueScale, offset: trueOffset))
        
        for uconv_line in ALL {
            let line = uconv_line.convertTo(scale: trueScale, andOffset: trueOffset)
            if !line.rect(s: trueScale).intersects(.init(x: self.bounds.minX, y: self.bounds.minY, width: self.bounds.width, height: self.bounds.height)) {
                if line.typeOfStroke == .image {
                    imageDictionary[line.id]?.view.removeFromSuperview()
                    imageDictionary.removeValue(forKey: line.id)
                }
                continue
            }
            context.saveGState()
            if self.sEnv.wrappedValue.scaleByWidth {
                context.setLineWidth(line.width * self.trueScale)
            } else {
                context.setLineWidth(line.width)
            }
            if line.typeOfStroke == .line {
                context.setStrokeColor(line.color.cgColor)
                context.drawSmoothLine(from: line.points)
            } else if line.typeOfStroke == .pencil {
                context.setStrokeColor(line.color.cgColor)
                context.drawSmoothLine(from: line.points, smooth: true)
            } else if line.typeOfStroke == .circle {
                if line.points.count >= 2 {
                    context.setStrokeColor(line.color.cgColor)
                    context.addEllipse(in: CGRect(origin: line.points[0], size: CGSize(width: line.points[1].x - line.points[0].x, height: line.points[1].y - line.points[0].y)))
                    
                    context.strokePath()
                }
                
            } else if line.typeOfStroke == .rectangle {
                if line.points.count >= 2 {
                    context.setStrokeColor(line.color.cgColor)
                    context.addRect(CGRect(origin: line.points[0], size: CGSize(width: line.points[1].x - line.points[0].x, height: line.points[1].y - line.points[0].y)))
                    
                    context.strokePath()
                }
            } else if line.typeOfStroke == .text {
                
                if self.sEnv.wrappedValue.selectedTextField.id != line.id {
                    let text = "\(line.textValue)"
                    let color = line.color
                    let fontSize: CGFloat = 30 * self.trueScale
                    let font = NSFont(name: "Avenir", size: fontSize)!
                    let boldFont = NSFont(name: "Avenir-Heavy", size: fontSize)!
                    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: font]
                
                    let a = text.textToText()
                    let string = NSMutableAttributedString(string: a.string, attributes: attributes)
                    let boldArr = a.boldRanges
                    boldArr.forEach { range in
                        string.addAttribute(.font, value: boldFont, range: range)
                    }
                    
                    let italicArr = a.italicRanges
                    italicArr.forEach{ range in
                        string.addAttribute(.obliqueness, value: 0.2, range: range)
                        
                    }
                    
                    let underlineArr: [NSRange] = a.underlineRanges
                    
                    underlineArr.forEach { range in
                        string.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                    }
                    
                    
                    string.draw(in: line.rect(s: self.trueScale))
                }
                
                
                
                
            } else if line.typeOfStroke == .graph {
                let e = CGRect(x: line.points[0].x - 20 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y - 20 * self.GRAPHSCALE * self.trueScale, width: 40 * self.GRAPHSCALE * self.trueScale, height: 40 * self.GRAPHSCALE * self.trueScale)
                
                let wr = CGRect(x: line.points[0].x - 22 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y - 22 * self.GRAPHSCALE * self.trueScale, width: 44 * self.GRAPHSCALE * self.trueScale, height: 54 * self.GRAPHSCALE * self.trueScale)
                context.setStrokeColor(line.color.cgColor)
                
                context.setFillColor(line.color.with(alpha: 1).cgColor)
                let wrPath = context.drawRect(wr, cornerRadius: 20 * self.trueScale)
                wrPath.fill()
                
                
                context.setFillColor(CGColor.black)
                let ePath = context.drawRect(e, cornerRadius: 10 * self.trueScale)
                ePath.fill()
                
                let p = line.points.except(ind: 0).split(by: line.skipIndexes)
                //                                        //print("Points", p)
                p.forEach { ap in
                    context.addLines(between: ap)
                }
                context.strokePath()
                
                let _p = CGPoint(x: line.points[0].x - 19 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y + 22 * self.GRAPHSCALE * self.trueScale)
                let text = "\(line.textValue)"
                let color = CGColor.black
                let fontSize: CGFloat = 20 * self.trueScale
                let font = CTFont("SF Symbols" as CFString, size: fontSize)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byTruncatingTail
                paragraphStyle.alignment = .left
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraphStyle]
                
                let string = NSAttributedString(string: text, attributes: attributes)
                let _line = CTLineCreateWithAttributedString(string)
                
                context.textPosition = _p
                CTLineDraw(_line, context)
                
                
            } else if line.typeOfStroke == .image {
                if let imgData = line.imageData {
                    let image = NSImage(data: imgData)!
                
                    if self.imageDictionary[line.id] == nil {
                        // Hasn't drewn image yet
                        let imageView = NSImageView(image: image)
                        imageView.imageScaling = .scaleProportionallyUpOrDown
                        self.layer?.backgroundColor = .clear
                        imageView.translatesAutoresizingMaskIntoConstraints = false
                        let _p = line.points[0]
                        let ox = imageView.leftAnchor.constraint(equalTo: self.centerXAnchor, constant: _p.x - self.bounds.width / 2)
                        let oy = imageView.bottomAnchor.constraint(equalTo: self.centerYAnchor, constant: self.bounds.height / 2 - _p.y)

                        let wx = imageView.widthAnchor.constraint(equalToConstant: image.size.width / 5 * trueScale)

                        let hy = imageView.heightAnchor.constraint(equalToConstant: image.size.height / 5 * trueScale)
                        let v = NSImageWithConstraints(offsetX: ox, offsetY: oy, widthConstraint: wx, heightConstraint: hy, image: image, view: imageView)
                        self.imageDictionary[line.id] = v
                    } else {
                        // LINE IS MADE ALREADY
                        let vlin = self.imageDictionary[line.id]
                        let _p = line.points[0]
                        vlin?.offsetX.constant = _p.x - self.bounds.width / 2
                        vlin?.offsetY.constant = self.bounds.height / 2 - _p.y
                        vlin?.widthConstraint.constant = image.size.width / 5 * trueScale
                        vlin?.heightConstraint.constant = image.size.height / 5 * trueScale

                    }
                }
            }
            context.restoreGState()
            context.saveGState()
            if line.selected {
                context.setLineDash(phase: 10, lengths: [10])
                context.setStrokeColor(XColor(calibratedRed: 0.4, green: 0.5, blue: 0.6, alpha: 0.5).cgColor)
                context.setLineWidth(2.0)
                context.addRect(line.rect(s: self.trueScale))
                context.strokePath()
            }
            context.restoreGState()
            context.saveGState()
            if line.typeOfStroke == .text && line.selected {
                if line.id != self.sEnv.wrappedValue.selectedTextField.id {
                    if self.sEnv.wrappedValue.toolInUse == .select && self.sEnv.wrappedValue.selectJustOne == true {
                        self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: line)
                        self.sEnv.wrappedValue.selectedTextField = line
                    } else if self.sEnv.wrappedValue.selectJustOne == false {
                        self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: Stroke(id: UUID(uuid: UUID_NULL), selected: false))
                        self.sEnv.wrappedValue.selectedTextField = Stroke(id: UUID(uuid: UUID_NULL), selected: false)
                    }
                    
                }
            }
            context.restoreGState()
            context.saveGState()
            context.setStrokeColor(XColor(calibratedRed: 0, green: 0.6, blue: 1, alpha: 1).cgColor)
            context.setLineWidth(1.0)
            context.setLineDash(phase: 10, lengths: [10])
            context.addRect(self.sEnv.wrappedValue.selectedRect)
            context.strokePath()
            context.restoreGState()
			
			if sEnv.wrappedValue.firstSelected().typeOfStroke != .text {
	//            print("None")
				self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: .init(id: UUID(uuid: UUID_NULL), selected: false))
				self.sEnv.wrappedValue.selectedTextField = .init(id: UUID(uuid: UUID_NULL), selected: false)
			}
        }
        
        
        currentTextFieldDidMove()
        
       
        
    }
    
    func currentTextFieldDidMove() {
        if offsetYConstraint != nil, offsetXConstraint != nil, self.sEnv.wrappedValue.selectedTextField.id != UUID(uuid: UUID_NULL) {
            let sl = self.sEnv.wrappedValue.strokes.first(where: {$0.id == self.sEnv.wrappedValue.selectedTextField.id})
            if let sl = sl {
                let _p = sl.points[0].convertTo(scale: trueScale, andOffset: trueOffset)
                self.offsetXConstraint.constant = _p.x-self.bounds.width / 2
                self.offsetYConstraint.constant = self.bounds.height / 2 - _p.y + String.BIAS
            }
        }
        
        if self.widthConstraint != nil, self.heightConstraint != nil {
            let sel = self.sEnv.wrappedValue.selectedTextField.id
            if sel != UUID(uuid: UUID_NULL) {
                
                let textValue = self.sEnv.wrappedValue.strokes.first(where: { $0.id == sel })?.textValue ?? "No"
                
                var textString: NSString = NSString(string: textValue)
                var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: NSFont(name: "Avenir", size: 30 * self.trueScale)!])
                
                let sz = labelSize.size
                
                self.widthConstraint.constant = sz.width + WIDTHTEXTBIAS * self.trueScale
                self.heightConstraint.constant = sz.height + WIDTHTEXTBIAS * self.trueScale
            }
            
        }
        
        
    }
    
    func currentTextFieldWillChange(from old: Stroke, to line: Stroke) {
//        print("Textfield changed")
        if self.textFieldViewController != nil {
            self.textFieldViewController.removeFromSuperview()
        }
        
        let textField = SelectedTextFieldView(line: line, scrollEnv: self.sEnv, trueScale: trueScale)
        let vc = NSHostingView(rootView: textField)
        self.textFieldViewController = vc
        
        
        
        if line.id != UUID(uuid: UUID_NULL) {
            self.addSubview(textFieldViewController)
            textFieldViewController.translatesAutoresizingMaskIntoConstraints = false
            if self.offsetXConstraint != nil, self.offsetYConstraint != nil {
                self.offsetYConstraint.isActive = false
                self.offsetXConstraint.isActive = false
            }
            if self.widthConstraint != nil, self.heightConstraint != nil {
                self.widthConstraint.isActive = false
                self.heightConstraint.isActive = false
            }
            let str = self.sEnv.wrappedValue.selectedTextField.textValue
            var textString: NSString = NSString(string: str)
            var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: NSFont(name: "Avenir", size: 30 * self.trueScale)!])
            let sz = labelSize.size
            let _p = line.points[0].convertTo(scale: trueScale, andOffset: trueOffset)
            self.offsetXConstraint = textFieldViewController.leftAnchor.constraint(equalTo: self.centerXAnchor, constant: _p.x-self.bounds.width/2)
            self.offsetXConstraint.isActive = true
            self.offsetYConstraint = textFieldViewController.topAnchor.constraint(equalTo: self.centerYAnchor, constant: self.bounds.height / 2 - _p.y + String.BIAS)
            self.offsetYConstraint.isActive = true
            self.widthConstraint = textFieldViewController.widthAnchor.constraint(equalToConstant: sz.width)
            self.widthConstraint.isActive = true
            self.heightConstraint = textFieldViewController.heightAnchor.constraint(equalToConstant: sz.height)
            self.heightConstraint.isActive = true
        }
        
    }
    
    
    private var bias: XPoint = .init(x: 100, y: 100)
    
    func addNewTextView(textValue: Text, id: UUID) -> (centerX: NSLayoutConstraint, centerY: NSLayoutConstraint) {
        let label = XHostingView(rootView: Text("Hello"))
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let cx = label.centerXAnchor.constraint(equalTo: self.leadingAnchor)
        let cy = label.centerYAnchor.constraint(equalTo: self.topAnchor, constant: self.bounds.height)
        cx.isActive = true
        cy.isActive = true
        NotificationCenter.default.addObserver(forName: .redrawTextViews, object: nil, queue: nil) { n in
            cx.constant = self.trueOffset.x
            cy.constant = self.bounds.height - self.trueOffset.y
        }
        return (cx, cy)
    }
    
    var textFieldViewController: NSView!
    var offsetXConstraint: NSLayoutConstraint!
    var offsetYConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>, notesFetch: FetchedResults<NoteData>, moc: NSManagedObjectContext) {
        self.moc = moc
        
        self.sEnv = scrollEnv
        self.notesFetch = notesFetch
        
        super.init(frame: XRect(x: 0, y: 0, width: 200, height: 200))
        
        NotificationCenter.default.addObserver(forName: .revertedAction, object: nil, queue: nil) { n in
            let obj = n.object as! NoteAction
            if obj.type == .strokeAction {
                self.whenInRevertedModify(forStroke: self.sEnv.wrappedValue.strokes[withId: obj.strokeID], ofNoteID: self.sEnv.wrappedValue.currentNoteId)
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: .didChangeNote, object: nil, queue: nil) { n in
            let image = self.toImage()!
            let noteId = self.sEnv.wrappedValue.currentNoteId
            let note = self.notesFetch.first { nd in
                nd.noteId == noteId
            }
            note?.image = image.tiffRepresentation
            try? self.moc.save()
        }
        
        
        NotificationCenter.default.addObserver(forName: .didChangeSelectedText, object: nil, queue: nil) {[self] n in
            self.setNeedsDisplay(self.bounds)
        }
    }
    
    func modify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionColor.insert()
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionWidth.insert()
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionPoints.insert()
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionText.insert()
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
                setNeedsDisplay(self.bounds)
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    
    func whenInRevertedModify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    //                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, primordialType: .reverted)
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    //                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, primordialType: .reverted)
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    //                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, primordialType: .reverted)
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    //                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, primordialType: .reverted)
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
                setNeedsDisplay(self.bounds)
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    override func draw(_ dirtyRect: XRect) {
        super.draw(dirtyRect)
        self.drawGuides()
        self.drawShit()
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
}
#elseif os(iOS)

extension CGContext {
    func drawRect(_ rect: CGRect, cornerRadius c: CGFloat) -> UIBezierPath {
        let pat = UIBezierPath(roundedRect: rect, cornerRadius: c)
        return pat
    }
    
    
    func drawSmoothLine(from points: [CGPoint]) {
        self.addLines(between: points)
        self.strokePath()
    }
}

class DrawImages: UIView {
    var moc: NSManagedObjectContext
    
    var notesFetch: FetchedResults<NoteData>
    
    var sEnv: EnvironmentObject<ScrollEnv>
    
    var trueOffset: CGPoint = .zero
    var zoomBias: CGPoint = .zero
    var trueScale: CGFloat = 1
    var dragOffset: CGSize = .zero
    
    var GRAPHSCALE: CGFloat = 5
    
    var ctx: CGContext? = nil
    
    
    var imageDictionary: [UUID: NSImageWithConstraints] = [:] {
        didSet {
            // MARK: DRAW IMAGES
            if imageDictionary.isEmpty {
                for c in self.subviews {
                    if true {
                        c.removeFromSuperview()
                    }
                }
            }
            for (keyId, imageCon) in imageDictionary {
                if imageCon.view.superview == self {
                    
                } else {
                    self.addSubview(imageCon.view)
                    imageCon.view.translatesAutoresizingMaskIntoConstraints = false
                    
                    imageCon.offsetX.isActive = true
                    imageCon.offsetY.isActive = true
                    imageCon.heightConstraint.isActive = true
                    imageCon.widthConstraint.isActive = true
                }
            }
        }
    }
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>, notesFetch: FetchedResults<NoteData>, moc: NSManagedObjectContext) {
        self.moc = moc
        
        self.sEnv = scrollEnv
        self.notesFetch = notesFetch
        
        
        super.init(frame: XRect(x: 0, y: 0, width: 200, height: 200))
        
        //
        NotificationCenter.default.addObserver(forName: .didChangeNote, object: nil, queue: nil) { not in
            self.updateSelf()
        }
        
        
        NotificationCenter.default.addObserver(forName: .didResetTransform, object: nil, queue: nil) { n in
            self.updateSelf()
            self.trueScale = 1
            self.trueOffset = .zero
        }
        
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func endOfEvents() {}
    
    
    func updateSelf() {
        self.imageDictionary = [:]
    }
	
	
	
    var movingShit = false
    
    
}

class NSImageWithConstraints {
    var offsetX: NSLayoutConstraint
    var offsetY: NSLayoutConstraint
    var widthConstraint: NSLayoutConstraint
    var heightConstraint: NSLayoutConstraint
    var image: UIImage
    var view: UIView
    init(offsetX: NSLayoutConstraint, offsetY: NSLayoutConstraint, widthConstraint: NSLayoutConstraint, heightConstraint: NSLayoutConstraint, image: UIImage, view: UIView) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.widthConstraint = widthConstraint
        self.heightConstraint = heightConstraint
        self.image = image
        self.view = view
    }
    
}


class DrawViewFBFController: UIViewController {
    var moc: NSManagedObjectContext
    
    var notesFetch: FetchedResults<NoteData>
    
    var sEnv: EnvironmentObject<ScrollEnv>
    
    init(moc: NSManagedObjectContext, notesFetch: FetchedResults<NoteData>, sEnv: EnvironmentObject<ScrollEnv>) {
        
        self.moc = moc
        self.notesFetch = notesFetch
        self.sEnv = sEnv
        self.drawRestOfLinesView = DrawViewFBF(scrollEnv: self.sEnv, notesFetch: self.notesFetch, moc: self.moc, controller: nil)
        
        self.drawRestOfImagesView = DrawImages(scrollEnv: self.sEnv, notesFetch: self.notesFetch, moc: self.moc)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var drawRestOfLinesView: DrawViewFBF!
    
    override func loadView() {
        super.loadView()
        self.drawRestOfLinesView = DrawViewFBF(scrollEnv: self.sEnv, notesFetch: self.notesFetch, moc: self.moc, controller: self)
        
        self.drawRestOfImagesView = DrawImages(scrollEnv: self.sEnv, notesFetch: self.notesFetch, moc: self.moc)
        self.view = UIView(frame: .infinite)
        self.drawRestOfLinesView.layer.isOpaque = false
        self.drawRestOfImagesView.isOpaque = false
        self.drawRestOfLinesView.isOpaque = false
        
        self.view.addSubview(self.drawRestOfLinesView)
        self.view.addSubview(self.drawRestOfImagesView)
        self.view.sendSubviewToBack(self.drawRestOfImagesView)
        self.drawRestOfLinesView.translatesAutoresizingMaskIntoConstraints = false
        self.drawRestOfLinesView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.drawRestOfLinesView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        self.drawRestOfImagesView.translatesAutoresizingMaskIntoConstraints = false
        self.drawRestOfImagesView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.drawRestOfImagesView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    }
    
    func updateSelf() {
        self.drawRestOfLinesView.setNeedsDisplay()
        self.drawRestOfLinesView.trueOffset = self.trueOffset
        self.drawRestOfLinesView.trueScale = self.trueScale
    }
    
	var eventTranslation: CGPoint? = .zero
	var instantaneousEventTranslation: CGPoint? = .zero
	var initialTouch: CGPoint? = .zero
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.senderState = .began
		self.initialTouch = touches.first!.location(in: self.view)
		var allTouches: [UITouch] = .init()
		
		for touch in touches {
			allTouches.append(contentsOf: event?.coalescedTouches(for: touch) ?? [])
		}
		let locations = allTouches.map({$0.location(in: self.view)})
		self.mouseDown(locations: locations)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.senderState = .none
		let touchLocation = touches.first!.location(in: self.view)
		let oldEventTranslation = self.eventTranslation ?? .zero
		self.eventTranslation = touchLocation - self.initialTouch!
		self.instantaneousEventTranslation = self.eventTranslation! - oldEventTranslation
		
		var allTouches: [UITouch] = .init()
		
		for touch in touches {
			allTouches.append(contentsOf: event?.coalescedTouches(for: touch) ?? [])
		}
		let locations = allTouches.map({$0.location(in: self.view)})
		
		self.mouseDragged(locations: locations)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.senderState = .ended
		self.instantaneousEventTranslation = .zero
		self.eventTranslation = .zero
		self.mouseUp()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did load!")
        
        let pinchGesture = UIPinchGestureRecognizer()
        
        pinchGesture.addTarget(self, action: #selector(self.magnify(_:)))
        
        self.view.addGestureRecognizer(pinchGesture)
        self.view.clearsContextBeforeDrawing = true
        NotificationCenter.default.addObserver(forName: .revertedAction, object: nil, queue: nil) { n in
            let obj = n.object as! NoteAction
            if obj.type == .strokeAction {
                self.whenInRevertedModify(forStroke: self.sEnv.wrappedValue.strokes[withId: obj.strokeID], ofNoteID: self.sEnv.wrappedValue.currentNoteId)
            }
            
        }
		
		NotificationCenter.default.addObserver(forName: .getOffsetAndScale, object: nil, queue: nil) { not in
					GetOffsetAndScale.offsetX = self.trueOffset.x
					GetOffsetAndScale.offsetY = self.trueOffset.y
					GetOffsetAndScale.scale = self.trueScale
				}
				
		NotificationCenter.default.addObserver(forName: .setOffsetAndScale, object: nil, queue: nil) { not in
			self.updateSelf()
			Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
				//				print(self.trueOffset)
				self.trueOffset.x = self.trueOffset.x + (SetOffsetAndScale.offsetX - self.trueOffset.x) / 10
				self.trueOffset.y = self.trueOffset.y + (SetOffsetAndScale.offsetY - self.trueOffset.y) / 10
				self.trueScale = self.trueScale + (SetOffsetAndScale.scale - self.trueScale) / 10
				//				print(SetOffsetAndScale.offsetX, SetOffsetAndScale.offsetY)
				
				
				
				self.updateSelf()
				if abs(self.trueOffset.x - SetOffsetAndScale.offsetX) < 10 && abs(self.trueScale - SetOffsetAndScale.scale) < 0.1 && abs(self.trueOffset.y - SetOffsetAndScale.offsetY) < 10 {
					self.trueOffset.x = SetOffsetAndScale.offsetX
					self.trueOffset.y = SetOffsetAndScale.offsetY
					self.trueScale = SetOffsetAndScale.scale
					timer.invalidate()
					
				}
				
			}
		}
    }
    
    
    func modify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionColor.insert()
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionWidth.insert()
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionPoints.insert()
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionText.insert()
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    
    func whenInRevertedModify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    //                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, primordialType: .reverted)
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    //                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, primordialType: .reverted)
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    //                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, primordialType: .reverted)
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    //                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, primordialType: .reverted)
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    
    // MARK: GESTURES
    
    var trueOffset: CGPoint = .zero
    var trueScale: CGFloat = 1
    
    
    var oldOffset = CGPoint.zero
    
//    @objc
//    func scrollWheel(_ sender: UIPanGestureRecognizer) {
//        
//        if sender.numberOfTouches == 2 || (self.sEnv.wrappedValue.toolInUse == .move && sender.numberOfTouches >= 1) {
//            if sender.state == .began {
//                self.oldOffset = self.trueOffset
//            } else {
//                
//                self.updateSelf()
//                
//                let scrollingDeltaXAndY = sender.translation(in: self.view)
//                let scrollingDeltaX = scrollingDeltaXAndY.x
//                let scrollingDeltaY = scrollingDeltaXAndY.y
//                self.trueOffset = CGPoint(x: self.oldOffset.x + scrollingDeltaX,
//                                          y: self.oldOffset.y + scrollingDeltaY)
//            }
//        } else if sender.numberOfTouches == 1 {
//            self.mouseDragged()
//        } else if sender.numberOfTouches == 0 {
//            self.mouseUp()
//        }
//    }
    
    private var scaleVal: CGFloat = 1.0
    
    
    var oldScaleOffset: CGPoint = .zero
    var oldScale = CGFloat(1)
    var __oldScale = CGFloat(1)
    var drawRestOfImagesView: DrawImages!
    var imageDictionary: [UUID: NSImageWithConstraints] = [:] {
        didSet {
            //
            self.drawRestOfImagesView.imageDictionary = self.imageDictionary
        }
    }
    
    var zoomBias: XPoint = .zero
    
    // MARK: - DRAG
    @objc
    func magnify(_ sender: UIPinchGestureRecognizer) {
		self.drawRestOfLinesView.drawTheShit = true
        if sender.state == .began {
            self.oldScaleOffset = self.trueOffset
            self.oldScale = self.trueScale
            self.__oldScale = self.trueScale
        }
        if sender.numberOfTouches >= 2 {
            let locationInSelf = sender.location(in: self.view)
            let eventmagnification = sender.scale
            //print(self.trueScale)
            self.updateSelf()
            if sender.state == .began {
                self.zoomBias = XPoint(x: locationInSelf.x, y: locationInSelf.y)
            }
            //
            self.trueScale = Math.calculateScale(fromMouseScale: eventmagnification, andOldScale: self.oldScale)
            self.trueOffset = Math.calculateOffset(fromMouseScale: eventmagnification, andOldOffset: self.oldScaleOffset, withMousePosition: self.zoomBias)
            
        }
    }
    
    // MARK: - CLICK
    @objc
	func mouseDown(locations: [CGPoint]) {
        self.updateSelf()
       
        let l3 = locations
        
        
        if self.sEnv.wrappedValue.toolInUse == .image {
			self.sEnv.wrappedValue.addImageLocation = l3.first!
            self.sEnv.wrappedValue.presentIOSPhotoPicker = true
            return
        }
        
        if self.sEnv.wrappedValue.toolInUse != .move {
            if self.sEnv.wrappedValue.toolInUse != .select {
                self.sEnv.wrappedValue.currentStroke.createdAt = Date()
                self.sEnv.wrappedValue.currentStroke.color = self.sEnv.wrappedValue.selectedColor
                self.sEnv.wrappedValue.currentStroke.width = CGFloat(self.sEnv.wrappedValue.selectedWidth)
                self.sEnv.wrappedValue.currentStroke.typeOfStroke = self.sEnv.wrappedValue.toolInUse
                self.sEnv.wrappedValue.currentStroke.id = UUID()
				if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .pencil {
					self.sEnv.wrappedValue.currentStroke.points = l3
				}
                if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .line || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .circle || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .rectangle {
					self.sEnv.wrappedValue.currentStroke.points = [l3.first!]
                } else if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .text || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .graph {
					self.sEnv.wrappedValue.currentStroke.points = [l3.first!]
                    self.sEnv.wrappedValue.currentStroke.textValue = self.sEnv.wrappedValue.selectedTextText
                }
            } else {
                // SELECTION
                if self.sEnv.wrappedValue.selectJustOne {
                    for l in self.sEnv.wrappedValue.strokes {
                        if l.selected {
                            self.modify(forStroke: l, ofNoteID: self.sEnv.wrappedValue.currentNoteId)
                        }
                    }
                    
                    if self.sEnv.wrappedValue.editGraph, self.sEnv.wrappedValue.selectedLinesCount() == 1 {
                    } else {
                        self.sEnv.wrappedValue.clearSelection()
                        
                        for (ind, st) in self.sEnv.wrappedValue.strokes.enumerated() {
							if st.contains(pointToDefault: l3.first!, viewScale: self.trueScale, andOffset: self.trueOffset) {
                                if self.sEnv.wrappedValue.selectJustOne {
                                    self.sEnv.wrappedValue.strokes[ind].selected = true
                                    
                                } else {
                                    self.sEnv.wrappedValue.strokes[ind].selected = true
                                }
                            }
                        }
                    }
                    if self.sEnv.wrappedValue.selectedLinesCount() >= 1 {
                        let f = self.sEnv.wrappedValue.firstSelected()
                        self.sEnv.wrappedValue.selectedTextText = f.textValue
                    }
                }
                
                if self.sEnv.wrappedValue.selectJustOne == false, self.sEnv.wrappedValue.selectedLinesCount() == 0 {
					self.sEnv.wrappedValue.selectedRect.origin = l3.first!
                }
            }
            
        }
        if senderState == .ended {
            self.mouseUp()
        }
    }
    
	enum SenderState {
		case began
		case ended
		case none
	}
	var senderState = SenderState.began
    var oldRectSize = CGSize.zero
    var dragOffset = CGSize.zero
    var modOldDragOffset = CGSize.zero
    // MARK: - DRAG
    @objc
	func mouseDragged(locations: [CGPoint]) {
        
        
        self.updateSelf()
        let locations = locations
        if senderState == .began {
            self.mouseDown(locations: locations)
        }
        //        //print("Dragged")
        if self.sEnv.wrappedValue.toolInUse != .move {
            let l3 = locations
            let eventdelta = eventTranslation!
            let eventdeltaX = eventdelta.x
            let eventdeltaY = eventdelta.y
            //        //print(eventdelta)
            if senderState == .began {
                self.dragOffset = .zero
                self.modOldDragOffset = .zero
                
            }
            if self.sEnv.wrappedValue.toolInUse != .select {
                if self.sEnv.wrappedValue.currentStroke.typeOfStroke == .line || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .circle || self.sEnv.wrappedValue.currentStroke.typeOfStroke == .rectangle {
                    if self.sEnv.wrappedValue.currentStroke.points.count >= 1 {
						self.sEnv.wrappedValue.currentStroke.points = [self.sEnv.wrappedValue.currentStroke.points[0], l3.first!]
                    }
                } else if self.sEnv.wrappedValue.currentStroke.typeOfStroke != .text {
					self.sEnv.wrappedValue.currentStroke.points.append(contentsOf: l3)
                }
            } else {
                self.modOldDragOffset = self.dragOffset
                self.dragOffset.width = eventdeltaX
                self.dragOffset.height = eventdeltaY
                //            //print(self.dragOffset)
                for n in 0 ..< self.sEnv.wrappedValue.strokes.count {
                    if self.sEnv.wrappedValue.strokes[n].selected {
                        self.sEnv.wrappedValue.strokes[n].points.transform(
                            by: CGSize(width: self.dragOffset.width - self.modOldDragOffset.width, height: self.dragOffset.height - self.modOldDragOffset.height),
                            scale: self.trueScale, offset: self.trueOffset)
                    }
                }
                
                if senderState == .began {
                    self.oldRectSize = self.sEnv.wrappedValue.selectedRect.size
                }
                
                if self.sEnv.wrappedValue.selectedLinesCount() == 0, self.sEnv.wrappedValue.selectJustOne == false {
                    self.sEnv.wrappedValue.selectedRect.size = CGSize(width: self.oldRectSize.width + eventdeltaX, height: self.oldRectSize.height + eventdeltaY)
                }
				self.drawRestOfLinesView.drawTheShit = true
            }
		} else {
			
			self.trueOffset = self.trueOffset + self.instantaneousEventTranslation!
			self.drawRestOfLinesView.drawTheShit = true
		}
		
        
    }
    
    func save(stroke str: Stroke) {
        guard !self.sEnv.wrappedValue.strokes.contains(where: {$0.id == str.id}) else {
            return
        }
        if str.typeOfStroke == .graph {
            self.sEnv.wrappedValue.strokes.append(str.graph(o: self.trueOffset, s: self.trueScale).convertToDefault(scale: self.trueScale, offset: self.trueOffset))
            
        } else {
            self.sEnv.wrappedValue.strokes.append(str.convertToDefault(scale: self.trueScale, offset: self.trueOffset))
        }
        
        let stroke = StrokeData(context: self.moc)
        
        if str.typeOfStroke != .graph {
            stroke.pointSet = CGPointArray(str.points).convertToDefault(scale: self.trueScale, offset: self.trueOffset).toString()
        } else {
            var arr = [CGPoint]()
            arr.append(str.points[0].convertToDefault(scale: self.trueScale, offset: self.trueOffset))
            let aa = str.pointsForExpression(
                withStringFormat: self.sEnv.wrappedValue.selectedTextText,
                insideOffset: .zero, insideScale: 1,
                trueOffset: self.trueOffset, trueScale: self.trueScale
            )
            arr.append(contentsOf: aa.point.scale(by: self.trueScale, around: arr[0]))
            //                    //print(arr)
            stroke.pointSet = CGPointArray(arr).toString()
            stroke.skipIndexes = aa.breakAtIndexes.toString()
        }
        
        stroke.color = str.color.toString()
        //        stroke.documentScale = Float(Double(trueScale))
        if !self.sEnv.wrappedValue.customSwatches.contains(where: { ns in
            ns.getComponents() == str.color.getComponents()
        }) {
            self.sEnv.wrappedValue.customSwatches.append(str.color)
        }
        
        //        //print("OWNED")
        
        stroke.createdAt = str.createdAt
        
        stroke.width = Float(str.width)
        
        stroke.typeOfStroke = str.typeOfStroke.rawValue
        
        stroke.strokeId = str.id
        
        stroke.textValue = str.textValue
        
        stroke.imageData = str.imageData
        
        
        //        //print(stroke.typeOfStroke)
        
        //MARK: Creation Action
        //                let action = NoteAction(env: self.sEnv, strokeProperty: nil, type: .creation, strokeID: stroke.strokeId, str: currentStroke)
        //                action.insert()
        
        stroke.ownedByNote = self.notesFetch.first(where: { $0.noteId == self.sEnv.wrappedValue.currentNoteId })
        
        //                //print("OWNED; \(stroke.ownedByNote?.name ?? "None")")
        
        do {
            try self.moc.save()
        } catch {
            //print(error.localizedDescription)
        }
    }
    
    // MARK: - UP
    @objc
    func mouseUp() {
        self.dragOffset = .zero
        //            //print("Mouseup")
        self.updateSelf()
		NotificationCenter.default.post(name: .mouseUpInView, object: nil)
        if self.sEnv.wrappedValue.toolInUse != .move {
            if self.sEnv.wrappedValue.toolInUse != .select {
                let currentStroke = self.sEnv.wrappedValue.currentStroke
                if currentStroke.points != [] {
                    
                    
                    self.save(stroke: self.sEnv.wrappedValue.currentStroke)
                }
                self.sEnv.wrappedValue.currentStroke = Stroke(points: [], originalScale: self.sEnv.wrappedValue.currentStroke.originalScale, id: UUID(uuid: UUID_NULL), textValue: "", skipIndexes: [], selected: false)
            } else if self.sEnv.wrappedValue.selectJustOne == false {
                self.sEnv.wrappedValue.strokes.forEach { i in
                    self.modify(forStroke: i, ofNoteID: self.sEnv.wrappedValue.currentNoteId)
                }
                self.sEnv.wrappedValue.clearSelection()
                
                for (j, st) in self.sEnv.wrappedValue.strokes.enumerated() {
                    if st.contains(rectToDefault: self.sEnv.wrappedValue.selectedRect, viewScale: self.trueScale, andOffset: self.trueOffset) {
                        self.sEnv.wrappedValue.strokes[j].selected = true
                    }
                }
                self.sEnv.wrappedValue.selectedRect = .zero
            } else if self.sEnv.wrappedValue.selectJustOne == true {
                if self.sEnv.wrappedValue.selectedLinesCount() != 0 {
                    let fs = self.sEnv.wrappedValue.firstSelected()
                    
                    self.sEnv.wrappedValue.selectedColorArr = [fs.color.getComponents().red, fs.color.getComponents().green, fs.color.getComponents().blue, fs.color.getComponents().alpha]
                    NotificationCenter.default.post(name: .didChangeColorFromSelection, object: nil)
                }
            }
            
        }
		self.drawRestOfLinesView.drawTheShit = true
    }
}

class DrawViewFBF: UIView {
    var moc: NSManagedObjectContext
    
    var notesFetch: FetchedResults<NoteData>
    
    var sEnv: EnvironmentObject<ScrollEnv>
    
    var trueOffset: CGPoint = .zero
    var zoomBias: CGPoint = .zero
    var trueScale: CGFloat = 1
    var dragOffset: CGSize = .zero
    
    var GRAPHSCALE: CGFloat = 5
    var controller: DrawViewFBFController?
	
	var textFieldViewController: UIView!
	var offsetXConstraint: NSLayoutConstraint!
	var offsetYConstraint: NSLayoutConstraint!
	var widthConstraint: NSLayoutConstraint!
	var heightConstraint: NSLayoutConstraint!
	
	var drawingLayer: CALayer? = nil
	var currentLineDrawingLayer: CAShapeLayer? = nil
    
    // MARK: - DRAW GUIDES
    
	
    func drawGuides() {
        guard let context = UIGraphicsGetCurrentContext() else {
            //            //print("No")
            return
        }
        context.saveGState()
        if self.sEnv.wrappedValue.showGrid {
            var geo = CGSize(width: self.bounds.width, height: self.bounds.height)
            let facInt = Double(Int(log2(1 / self.trueScale)))
            let scalePow: CGFloat = .init(pow(2, facInt))
            let multi: CGFloat = .init(100 * scalePow)
            let step = multi
            let modx = CGFloat(fmod(Double(self.trueOffset.x), Double(multi * self.trueScale)))
            let mody = CGFloat(fmod(Double(self.trueOffset.y), Double(multi * self.trueScale)))
            for i in stride(from: 0, to: max(geo.width, geo.height) / self.trueScale, by: step) {
                context.setStrokeColor(XColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.2).cgColor)
                context.addLines(between: CGPointArray([
                    CGPoint(x: i, y: 0),
                    CGPoint(x: i, y: max(geo.width, geo.height) / self.trueScale + 0)
                ]).convertTo(scale: self.trueScale, andOffset: CGPoint(x: modx, y: mody)).arr)
                context.strokePath()
                
                context.addLines(between: CGPointArray([
                    CGPoint(x: 0, y: i),
                    CGPoint(x: max(geo.width, geo.height) / self.trueScale + 0, y: i)
                ]).convertTo(scale: self.trueScale, andOffset: CGPoint(x: modx, y: mody)).arr)
                
                context.strokePath()
            }
        }
        context.restoreGState()
    }
    
    // MARK: - DRAW
    
    func clrscr() {
        
    }
    
    var imageDictionary: [UUID: NSImageWithConstraints] = [:] {
        didSet {
            self.controller?.imageDictionary = imageDictionary
        }
    }
	
	
	private func draw(bezierPath path: UIBezierPath, addInLayer: Bool = true, line: Stroke) -> CAShapeLayer {
		let shapeLayer = CAShapeLayer()
		shapeLayer.path = path.cgPath
		shapeLayer.strokeColor = line.color.cgColor
		shapeLayer.fillColor = nil
		if addInLayer {
			self.drawingLayer?.addSublayer(shapeLayer)
		}
		return shapeLayer
	}
	
	func setupDrawingLayer() {
		if(self.drawingLayer == nil) {
			let newLayer = CALayer()
			newLayer.contentsScale = UIScreen.main.scale
			self.layer.addSublayer(newLayer)
			self.drawingLayer = newLayer
		}
	}
	
	
	
	var drawTheShit = true
	
	var caLayerDictionary = [CALayer: Stroke]()
	
	func drawShit() {
		let currentLine = self.sEnv.wrappedValue.currentStroke
		if currentLine.points.count != 0 {
			if let currentLinePath = UIBezierPath.from(normalizedLine: currentLine) {
				let layer = self.draw(bezierPath: currentLinePath, addInLayer: false, line: currentLine)
				self.caLayerDictionary[layer] = currentLine
				if self.currentLineDrawingLayer == nil {
					self.currentLineDrawingLayer = layer
					self.drawingLayer?.addSublayer(self.currentLineDrawingLayer!)
				} else {
					self.currentLineDrawingLayer!.path = currentLinePath.cgPath
				}
			}
		}
		if !drawTheShit {
			return;
		} else {
			drawTheShit = false
		}
		if self.drawingLayer == nil {
			setupDrawingLayer()
			let strokes = self.sEnv.wrappedValue.strokes
			let all = strokes
			let allUnScaled = all
			
			for line in allUnScaled {
				guard let pathToDraw = UIBezierPath.from(normalizedLine: line) else {continue}
				let ly = self.draw(bezierPath: pathToDraw, line: line.convertTo(scale: trueScale, andOffset: trueOffset))
				self.caLayerDictionary[ly] = line
			}
		} else {
			let childLayerArray = self.drawingLayer?.sublayers ?? []
			let childShapeLayerArray = childLayerArray as! [CAShapeLayer]
			for childLayer in childShapeLayerArray {
				let stroke = self.caLayerDictionary[childLayer]
				childLayer.path = nil
				childLayer.path = UIBezierPath.from(normalizedLine: stroke!.convertTo(scale: trueScale, andOffset: trueOffset))?.cgPath
			}
		}
	}
	
	func prepareForMagnification() {
		self.drawingLayer?.removeFromSuperlayer()
		self.drawingLayer = nil
		let _ = self.convertToImage()
	}
	
	func convertToImage() -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
		let output = UIGraphicsGetImageFromCurrentImageContext()
		let sview = UIImageView(image: output)
		self.addSubview(sview)
		sview.translatesAutoresizingMaskIntoConstraints = false
		sview.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		sview.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		sview.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
		sview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
		return output
	}
	
	
	
    func olddrawShit() {
        guard let context = UIGraphicsGetCurrentContext() else {
            //            //print("No")
            return
        }
        
        if self.sEnv.wrappedValue.resetScaleAndOffset {
            self.trueScale = 1
            self.trueOffset = .zero
            self.sEnv.wrappedValue.resetScaleAndOffset = false
        }
        
        let strokes = self.sEnv.wrappedValue.strokes
        let all = strokes
        let allScaled = all.map { stroke -> Stroke in
            stroke.convertTo(scale: trueScale, andOffset: trueOffset)
        }
        
        let ALL = allScaled.combined(with: self.sEnv.wrappedValue.currentStroke)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        for line in ALL {
            if !line.rect(s: trueScale).intersects(.init(x: self.bounds.minX, y: self.bounds.minY, width: self.bounds.width, height: self.bounds.height)) {
                continue
            }
            context.saveGState()
            if self.sEnv.wrappedValue.scaleByWidth {
                context.setLineWidth(line.width * self.trueScale)
            } else {
                context.setLineWidth(line.width)
            }
            if line.typeOfStroke == .line || line.typeOfStroke == .pencil {
                context.setStrokeColor(line.color.cgColor);
                
                context.addLines(between: line.points)
                
                context.strokePath()
            } else if line.typeOfStroke == .circle {
                if line.points.count >= 2 {
                    context.setStrokeColor(line.color.cgColor)
                    context.addEllipse(in: CGRect(origin: line.points[0], size: CGSize(width: line.points[1].x - line.points[0].x, height: line.points[1].y - line.points[0].y)))
                    
                    context.strokePath()
                }
                
            } else if line.typeOfStroke == .rectangle {
                if line.points.count >= 2 {
                    context.setStrokeColor(line.color.cgColor)
                    context.addRect(CGRect(origin: line.points[0], size: CGSize(width: line.points[1].x - line.points[0].x, height: line.points[1].y - line.points[0].y)))
                    
                    context.strokePath()
                }
            } else if line.typeOfStroke == .text {
				let text = "\(line.textValue)"
				let color = line.color
				let fontSize: CGFloat = 30 * self.trueScale
				let font = UIFont(name: "Avenir", size: fontSize)!
				let boldFont = UIFont(name: "Avenir-Heavy", size: fontSize)!
				let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: font]
			
				let a = text.textToText()
				let string = NSMutableAttributedString(string: a.string, attributes: attributes)
				let boldArr = a.boldRanges
				boldArr.forEach { range in
					string.addAttribute(.font, value: boldFont, range: range)
				}
				
				let italicArr = a.italicRanges
				italicArr.forEach{ range in
					string.addAttribute(.obliqueness, value: 0.2, range: range)
					
				}
				
				let underlineArr: [NSRange] = a.underlineRanges
				
				underlineArr.forEach { range in
					string.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
				}
				
				
				string.draw(in: line.rect(s: self.trueScale))
				let _line = CTLineCreateWithAttributedString(string)
				context.textMatrix = CGAffineTransform.identity
				context.textMatrix = .init(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
				context.textPosition = CGPoint(x: line.points[0].x, y: line.points[0].y)
				
                
            } else if line.typeOfStroke == .graph {
                let e = CGRect(x: line.points[0].x - 20 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y - 20 * self.GRAPHSCALE * self.trueScale, width: 40 * self.GRAPHSCALE * self.trueScale, height: 40 * self.GRAPHSCALE * self.trueScale)
                
                let wr = CGRect(x: line.points[0].x - 22 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y - 22 * self.GRAPHSCALE * self.trueScale, width: 44 * self.GRAPHSCALE * self.trueScale, height: 54 * self.GRAPHSCALE * self.trueScale)
                context.setStrokeColor(line.color.cgColor)
                
                context.setFillColor(line.color.with(alpha: 1).cgColor)
                UIGraphicsPushContext(context)
                let wrPath = context.drawRect(wr, cornerRadius: 20 * self.trueScale)
                wrPath.fill()
                context.setFillColor(CGColor.black)
                let ePath = context.drawRect(e, cornerRadius: 20 * self.trueScale)
                ePath.fill()
                UIGraphicsPopContext()
                
                let p = line.points.except(ind: 0).split(by: line.skipIndexes)
                
                p.forEach { ap in
                    context.addLines(between: ap)
                }
                context.strokePath()
                
                let _p = CGPoint(x: line.points[0].x - 19 * self.GRAPHSCALE * self.trueScale, y: line.points[0].y + 22 * self.GRAPHSCALE * self.trueScale)
                let text = line.textValue
                let color = CGColor.black
                let fontSize: CGFloat = 20 * self.trueScale
                let font = CTFont("SF Symbols" as CFString, size: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                
                let string = NSAttributedString(string: text, attributes: attributes)
                let _line = CTLineCreateWithAttributedString(string)
                
                context.textMatrix = CGAffineTransform.identity
                context.textMatrix = .init(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
                
                context.textPosition = _p + CGPoint(x: 10 * self.trueScale, y: 10 * self.trueScale)
                CTLineDraw(_line, context)
            } else if line.typeOfStroke == .image {
                if let imgData = line.imageData {
                    
                    let image = UIImage(data: imgData)!
                    
                    if self.imageDictionary[line.id] == nil {
                        print("Image")
                        let imageView = UIImageView(image: image)
                        imageView.scalesLargeContentImage = true
                        
                        self.backgroundColor = .clear
                        imageView.translatesAutoresizingMaskIntoConstraints = false
                        let _p = line.points[0]
                        let ox = imageView.leftAnchor.constraint(equalTo: self.centerXAnchor, constant:   _p.x-self.bounds.width / 2)
                        let oy = imageView.topAnchor.constraint(equalTo: self.centerYAnchor, constant: _p.y - self.bounds.height / 2)
                        
                        let wx = imageView.widthAnchor.constraint(equalToConstant: image.size.width / 5 * trueScale)
                        
                        let hy = imageView.heightAnchor.constraint(equalToConstant: image.size.height / 5 * trueScale)
                        
                        
                        let v = NSImageWithConstraints(offsetX: ox, offsetY: oy, widthConstraint: wx, heightConstraint: hy, image: image, view: imageView)
                        self.imageDictionary[line.id] = v
                        
                        
                        
                    } else {
                        // LINE IS MADE ALREADY
                        let vlin = self.imageDictionary[line.id]
                        let _p = line.points[0]
                        vlin?.offsetX.constant = _p.x - self.bounds.width / 2
                        vlin?.offsetY.constant = _p.y - self.bounds.height / 2
                        vlin?.widthConstraint.constant = image.size.width / 5 * trueScale
                        vlin?.heightConstraint.constant = image.size.height / 5 * trueScale
                        
                    }
                }
            }
            context.restoreGState()
            
			if line.typeOfStroke == .text && line.selected {
				if line.id != self.sEnv.wrappedValue.selectedTextField.id {
					if self.sEnv.wrappedValue.toolInUse == .select && self.sEnv.wrappedValue.selectJustOne == true {
						
						self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: line)
						self.sEnv.wrappedValue.selectedTextField = line
						self.currentTextFieldDidMove()
					} else if self.sEnv.wrappedValue.selectJustOne == false {
						self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: Stroke(id: UUID(uuid: UUID_NULL), selected: false))
						self.sEnv.wrappedValue.selectedTextField = Stroke(id: UUID(uuid: UUID_NULL), selected: false)
						self.currentTextFieldDidMove()
					}
					
				}
			}
			
            context.saveGState()
            if line.selected {
                context.setStrokeColor(XColor(calibratedRed: 0.5, green: 0.6, blue: 0.6, alpha: 1).cgColor)
                context.setLineWidth(1.0)
                context.setLineDash(phase: 10, lengths: [10])
                
                context.addRect(line.rect(s: self.trueScale))
                context.strokePath()
            }
            context.setStrokeColor(XColor(calibratedRed: 0, green: 0.6, blue: 1, alpha: 1).cgColor)
            context.setLineWidth(1.0)
            context.addRect(self.sEnv.wrappedValue.selectedRect)
            context.strokePath()
            context.restoreGState()
			
			
			if sEnv.wrappedValue.firstSelected().typeOfStroke != .text {
	//            print("None")
				self.currentTextFieldWillChange(from: self.sEnv.wrappedValue.selectedTextField, to: .init(id: UUID(uuid: UUID_NULL), selected: false))
				self.sEnv.wrappedValue.selectedTextField = .init(id: UUID(uuid: UUID_NULL), selected: false)
				self.currentTextFieldDidMove()
			}
            
        }
		currentTextFieldDidMove()
        
        
    }
	
	func currentTextFieldDidMove() {
//		print("Move")
		if offsetYConstraint != nil, offsetXConstraint != nil, self.sEnv.wrappedValue.selectedTextField.id != UUID(uuid: UUID_NULL) {
			let sl = self.sEnv.wrappedValue.strokes.first(where: {$0.id == self.sEnv.wrappedValue.selectedTextField.id})
			if let sl = sl {
				let _p = sl.points[0].convertTo(scale: trueScale, andOffset: trueOffset)
				
				self.offsetXConstraint.constant = _p.x-self.bounds.width / 2
				self.offsetYConstraint.constant = _p.y-self.bounds.height / 2 - String.BIAS - self.heightConstraint.constant
				
				
			}
		}
		
		if self.widthConstraint != nil, self.heightConstraint != nil {
			let sel = self.sEnv.wrappedValue.selectedTextField.id
			if sel != UUID(uuid: UUID_NULL) {
				
				let textValue = self.sEnv.wrappedValue.strokes.first(where: { $0.id == sel })?.textValue ?? "No"
				
				var textString: NSString = NSString(string: textValue)
				var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont(name: "Avenir", size: 30 * self.trueScale)!], context: nil)
				
				let sz = labelSize.size
				
				self.widthConstraint.constant = sz.width + WIDTHTEXTBIAS * self.trueScale
				self.heightConstraint.constant = sz.height + WIDTHTEXTBIAS * self.trueScale
			}
			
			
		}
		
		
	}
	
	func currentTextFieldWillChange(from old: Stroke, to line: Stroke) {
//        print("Textfield changed")
		
		if self.textFieldViewController != nil {
			self.textFieldViewController.removeFromSuperview()
		}
		
		let textField = SelectedTextFieldView(line: line, scrollEnv: self.sEnv, trueScale: trueScale)
		let vc = UIHostingController(rootView: textField)
		self.textFieldViewController = vc.view
		
		
		
		if line.id != UUID(uuid: UUID_NULL) {
			self.addSubview(textFieldViewController)
			textFieldViewController.translatesAutoresizingMaskIntoConstraints = false
			if self.offsetXConstraint != nil, self.offsetYConstraint != nil {
				self.offsetYConstraint.isActive = false
				self.offsetXConstraint.isActive = false
			}
			
			if self.widthConstraint != nil, self.heightConstraint != nil {
				self.widthConstraint.isActive = false
				self.heightConstraint.isActive = false
			}
			let str = self.sEnv.wrappedValue.selectedTextField.textValue
			var textString: NSString = NSString(string: str)
			var labelSize = textString.boundingRect(with: .init(width: 3000, height: 3000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont(name: "Avenir", size: 30 * self.trueScale)!], context: nil)
			
			let sz = labelSize.size
			
			let _p = line.points[0].convertTo(scale: trueScale, andOffset: trueOffset)
			self.offsetXConstraint = textFieldViewController.leftAnchor.constraint(equalTo: self.centerXAnchor)
			
			
			
			self.offsetXConstraint.isActive = true
			
			
			self.offsetYConstraint = textFieldViewController.topAnchor.constraint(equalTo: self.centerYAnchor)
			self.offsetYConstraint.isActive = true
			
			self.widthConstraint = textFieldViewController.widthAnchor.constraint(equalToConstant: sz.width)
			self.widthConstraint.isActive = true
			
			
			self.heightConstraint = textFieldViewController.heightAnchor.constraint(equalToConstant: sz.height)
			self.heightConstraint.isActive = true
			
		}
	}
    
    func modify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionColor.insert()
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionWidth.insert()
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionPoints.insert()
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, noteOwnerID: note?.noteId ?? UUID(uuid: UUID_NULL))
                    actionText.insert()
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    func whenInRevertedModify(forStroke st: Stroke, ofNoteID noteId: UUID) {
        //        //print("AAA")
        let note = self.notesFetch.first(where: { $0.noteId == noteId })
        if note != nil {
            let strokes = note!.ownedStrokes?.allObjects as? [StrokeData] ?? []
            let str = strokes.first(where: { $0.strokeId == st.id })
            //            //print(str)
            if str != nil {
                let rr = st
                
                
                
                let col = rr.color
                if col.toString() != str!.color {
                    //                    let actionColor = NoteAction(env: self.sEnv, strokeProperty: .color, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.color?.toXColor(), setValueTo: col, str: st, primordialType: .reverted)
                }
                str!.color = col.toString()
                
                
                
                let w = CGFloat(rr.width)
                if Float(w) != str!.width {
                    //                    let actionWidth = NoteAction(env: self.sEnv, strokeProperty: .width, type: .strokeAction, strokeID: str?.strokeId, previousValue: CGFloat(str?.width ?? 0.0), setValueTo: w, str: st, primordialType: .reverted)
                }
                str!.width = Float(w)
                
                
                
                
                let pts = rr.points
                if CGPointArray(pts).toString() != str!.pointSet {
                    //                    let actionPoints = NoteAction(env: self.sEnv, strokeProperty: .points, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.pointSet?.toPointArray().arr, setValueTo: pts, str: st, primordialType: .reverted)
                }
                str!.pointSet = CGPointArray(pts).toString()
                
                
                
                
                let text = rr.textValue
                if text != str!.textValue {
                    //                    let actionText = NoteAction(env: self.sEnv, strokeProperty: .textValue, type: .strokeAction, strokeID: str?.strokeId, previousValue: str!.textValue, setValueTo: text, str: st, primordialType: .reverted)
                }
                str!.textValue = text
                
                
                //                //print("Color: \(str!.color ?? "")")
                try? self.moc.save()
            } else {
                //                //print("STROKE IS NIL")
            }
        }
    }
    
    private var bias: XPoint = .init(x: 100, y: 100)
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>, notesFetch: FetchedResults<NoteData>, moc: NSManagedObjectContext, controller: DrawViewFBFController?) {
        self.moc = moc
        
        self.sEnv = scrollEnv
        self.notesFetch = notesFetch
        self.controller = controller
        super.init(frame: XRect(x: 0, y: 0, width: 200, height: 200))
		NotificationCenter.default.addObserver(forName: .iOSTextFieldTextChanged, object: nil, queue: nil) { notification in
			self.currentTextFieldDidMove()
			self.updateSelf()
		}
		
		NotificationCenter.default.addObserver(forName: .mouseUpInView, object: nil, queue: nil) { notification in
			
			self.didFinishDrawingCurrentLine = true
			if let currDr = self.currentLineDrawingLayer {
				self.caLayerDictionary[currDr] = self.sEnv.wrappedValue.currentStroke.convertToDefault(scale: self.trueScale, offset: self.trueOffset)
			}
			self.currentLineDrawingLayer = nil
		}
		// MARK: Notifications
    }
    var didFinishDrawingCurrentLine = false
	
    override func draw(_ rect: CGRect) {
        super.draw(rect)
		self.drawShit()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func endOfEvents() {}
    
    func updateSelf() {
		
    }
    
}


 

#endif

extension Array where Element == NSRange {
    func toString() -> String {
        var str = ""
        for (n , el) in self.enumerated() {
            str.append("\(el.location)#\(el.length)|")
        }
        _ = str.popLast()
        return str;
    }
}

extension String {
    func toNSRangeArray() -> [NSRange] {
        var rarr = [NSRange]()
        self.split(separator: "|").forEach { a in
            let aa = a.split(separator: "#")
            let numberFormatter = NumberFormatter()
            let number1 = numberFormatter.number(from: String(aa[0]))
            let a0 = number1?.intValue ?? 0
            let number2 = numberFormatter.number(from: String(aa[1]))
            let a1 = number2?.intValue ?? 0
            rarr.append(NSRange(location: a0, length: a1))
            
        }
        return rarr
    }
    
    
    
    
    func textToText(boldSubstring: Character = "{", italicSubstring: Character = "[", underlineSubstring: Character = "<", boldSubstringClose: Character = "}", italicSubstringClose: Character = "]", underlineSubstringClose: Character = ">", withOffset: Bool = true) -> (string: String, italicRanges: [NSRange], boldRanges: [NSRange], underlineRanges: [NSRange], smallRanges: [NSRange]) {
        let arr = Array(self)
        var newArr = [Character]()
        var currentItalicRange = NSRange()
        var currentBoldRange = NSRange()
        var currentUnderlineRange = NSRange()
        
        var boldArr = [NSRange]()
        var italicArr = [NSRange]()
        var underlineArr = [NSRange]()
        var smallArr = [NSRange]()
        
        var devansare = 0
        
        for (n, char) in arr.enumerated() {
            if(n == 0) {
                switch char {
                case boldSubstring:
//                    newArr.append("*")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentBoldRange.location = n - devansare + 1
//                    break
                case italicSubstring:
//                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentItalicRange.location = n - devansare + 1
//                    break
                case underlineSubstring:
                    //                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentUnderlineRange.location = n - devansare + 1
                    //                    break
                case boldSubstringClose:
//                    newArr.append("*")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentBoldRange.length = n - currentBoldRange.location + 1
                    boldArr.append(currentBoldRange)
                    currentBoldRange = .init()
//                    break
                case italicSubstringClose:
//                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentItalicRange.length = n - currentItalicRange.location + 1
                    italicArr.append(currentItalicRange)
                    currentItalicRange = .init()
//                    break
                case underlineSubstringClose:
                    //                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentUnderlineRange.length = n - currentUnderlineRange.location + 1
                    underlineArr.append(currentUnderlineRange)
                    currentUnderlineRange = .init()
                    //                    break
                case "\\":
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    
                default:
                    newArr.append(char)
                }
            } else if (arr[n-1] != "\\") {
                switch char {
                case boldSubstring:
//                    newArr.append("*")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentBoldRange.location = n - devansare + 1
                case italicSubstring:
//                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentItalicRange.location = n - devansare + 1
//                    break
                case underlineSubstring:
                    //                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentUnderlineRange.location = n - devansare + 1
                case boldSubstringClose:
//                    newArr.append("*")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentBoldRange.length = n - (currentBoldRange.location + devansare) + 1
                    boldArr.append(currentBoldRange)
                    currentBoldRange = .init()
//                    break
                case italicSubstringClose:
//                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentItalicRange.length = n - (currentItalicRange.location + devansare) + 1
                    italicArr.append(currentItalicRange)
                    currentItalicRange = .init()
                case underlineSubstringClose:
                    //                    newArr.append("_")
                    devansare += 1
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    currentUnderlineRange.length = n - (currentUnderlineRange.location + devansare) + 1
                    underlineArr.append(currentUnderlineRange)
                    currentUnderlineRange = .init()
//                    break
                case "\\":
                    if !withOffset {
                        devansare = 0
                        newArr.append(char)
                        smallArr.append(NSRange(location: n, length: 1))
                    }
                    devansare += 1
                default:
                    newArr.append(char)
                }
            } else {
                newArr.append(char)
            }
        }
        var s = ""
        for i in newArr {
            s.append("\(i)")
        }
        return (s, italicArr, boldArr, underlineArr, smallArr)
    }
}
extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: rhs * lhs.x, y: rhs * lhs.y)
    }
    
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
}
