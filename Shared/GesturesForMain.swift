//
//  GesturesForMain.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 28.04.2022.
//

import Foundation
import CoreData
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI
#if os(macOS)

struct _MyView: XViewRepresentable {
    func makeUIView(context: Context) -> DrawViewFBF {
        let alef = DrawViewFBF(scrollEnv: self._scrollEnv, notesFetch: self.noteFetch, moc: self.moc)
        return alef
    }
    
    func updateUIView(_ uiView: DrawViewFBF, context: Context) {
        uiView.notesFetch = self.noteFetch
        uiView.setNeedsDisplay(uiView.bounds)
    }
    
    typealias UIViewType = DrawViewFBF
    
    
    func makeNSView(context: Context) -> DrawViewFBF {
        let alef = DrawViewFBF(scrollEnv: self._scrollEnv, notesFetch: self.noteFetch, moc: self.moc)
        return alef
    }
    
    func updateNSView(_ nsView: DrawViewFBF, context: Context) {
        nsView.notesFetch = self.noteFetch
        nsView.setNeedsDisplay(nsView.bounds)
    }
    
    typealias NSViewType = DrawViewFBF
    
    @EnvironmentObject var scrollEnv: ScrollEnv
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: NoteData.entity(), sortDescriptors: []) var noteFetch: FetchedResults<NoteData>
    
    
}
#elseif os(iOS)
import UIKit
struct _MyView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DrawViewFBFController {
        let alef = DrawViewFBFController(moc: self.moc, notesFetch: self.noteFetch, sEnv: self._scrollEnv)
        return alef
        
    }
    
    func updateUIViewController(_ uiViewController: DrawViewFBFController, context: Context) {
        uiViewController.view.setNeedsDisplay()
        uiViewController.drawRestOfLinesView.notesFetch = self.noteFetch
    }
    
    typealias UIViewControllerType = DrawViewFBFController
    
    
    
    
    @EnvironmentObject var scrollEnv: ScrollEnv
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: NoteData.entity(), sortDescriptors: []) var noteFetch: FetchedResults<NoteData>
    
    
}
#endif

