//
//  GestureForEditGraph.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 28.04.2022.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import CoreData

struct GestureGraphView: XViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GestureControllerGraph {
        GestureControllerGraph(scrollEnv: self._scrollEnv, notesFetch: self.noteFetch, moc: self.moc)
    }
    
    func updateUIViewController(_ uiViewController: GestureControllerGraph, context: Context) {
        uiViewController.notesFetch = self.noteFetch
    }
    
    typealias UIViewControllerType = GestureControllerGraph
    
    @EnvironmentObject var scrollEnv: ScrollEnv
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: NoteData.entity(), sortDescriptors: []) var noteFetch: FetchedResults<NoteData>
    func makeNSViewController(context: Context) -> GestureControllerGraph {
        GestureControllerGraph(scrollEnv: self._scrollEnv, notesFetch: self.noteFetch, moc: self.moc)
    }
    
    func updateNSViewController(_ nsViewController: GestureControllerGraph, context: Context) {
        nsViewController.notesFetch = self.noteFetch
    }
    
    typealias NSViewControllerType = GestureControllerGraph
}

class GestureControllerGraph: XViewController {
    var moc: NSManagedObjectContext
    
    var notesFetch: FetchedResults<NoteData>
    
    var sEnv: EnvironmentObject<ScrollEnv>
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>, notesFetch: FetchedResults<NoteData>, moc: NSManagedObjectContext) {
        self.moc = moc
        
        self.sEnv = scrollEnv
        self.notesFetch = notesFetch
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = XView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(iOS)
        
        var scrollGesture = UIPanGestureRecognizer()
        scrollGesture.addTarget(self, action: #selector(self.scrollWheel(_:)))
        self.view.addGestureRecognizer(scrollGesture)
        
        var zoomGesture = UIPinchGestureRecognizer()
        zoomGesture.addTarget(self, action: #selector(self.magnify(_:)))
        self.view.addGestureRecognizer(zoomGesture)
        
        #endif
    }

    #if os(macOS)
    override func magnify(with event: XEvent) {
        let zoomBiasa = self.view.convert(event.locationInWindow, from: nil)
        
        let zb = CGPoint(x: 2*(zoomBiasa.x - self.view.frame.width / 2),
                         y: 2*(self.view.frame.height / 2 - zoomBiasa.y))
        
        let go = Math.calculateOffsetGraph(
            fromMouseScale: max(0.5, 1 + event.magnification),
            andOldOffset: CGPoint(x: self.sEnv.wrappedValue.graphOffset.x, y: self.sEnv.wrappedValue.graphOffset.y),
            withMousePosition: zb
        )
        
        if Math.calculateScaleGraph(fromMouseScale: max(0.5, 1 + event.magnification), andOldScale: self.sEnv.wrappedValue.graphScale) >= 1 {
            self.sEnv.wrappedValue.graphOffset = CGPoint(x: go.x, y: go.y)
            
            self.sEnv.wrappedValue.graphScale = Math.calculateScaleGraph(fromMouseScale: max(0.5, 1 + event.magnification), andOldScale: self.sEnv.wrappedValue.graphScale)
        } else {
            self.sEnv.wrappedValue.graphScale = 1
        }
    }
    
    override func scrollWheel(with event: XEvent) {
        self.sEnv.wrappedValue.graphOffset = CGPoint(x: self.sEnv.wrappedValue.graphOffset.x + event.scrollingDeltaX,
                                                     y: self.sEnv.wrappedValue.graphOffset.y + event.scrollingDeltaY)
    }

    #elseif os(iOS)
    
    var oldGraphScale: CGFloat = 1
    var oldOffsetS: CGPoint = .zero
    @objc
    func magnify(_ sender: UIPinchGestureRecognizer) {
        let eventScale = sender.scale
        let zoomBiasa = sender.location(in: self.view)
        
        if sender.state == .began {
            self.oldOffsetS = self.sEnv.wrappedValue.graphOffset
            self.oldGraphScale = self.sEnv.wrappedValue.graphScale
        }
        
        if sender.numberOfTouches == 2 {
            let eventmagnification = sender.scale
        
            let zb = CGPoint(x: 2*(zoomBiasa.x - self.view.frame.width / 2),
                             y: 2*(self.view.frame.height / 2 - zoomBiasa.y))
        
            let go = Math.calculateOffsetGraph(
                fromMouseScale: eventmagnification,
                andOldOffset: self.oldOffsetS,
                withMousePosition: zb
            )
        
            let m = Math.calculateScaleGraph(fromMouseScale: eventmagnification, andOldScale: self.oldGraphScale)
        
            /*
             self.trueScale = Math.calculateScale(fromMouseScale: eventmagnification, andOldScale: self.oldScale)
         
             self.trueOffset = Math.calculateOffset(fromMouseScale: eventmagnification, andOldOffset: self.oldScaleOffset, withMousePosition: self.zoomBias)
             */
        
            if m >= 1 {
                self.sEnv.wrappedValue.graphOffset = CGPoint(x: go.x, y: go.y)
            
                self.sEnv.wrappedValue.graphScale = m
            } else {
                self.sEnv.wrappedValue.graphScale = 1
            }
        }
    }
    
    var oldGraphOffset = CGPoint.zero
    @objc
    func scrollWheel(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.oldGraphOffset = self.sEnv.wrappedValue.graphOffset
        }
        let loc = sender.translation(in: self.view)
        let event = (scrollingDeltaX: loc.x, scrollingDeltaY: loc.y)
        
        self.sEnv.wrappedValue.graphOffset = CGPoint(x: self.oldGraphOffset.x + event.scrollingDeltaX,
                                                     y: self.oldGraphOffset.y + event.scrollingDeltaY)
    }
    #endif
}
