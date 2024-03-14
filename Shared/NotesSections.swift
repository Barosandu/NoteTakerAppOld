//
//  NotesSections.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 07.05.2022.
//

import Foundation
import SwiftUI
import Combine

import CoreData

extension Date {
    static func format(date: Date) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "dd.MM',' HH:mm"
        return dateFormater.string(from: date)
    }
}



extension String {
	#if os(iOS)
	func nsAttributedStringForEditingInTextField(scale: CGFloat) -> NSAttributedString {
		let txt = self.textToText(withOffset: false)
		let _string = txt.string
		let boldArr = txt.boldRanges
		let italicArr = txt.italicRanges
		let underlineArr = txt.underlineRanges
		let smallArr = txt.smallRanges
		
		let string = NSMutableAttributedString(string: _string, attributes: [.font: UIFont(name: "Avenir", size: scale * 30), .foregroundColor: UIColor.white])
		
		
		boldArr.forEach { range in
			string.addAttribute(.strokeWidth, value: 7, range: NSRange(location: range.location, length: range.length - 1))
		}
		
		
		italicArr.forEach{ range in
			string.addAttribute(.obliqueness, value: 0.2, range: NSRange(location: range.location, length: range.length - 1))
			
		}
		
		
		
		underlineArr.forEach { range in
			string.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: range.location, length: range.length - 1))
		}
		
		smallArr.forEach { range in
			string.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.5), range: range)
			string.removeAttribute(.underlineStyle, range: range)
			string.removeAttribute(.obliqueness, range: range)
			string.removeAttribute(.strokeWidth, range: range)
		}
		
		
		
		
		return string
	}
	#elseif os(macOS)
	func nsAttributedStringForEditingInTextField(scale: CGFloat) -> NSAttributedString {
		let txt = self.textToText(withOffset: false)
		let _string = txt.string
		let boldArr = txt.boldRanges
		let italicArr = txt.italicRanges
		let underlineArr = txt.underlineRanges
		let smallArr = txt.smallRanges
		
		let string = NSMutableAttributedString(string: _string, attributes: [.font: NSFont(name: "Avenir", size: scale * 30), .foregroundColor: NSColor.white])
		
		
		boldArr.forEach { range in
			string.addAttribute(.strokeWidth, value: 7, range: NSRange(location: range.location, length: range.length - 1))
		}
		
		
		italicArr.forEach{ range in
			string.addAttribute(.obliqueness, value: 0.2, range: NSRange(location: range.location, length: range.length - 1))
			
		}
		
		
		
		underlineArr.forEach { range in
			string.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: range.location, length: range.length - 1))
		}
		
		smallArr.forEach { range in
			string.addAttribute(.foregroundColor, value: NSColor.white.withAlphaComponent(0.5), range: range)
			string.removeAttribute(.underlineStyle, range: range)
			string.removeAttribute(.obliqueness, range: range)
			string.removeAttribute(.strokeWidth, range: range)
		}
		
		
		
		
		return string
	}
	#endif
}

#if os(macOS)
public extension NSView {
    
    func bitmapImage() -> NSImage? {
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

extension View {
    func renderAsImage() -> NSImage? {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return view.bitmapImage()
    }
}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    
    override var safeAreaInsets: NSEdgeInsets {
        return .init()
    }
    
}
#endif

struct ViewForNote: View {
	@EnvironmentObject var scrollEvent: ScrollEnv
	var note: NoteData
	@Binding var renamingNoteID: UUID
	
