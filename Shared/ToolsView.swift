//
//  ToolsView.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on SSIZE.04.SSIZE22.
//

import Foundation
import SwiftUI

enum ToolInUse: Int16 {
    case pencil = 1
    case line = 2
    case circle = 3
    case rectangle = 4
    case select = 5
    case text = 6
    case graph = 7
    #if os(iOS)
    case move = 8
    #endif
    case image = 9
}



struct SearchableToolsView: View {
    let arr = ["", "Pencil", "Line", "Circle", "Rectangle", "Text", "Graph", "Select single item", "View graph", "Select multiple items"]
    let brr = ["", "⌘P", "⌘D", "⌘O", "⌘R", "⌘T", "⌘G", "⌘E", "⌘K", "⌘U"]
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                VStack {
                    ForEach(1..<arr.count) { i in
                        HStack {
                            Text("\(brr[i])")
                                .padding()
                            Text("\(arr[i])")
                                .padding()
                            
                            Spacer()
                        }
                            
                        
                    }
                }
                .padding(5)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                
                Spacer()
            }
            Spacer()
        }.frame(maxWidth: 300, maxHeight: 300)
    }
}

extension String {
    static var NONE = "NONE"
}


#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.closure(image)
            }
            
            
            
            
        }
    }
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var closure: (UIImage) -> Void
    
    
    @Environment(\.presentationMode) private var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
}
#endif
final class FileImporter {
    #if os(macOS)
    class func showOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        let response = panel.runModal()
        return response == .OK ? panel.url : nil
    }
    #elseif os(iOS)
    #endif
    
}

struct ToolButton<Content: View>: View {
    var ind: Int
    var action: () -> Void
    var label: () -> Content
    @State var hovered: Bool = false
    
    
    var arr = ["Pencil", "Line", "Circle", "Rectangle", "Text", "Graph", "Select single item", "Select multiple items", "Preview graph", "Add image"]
	
	
	
    var body: some View {
		
        HStack(spacing: 0) {
            Button {
                action()
            } label: {
                label()
                
            }.onHover { val in
                withAnimation(.easeIn(duration: 0.15)) {
                    self.hovered = val
                }
            }
			
            
            .zIndex(9)
            VStack {
                if self.hovered {
                    Text(arr[ind])
                        .padding(10)
						.background(.blue)
						.frame(height: 40)
                        .transition(.move(edge: .leading))
                }
            }.zIndex(7)
				.clipped()
			
        }
		
    }
}

struct ToolsView: View {
    @EnvironmentObject var scrollEvent: ScrollEnv
    var arr = ["Pencil", "Line", "Circle", "Rectangle", "Text", "Graph", "Select single item", "Select multiple items", "Preview graph", "Add Image", "Move"]
    
    var SSIZE: CGFloat = 15
    var HHEIGHT: CGFloat = 40
    var CHSAPE = Rectangle()
    
    
    
    init() {
        
    }
    
    @State var str = ""
    
    
    @State var hoveringButton: String = ""
    
    
    @State var showPopup = false
    
