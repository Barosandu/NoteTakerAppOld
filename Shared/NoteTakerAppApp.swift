//
//  NoteTakerAppApp.swift
//  Shared
//
//  Created by Alexandru Ariton on 18.04.2022.
//

import Combine
import SwiftUI

#if os(macOS)
typealias XViewControllerRepresentable = NSViewControllerRepresentable
typealias XViewRepresentable = NSViewRepresentable
typealias XViewController = NSViewController
typealias XView = NSView
typealias XHostingView = NSHostingView
typealias XEvent = NSEvent
typealias XColor = NSColor
typealias XRect = NSRect
typealias XPoint = NSPoint
#elseif os(iOS)
import UIKit
typealias XViewControllerRepresentable = UIViewControllerRepresentable
typealias XViewRepresentable = UIViewRepresentable
typealias XViewController = UIViewController
typealias XView = UIView
typealias XHostingView = UIHostingController
typealias XEvent = UIEvent
typealias XColor = UIColor
typealias XRect = CGRect
typealias XPoint = CGPoint

extension CGColor {
    static let black = CGColor.red
}
#endif

@main
struct NoteTakerAppApp: App {
    
    
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            VStack {
                ContentView()
                    .environmentObject(ScrollEnv(noteName: ""))
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        #if os(macOS)
		.windowToolbarStyle(.unified)
		.windowStyle(.hiddenTitleBar)
        #endif
    }
}




extension Array where Element == Stroke {
    subscript(withId withId: UUID) -> Element {
        get {
            return self.first(where: { $0.id == withId }) ?? Stroke(id: UUID(uuid: UUID_NULL), selected: false)
        }
        
        set(val) {
            let i = self.firstIndex(where: { $0.id == withId })
            if i != nil {
                let ind = i!
                self[ind] = val
            }
        }
    }
}



class ScrollEnv: ObservableObject {
    var strokes: [Stroke]
    var currentStroke: Stroke
    var selectedTextField: Stroke
    @Published var currentNoteId: UUID
    @Published var currentNoteName: String
    @Published var addImageLocation: CGPoint
    var removeFromSuperView: Bool = false
	
    
    @Published var allActions: [NoteAction] {
        didSet {
//            //print("Set")
        }
    }
    
    @Published var updateCol = false
    #if os(iOS)
    func add(iosImage img: UIImage, at l3: CGPoint) {
        self.currentStroke.createdAt = Date()
        self.currentStroke.color = self.selectedColor
        self.currentStroke.width = .init(self.selectedWidth)
        self.currentStroke.typeOfStroke = .image
        self.currentStroke.id = UUID()
        self.currentStroke.imageData = img.pngData()
        self.currentStroke.points = [l3]
        NotificationCenter.default.post(name: .saveImageIOS, object: self.currentStroke)
        self.currentStroke = Stroke(id: UUID(uuid: UUID_NULL), selected: false)
        
    }
    #endif
    
    
    @Published var selectedColorArr: [CGFloat] {
        didSet {
            self.selectedColor = XColor(red: self.selectedColorArr[0], green: self.selectedColorArr[1], blue: self.selectedColorArr[2], alpha: self.selectedColorArr[3])
            for (n, line) in self.strokes.enumerated() {
                if line.selected {
                    self.strokes[n].color = self.selectedColor
                }
            }
        }
    }
    
    @Published var selectedColor: XColor
    @Published var selectedWidth: CGFloat {
        didSet {
            for (n, line) in self.strokes.enumerated() {
                if line.selected {
                    self.strokes[n].width = self.selectedWidth
                }
            }
        }
    }

    @Published var scaleByWidth: Bool
    
    @Published var customSwatches: [XColor]
    
    @Published var selectedTextText: String {
        didSet {
            for (n, line) in self.strokes.enumerated() {
                if line.selected && line.typeOfStroke == .text && self.selectedTextField.id == line.id {
                    let a = self.selectedTextText.textToText()
                    self.strokes[n].textValue = self.selectedTextText
                    
                }
            }
            NotificationCenter.default.post(name: .didChangeSelectedText, object: nil)
        }
    }
    
    func didFinishEditingText() {
        
    }
     
    @Published var showGrid: Bool
    @Published var showGuide: Bool
    
    @Published var toolInUse: ToolInUse
    
    @Published var selectJustOne: Bool 
    
//    var dragOffset: CGSize
    
    
    @Published var editGraph: Bool
    
    
    
    @Published var graphScale: CGFloat
    @Published var graphOffset: CGPoint
    
    @Published var resetScaleAndOffset = false
    
    var selectedRect: CGRect
    
    func selectedLinesCount() -> Int {
        return self.strokes.filter({$0.selected}).count
    }
    func firstSelected() -> Stroke {
        return self.strokes.first(where: {$0.selected}) ?? Stroke(id: UUID(uuid: UUID_NULL), typeOfStroke: .line, selected: false)
        
    }
    
    func beginSelection() {
        
    }
    
    func clearSelection() {
        for (n, s) in self.strokes.enumerated() {
            self.strokes[n].selected = false
        }
    }
    
    @Published var presentIOSPhotoPicker: Bool
    #if os(iOS)
    @Published var addIOSImage: UIImage
    #endif
    init(noteName: String) {
        self.strokes = []
        self.currentStroke = Stroke(id: UUID(uuid: UUID_NULL), selected: false)
        
        self.allActions = []
        self.addImageLocation = .zero
        self.currentNoteId = UUID(uuid: UUID_NULL)
        self.currentNoteName = ""
        self.selectedColor = XColor(red: 0, green: 0.6, blue: 1, alpha: 1)
        self.selectedColorArr = [0, 0.6, 1, 1]
        
        self.selectedWidth = 2
        self.scaleByWidth = true
        self.showGrid = true
        self.showGuide = false
        self.customSwatches = DefaultValues.defaultSwatches
        self.presentIOSPhotoPicker = false
        self.toolInUse = .select
        self.selectedTextText = "Your text goes here..."
        self.selectJustOne = false
        self.editGraph = false
        
        self.graphScale = 3
        self.graphOffset = .zero
        #if os(iOS)
        self.addIOSImage = UIImage()
        #endif
        self.selectedRect = .zero
        self.selectedTextField = Stroke(id: UUID(uuid: UUID_NULL), selected: false)
        
        
    }
}