	var deleteNote: (UUID) -> Void
	
	
	@State var hovered: Bool = false
	var body: some View {
		Button {
			#if os(iOS)
			withAnimation {
				self.scrollEvent.currentNoteId = note.noteId ?? UUID(uuid: UUID_NULL)
				self.scrollEvent.currentNoteName = note.name ?? ""
			}
			#elseif os(macOS)
			self.scrollEvent.currentNoteId = note.noteId ?? UUID(uuid: UUID_NULL)
			self.scrollEvent.currentNoteName = note.name ?? ""
			#endif
			
		} label: {
			Group {
				HStack {
					HStack {
						VStack(alignment: .leading) {
							Text(note.name ?? "No")
								.font(.system(size: 20))
							
							Text("\(Date.format(date: note.savedAt ?? Date()))")
								.font(.system(size: 10))
						}
						Spacer()
					}.padding(7)
						.background((self.scrollEvent.currentNoteId == note.noteId ?
									 Color.blue : (self.hovered == false ? Color.gray.opacity(0.005) : (Color.gray.opacity(0.1)))))
					
						
						
				}
			}
		}
		.buttonStyle(.plain)
		.onHover(perform: { val in
			self.hovered = val
		})
			.contextMenu {
				Button {
					self.deleteNote(note.noteId ?? UUID())
				} label: {
					Label("Delete", systemImage: "trash")
				}
			}
	}
}

struct NotesSectionNav: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NoteSection.name, ascending: true)], animation: .default) private var noteSections: FetchedResults<NoteSection>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NoteData.savedAt, ascending: true)], animation: .default) private var notes: FetchedResults<NoteData>
    @State var addingNote = false
    @State var addingNoteName = ""
    
    @State var addingSection = false
    @State var addingSectionName = ""
    
    @EnvironmentObject var scrollEvent: ScrollEnv
    
    
    func addNote(withName name: String, inSectionWithID sectionID: NSManagedObjectID) {
        let note = NoteData(context: self.moc)
        note.name = self.addingNoteName
        note.savedAt = Date()
        note.noteId = UUID()
        note.ownedBySection = self.noteSections.first(where: { $0.objectID == sectionID })
        self.addingNoteName = ""
        try? self.moc.save()
    }
    
    func addSection(withName name: String) {
        let section = NoteSection(context: self.moc)
        section.name = self.addingSectionName
//        //print(section.name)
        self.addingSectionName = ""
        try? self.moc.save()
    }
    
    func clearAllStrokes(forNoteWithID id: UUID) {
        let note: NoteData? = self.notes.first(where: { $0.noteId == id })
        
        if note != nil {
            self.scrollEvent.strokes = []
            
            for elem in note!.ownedStrokes?.allObjects as! [StrokeData] {
                self.moc.delete(elem)
            }
            
            try? self.moc.save()
        }
    }
    
    func deleteNote(withID id: UUID) {
        let note = self.notes.first(where: { $0.noteId == id })
        
        if note != nil {
            self.clearAllStrokes(forNoteWithID: note!.noteId ?? UUID())
            self.scrollEvent.currentNoteId = UUID()
            self.scrollEvent.currentNoteName = ""
            
            self.moc.delete(note!)
            try? self.moc.save()
        }
    }
    
    func renameNote(withID id: UUID, newName: String) {
        let note = self.notes.first(where: { $0.noteId == id })
        
        if note != nil {
            note!.name = newName
            try? self.moc.save()
        }
    }
    @State var renamingNoteName = ""
    
    @State var selectedSectionName = ""
    @State var selectedSectionID: NSManagedObjectID = .init()
    
    @State var renamingNoteID: UUID = .init(uuid: UUID_NULL)
    var addNoteInputView: some View {
        HStack {
            TextField("Add Me", text: self.$addingNoteName) {
                if self.addingNoteName != "" {
                    self.addNote(withName: self.addingNoteName, inSectionWithID: self.selectedSectionID)
					self.addingNoteName = ""
                }
				self.addingNote = false
            }.textFieldStyle(.roundedBorder)
				.padding(5)
        }
    }
    
    @State var __addSectionOnlyOnce = false
    var addSectionInputView: some View {
        VStack {
            Text("Add Section")
            TextField("Add Section", text: self.$addingSectionName) {
                if self.addingSectionName != "" {
					self.addSection(withName: self.addingSectionName)
					print("Added section!")
                }
				self.addingSection = false
				self.__addSectionOnlyOnce = false
				self.addingSectionName = ""
                
            }.textFieldStyle(.roundedBorder)
            
                .padding([.horizontal, .top])
                
        }
    }
    
    /*
     
     */
    func deleteSection(withId secId: NSManagedObjectID) {
        let s = noteSections.first(where: {$0.objectID == secId})
        if s != nil {
            for n in s!.sectionOwnedNotes?.allObjects as? [NoteData] ?? [] {
                self.moc.delete(n)
            }
            self.moc.delete(s!)
            try? self.moc.save()
        }
    }
	
	func deleteAllSections() {
		let sections = noteSections
		for s in sections {
			for n in s.sectionOwnedNotes?.allObjects as? [NoteData] ?? [] {
				self.moc.delete(n)
			}
			self.moc.delete(s)
			try? self.moc.save()
		}
	}
    
    var body: some View {
        ZStack {
            ScrollView {
                ForEach(self.noteSections, id: \.name) { (sect: NoteSection) in
                     VSection(label: HStack {
                         Text("\(sect.name ?? "nan")")
                             .contextMenu {
                                 Button("Delete whole section") {
                                     self.deleteSection(withId: sect.objectID)
                                 }
                             }
                         Button {
							self.selectedSectionID = sect.objectID
							self.addingNoteName = ""
							 withAnimation {
								 self.addingNote = true
							 }
							
							 
                             
                         } label: {
                             Image(systemName: "plus")
                                 .foregroundColor(.blue)
                                 .padding()
                         }.buttonStyle(.plain)
						 
					 }, restrictWidth: false, spacing: 0) {
						 VStack {
							 Group {
								 if self.addingNote && self.selectedSectionID == sect.objectID {
									 self.addNoteInputView
										 .animation(.easeIn, value: self.addingNote)
										 .transition(.move(edge: .top))
									 
								 }
							 }
							 
							 LazyVStack(spacing: 0) {
								 ForEach((sect.sectionOwnedNotes?.allObjects as? [NoteData] ?? []).sorted(by: {$0.savedAt! > $1.savedAt!})) { note in
									 ViewForNote(scrollEvent: self._scrollEvent, note: note, renamingNoteID: self.$renamingNoteID, deleteNote: self.deleteNote(withID:))
								 }
							 }
							 .clipped()
						 }
                         
                         .background(Color.gray.opacity(0.2))
						 .cornerRadius(10)
                         .padding(.horizontal)
                     }
					 
                     
                 }
				
				Spacer(minLength: 200)
            }
            VStack {
                Spacer()
                ZStack {
                    
                    VStack {
                        Group {
                            if self.addingSection {
                                self.addSectionInputView
									.transition(.slide)
									.animation(.easeIn, value: self.addingSection)
                                    
                            } else {
                                
                                Button {
                                    withAnimation {
                                        self.addingSection = true
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("Add section")
                                            .padding(.horizontal)
                                            .padding(.vertical, 5)
                                        Spacer()
                                    }.background(.blue)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                                .transition(.slide)
                            }
                        }
                        .padding()
                    }.background(
                        Color.clear
                            .background(TranslucentBackground())
                            .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
                            .edgesIgnoringSafeArea(.all)
                    )
					
                    
                }
            }
		}
    }
}