    var hoveringView: some View {
        VStack {
            if self.hoveringButton != .NONE {
                VStack {
                    Text("\(self.hoveringButton)")
                }
            } else {
                Color.black.opacity(0.01)
            }
        }
    }
	@State var geoOfTools: (width: CGFloat, height: CGFloat) = (0,0)
	var body: some View {
		ZStack(alignment: .leading) {
			Spacer().background(alignment: .leading) {
				TranslucentBackground().frame(width: 40)
					.cornerRadius(10)
			}
				HStack {
					VStack(alignment: .leading) {
						VStack(alignment: .leading) {
							ToolButton(ind: 0) {
								self.scrollEvent.toolInUse = .pencil
							} label: {
								Image(systemName: "pencil.and.outline")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .pencil {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("p", modifiers: .command)
							
							ToolButton(ind: 1) {
								self.scrollEvent.toolInUse = .line
							} label: {
								Image(systemName: "line.diagonal")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .line {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("d", modifiers: .command)
							
							ToolButton(ind: 2) {
								self.scrollEvent.toolInUse = .circle
							} label: {
								Image(systemName: "circle")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .circle {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("o", modifiers: .command)
							
							ToolButton(ind: 3) {
								self.scrollEvent.toolInUse = .rectangle
							} label: {
								Image(systemName: "square")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .rectangle {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("r", modifiers: .command)
							
							ToolButton(ind: 4) {
								self.scrollEvent.toolInUse = .text
								self.scrollEvent.selectedTextText = "Your text goes here..."
							} label: {
								Image(systemName: "character.cursor.ibeam")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .text {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("t", modifiers: .command)
							
							ToolButton(ind: 5) {
								self.scrollEvent.toolInUse = .graph
							} label: {
								Image(systemName: "function")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .graph {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
							.keyboardShortcut("g", modifiers: .command)
							
							
							
							ToolButton(ind: 9) {
								self.scrollEvent.toolInUse = .image
							} label: {
								Image(systemName: "photo")
									.font(.system(size: SSIZE, weight: .bold))
									.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//									.padding(2)
									.background(
										Group {
											if self.scrollEvent.toolInUse == .image {
												Color.blue
											} else {
												Color.black.opacity(0.01)
											}
										}.clipShape(CHSAPE)
									)
							}
							.buttonStyle(.plain)
						}
						
#if os(iOS)
						ToolButton(ind: 10) {
							self.scrollEvent.toolInUse = .move
						} label: {
							Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
								.font(.system(size: SSIZE, weight: .bold))
								.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//								.padding(2)
								.background(
									Group {
										if self.scrollEvent.toolInUse == .move {
											Color.blue
										} else {
											Color.black.opacity(0.01)
										}
									}.clipShape(CHSAPE)
								)
						}
						.buttonStyle(.plain)
#endif
						
						
						ToolButton(ind: 6) {
							self.scrollEvent.toolInUse = .select
							self.scrollEvent.editGraph = false
							self.scrollEvent.selectJustOne = true
						} label: {
							Image(systemName: "cursorarrow")
								.font(.system(size: SSIZE, weight: .bold))
								.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//								.padding(2)
								.background(
									Group {
										if self.scrollEvent.toolInUse == .select && !self.scrollEvent.editGraph && self.scrollEvent.selectJustOne {
											Color.blue
										} else {
											Color.black.opacity(0.01)
										}
									}.clipShape(CHSAPE)
								)
						}
						.buttonStyle(.plain)
						.keyboardShortcut("e", modifiers: .command)
						
						ToolButton(ind: 7) {
							self.scrollEvent.toolInUse = .select
							self.scrollEvent.editGraph = false
							self.scrollEvent.selectJustOne = false
						} label: {
							Image(systemName: "selection.pin.in.out")
								.font(.system(size: SSIZE, weight: .bold))
								.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//								.padding(2)
								.background(
									Group {
										if self.scrollEvent.toolInUse == .select && !self.scrollEvent.editGraph && !self.scrollEvent.selectJustOne {
											Color.blue
										} else {
											Color.black.opacity(0.01)
										}
									}.clipShape(CHSAPE)
								)
						}
						.buttonStyle(.plain)
						.keyboardShortcut("u", modifiers: .command)
						
						ToolButton(ind: 8) {
							self.scrollEvent.toolInUse = .select
							self.scrollEvent.editGraph = true
							self.scrollEvent.selectJustOne = true
						} label: {
							Image(systemName: "perspective")
								.font(.system(size: SSIZE, weight: .bold))
								.frame(width: HHEIGHT, height: HHEIGHT, alignment: .center)
//								.padding(2)
								.background(
									Group {
										if self.scrollEvent.toolInUse == .select && self.scrollEvent.editGraph && self.scrollEvent.selectJustOne {
											Color.blue
										} else {
											Color.black.opacity(0.01)
										}
									}.clipShape(CHSAPE)
								)
						}
						.buttonStyle(.plain)
						.disabled(!self.scrollEvent.selectJustOne)
						.keyboardShortcut("k", modifiers: .command)
						
						
					}
				}
				
				
		}
		.cornerRadius(10)
		.padding(10)
    }
}

extension Float {
    func isValid() -> Bool {
        if self.isInfinite || self.isNaN {
            return false
        }
        return true
    }
}

struct ToolbarButton: ViewModifier {
    @State var ishovered = false
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .padding([.vertical], 9)
            .padding([.horizontal], 7)
            .contentShape(Rectangle(), eoFill: false)
            .onHover { v in
                withAnimation(.easeIn) {
                    self.ishovered = v
                }
            }
            .background (
                Group {
                    if self.ishovered {
                        HighlightedBackground()
                            .cornerRadius(5)
                    } else {
                        Color.black.opacity(0.01)
                    }
                }
            )
            .padding(.horizontal, 10)
    }
}

struct ToolbarButtonRED: ViewModifier {
    @State var ishovered = false
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .padding([.vertical], 9)
            .padding([.horizontal], 7)
            .contentShape(Rectangle(), eoFill: false)
            .onHover { v in
                withAnimation(.easeIn) {
                    self.ishovered = v
                }
            }
            .background (
                Group {
                    if self.ishovered {
                        Color.red.cornerRadius(5)
                    } else {
                        Color.red.cornerRadius(5)
                    }
                }
            )
            .padding(.horizontal, 10)
    }
}

struct TextBUIButton: ViewModifier {
    @State var ishovered = false
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .padding([.vertical], 9)
            .padding([.horizontal], 7)
            .contentShape(Rectangle(), eoFill: false)
            .onHover { v in
                
                self.ishovered = v
                
            }
            .background (
                Group {
                    if self.ishovered {
                        HighlightedBackground()
                            .cornerRadius(5)
                    } else {
                        Color.black.opacity(0.01)
                    }
                }
            )
            .padding(.horizontal, 10)
    }
}
