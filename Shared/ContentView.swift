import Combine
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NoteData.savedAt, ascending: true)], animation: .default) private var notes: FetchedResults<NoteData>
	
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MarcajeData.savedAt, ascending: true)], animation: .default) private var marcaje: FetchedResults<MarcajeData>
    
    @FetchRequest(entity: StrokeData.entity(), sortDescriptors: []) private var strokeData: FetchedResults<StrokeData>
    
    @State var addName = ""
    
    @EnvironmentObject var scrollEvent: ScrollEnv
    
    var rgbaView: some View {
        VStack {
            CustomSlider(value: self.$scrollEvent.selectedColorArr[0], lowerBound: 0, upperBound: 1) {
                LinearGradient(colors: [Color(self.scrollEvent.selectedColor.with(red: 0)),
                                        Color(self.scrollEvent.selectedColor.with(red: 1))],
                               startPoint: .leading,
                               endPoint: .trailing)
            }.labelled {
                Text("R: ")
            }
            CustomSlider(value: self.$scrollEvent.selectedColorArr[1], lowerBound: 0, upperBound: 1) {
                LinearGradient(colors: [Color(self.scrollEvent.selectedColor.with(green: 0)),
                                        Color(self.scrollEvent.selectedColor.with(green: 1))],
                               startPoint: .leading,
                               endPoint: .trailing)
            }.labelled {
                Text("G: ")
            }
            CustomSlider(value: self.$scrollEvent.selectedColorArr[2], lowerBound: 0, upperBound: 1) {
                LinearGradient(colors: [Color(self.scrollEvent.selectedColor.with(blue: 0)),
                                        Color(self.scrollEvent.selectedColor.with(blue: 1))],
                               startPoint: .leading,
                               endPoint: .trailing)
            }.labelled {
                Text("B: ")
            }
            CustomSlider(value: self.$scrollEvent.selectedColorArr[3], lowerBound: 0, upperBound: 1) {
                LinearGradient(colors: [Color(self.scrollEvent.selectedColor.with(alpha: 0)),
                                        Color(self.scrollEvent.selectedColor.with(alpha: 1))],
                               startPoint: .leading,
                               endPoint: .trailing)
            }.labelled {
                Text("A: ")
            }
        }
        .padding(5)
        .background(HighlightedBackground(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    var swatchesView: some View {
        VStack {
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 30, maximum: 40))]) {
                    ForEach(self.scrollEvent.customSwatches) { cl in
                        ZStack {
                            Color(cl)
                            if self.scrollEvent.selectedColorArr == [cl.getComponents().red, cl.getComponents().green, cl.getComponents().blue, cl.getComponents().alpha] {
                                Color.black
                                    .opacity(0.5)
                                Image(systemName: "checkmark")
                            }
                        }
                        .frame(width: 20, height: 20, alignment: .center)
                        .clipShape(Circle())
                        .onTapGesture {
                            let color = cl
                            //                                    //print(color)
                                
                            self.scrollEvent.selectedColor = color
                            self.scrollEvent.selectedColorArr = [color.getComponents().red, color.getComponents().green, color.getComponents().blue, color.getComponents().alpha]
                        }
                    }
                }
                
                Button {
                    self.scrollEvent.customSwatches = DefaultValues.defaultSwatches
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset swatches")
                        Spacer()
                    }
                    .padding(5)
                    .background(HighlightedBackground(cornerRadius: 10))
                }.buttonStyle(.plain)
            }
            .padding(5)
            .background(HighlightedBackground(cornerRadius: 10))
            .padding(.horizontal)
        }
    }
    
    @State var writtenWidth = "1.0"
    
    var selectWidthView: some View {
        VStack {
//            TextField("w", value: self.$scrollEvent.selectedWidth, formatter: formatter)
//                        .frame(width: 50)
//                        .textFieldStyle(.roundedBorder)

            CustomSlider(value: self.$scrollEvent.selectedWidth, lowerBound: 1, upperBound: 5) {
                Color.blue
            }
            
            CustomToggle(value: self.$scrollEvent.scaleByWidth) {
                Text("Scale width")
            }
        }.padding(5)
            .background(HighlightedBackground(cornerRadius: 10))
            .padding(.horizontal)
    }
    
    @State var showSwatches = false
    
    func restoreText() {
        if self.scrollEvent.selectedLinesCount() >= 1 {
            let st = self.scrollEvent.firstSelected()
            
            self.scrollEvent.selectedTextText = st.textValue
        }
    }
    
    var scaleView: some View {
        VStack {
            CustomToggle(value: self.$scrollEvent.showGrid) {
                Text("Show grid")
            }
            
            CustomToggle(value: self.$scrollEvent.showGuide) {
                Text("Show origin guide")
            }
            Button {
                self.scrollEvent.resetScaleAndOffset = true
                NotificationCenter.default.post(name: .didResetTransform, object: nil)
            } label: {
                HStack {
                    Spacer()
                    Text("Reset transform")
                    Spacer()
                }
                .padding(5)
                .background(HighlightedBackground(cornerRadius: 10))
            }.buttonStyle(.plain)
            
        }.padding(5)
            .background(HighlightedBackground(cornerRadius: 10))
            .padding(.horizontal)
    }
    
    @State var txt = "Hello"
    
    var colorControlView: some View {
        VStack {
            Spacer(minLength: 50)
            
            VSection(label: HStack {
                Text("Color")
                    
                Color(self.scrollEvent.selectedColor).frame(width: 40, height: 20, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }) {
                VStack {
                    HStack {
                        Button {
                            withAnimation {
                                self.showSwatches = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Swatches")
                                Spacer()
                            }
                            .padding(5)
                            .background(
                                Group {
                                    if self.showSwatches {
                                        Color.blue
                                    } else {
                                        HighlightedBackground()
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        Button {
                            withAnimation {
                                self.showSwatches = false
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("RGBA")
                                Spacer()
                            }
                            .padding(5)
                            .background(
                                Group {
                                    if !self.showSwatches {
                                        Color.blue
                                    } else {
                                        HighlightedBackground()
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    if self.showSwatches {
                        self.swatchesView
                            .transition(.slide)
                    } else {
                        self.rgbaView
                            .transition(.slide)
                    }
                }
            }
            
            VSection(label: HStack {
                Text("Width")
                Text(String(format: "%.2f", self.scrollEvent.selectedWidth))
            }) {
                self.selectWidthView
            }
            
            VSection(label: HStack {
                Text("View")
            }) {
                self.scaleView
            }
            
#if os(macOS)

            
            VSection(label: HStack {
                Text("Text")
            }) {
                VStack {
                    HStack(spacing: 10) {
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "{}")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "bold")
                                
                                Spacer()
                            }.modifier(ToolbarButton())
                        }
                        .buttonStyle(.plain)
                        
                        
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "[]")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "italic")
                                
                                Spacer()
                            }.modifier(ToolbarButton())
                        }.buttonStyle(.plain)
                        
                        
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "<>")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "underline")
                                Spacer()
                            }
                            .modifier(ToolbarButton())
                        }.buttonStyle(.plain)
                        
                    }
                    
                    HStack(spacing: 10) {
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "}{")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "bold")
                                
                                Spacer()
                            }.modifier(ToolbarButtonRED())
                        }
                        .buttonStyle(.plain)
                        
                        
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "][")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "italic")
                                
                                Spacer()
                            }.modifier(ToolbarButtonRED())
                        }.buttonStyle(.plain)
                        
                        
                        Button {
                            NotificationCenter.default.post(name: .encircleSelectionWithCaracters, object: "><")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "underline")
                                Spacer()
                            }
                            .modifier(ToolbarButtonRED())
                        }.buttonStyle(.plain)
                        
                    }
                }
                .padding(5)
                .background(HighlightedBackground(cornerRadius: 10))
                .padding(.horizontal)
            }
            
#endif
            
            if self.scrollEvent.toolInUse == .graph {
                VSection(label: HStack {
                    Text("Graph")
                }) {
                    VStack {
                        TextEditor(text: self.$scrollEvent.selectedTextText)
                            .cornerRadius(10)
                            .frame(minHeight: 100)
                            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 7))
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    }
                    .padding(5)
                    .background(HighlightedBackground(cornerRadius: 10))
                    .padding(.horizontal)
                }
            }
            
        }
    }
    
    @State var showActionHistory = false
    
    var actionHistoryView: some View {
        ActionsView()
    }
    
    func deleteSelectedLines() {
        let lines = self.notes.first(where: { $0.noteId == self.scrollEvent.currentNoteId })?.ownedStrokes?.allObjects as? [StrokeData] ?? []
        
        let selectedLines = lines.filter { st in
            self.scrollEvent.strokes[withId: st.strokeId ?? UUID()].selected == true
        }
        self.scrollEvent.strokes = self.scrollEvent.strokes.filter { st in
            st.selected == false
        }
//        //print(selectedLines.map({$0.strokeId}))
        
        for str in selectedLines {
            self.moc.delete(str)
//            //print("Del")
        }
        try? self.moc.save()
    }
    
    func bringSelectedLinesToFront() {
        self.scrollEvent.strokes = self.scrollEvent.strokes.map { st in
            if st.selected {
                var r = st
                r.createdAt = Date()
                return r
            } else {
                return st
            }
        }.sorted(by: { s1, s2 in
            s1.createdAt < s2.createdAt
        })
        
        let lines = self.notes.first(where: { $0.noteId == self.scrollEvent.currentNoteId })?.ownedStrokes?.allObjects as? [StrokeData] ?? []
        let selectedLines = lines.filter { st in
            self.scrollEvent.strokes[withId: st.strokeId ?? UUID()].selected == true
        }
        
        for str in selectedLines {
            str.createdAt = Date()
        }
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
    
    var controlsView: some View {
        GeometryReader { g in
            VStack {
                ScrollView(showsIndicators: false) {
                    self.colorControlView
                    #if os(iOS)
                    Spacer(minLength: 300)
                    #endif
                    Spacer()
                }
            }
            #if os(macOS)
            .frame(minWidth: 250, maxWidth: 250, minHeight: 400)
            #elseif os(iOS)
            .frame(width: g.size.width, height: 400)
            #endif
        }
        .background(TranslucentBackground())
        
        .edgesIgnoringSafeArea(.all)
    }
    
    @State var showControlsView = true
	@State var showControlsWhole = true
	@State var showPinsView = false
    
    @State var drawView = DrawView()
    
    @ViewBuilder var __controls: some View {
        if self.showControlsView {
            VStack {
                ZStack {
                    ZStack {
                        VStack {
							if self.showControlsWhole {
                                self.controlsView
                                    .transition(.slide)
                                
                            } else if self.showActionHistory {
                                self.actionHistoryView
                                    .transition(.slide)
							} else if self.showPinsView {
								self.marcajeView
									.transition(.slide)
							}
                        }.edgesIgnoringSafeArea(.all)
                    }
#if os(macOS)
                    .frame(minWidth: 250, maxWidth: 250, minHeight: 400)
                    //                                    #elseif os(iOS)
                    
#endif
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Button {
                                withAnimation {
                                    self.showActionHistory = true
									self.showControlsWhole = false
									self.showPinsView = false
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.uturn.backward")
                                    Spacer()
                                }
                                .padding(5)
                                .background(
                                    Group {
                                        if self.showActionHistory != false {
                                            Color.blue
                                        } else {
                                            HighlightedBackground()
                                        }
                                    }
                                )
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
							
							Button {
								withAnimation {
									self.showPinsView = true
									self.showActionHistory = false
									self.showControlsWhole = false
								}
							} label: {
								HStack {
									Spacer()
									Image(systemName: "pin.fill")
									Spacer()
								}
								.padding(5)
								.background(
									Group {
										if self.showPinsView != false {
											Color.blue
										} else {
											HighlightedBackground()
										}
									}
								)
								.cornerRadius(10)
							}
							.buttonStyle(.plain)
                            
                            Button {
                                withAnimation {
                                    self.showActionHistory = false
									self.showControlsWhole = true
									self.showPinsView = false
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "slider.horizontal.3")
                                    Spacer()
                                }
                                .padding(5)
                                .background(
                                    Group {
                                        if self.showControlsWhole == true {
                                            Color.blue
                                        } else {
                                            HighlightedBackground()
                                        }
                                    }
                                )
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        
                        .background(
                            TranslucentBackground().edgesIgnoringSafeArea(.all)
                        )
#if os(macOS)
                        .frame(width: 250)
#endif
                        .edgesIgnoringSafeArea([])
                        
                    }.edgesIgnoringSafeArea([]).edgesIgnoringSafeArea([])
                }
            }
#if os(iOS)
            .frame(height: 400)
#endif
         
            .transition(.move(edge: .trailing))
        }
    }
    
    var drawAndControlsViews: some View {
        VStack {
            ZStack {
                ZStack {
                    self.drawView
                        .edgesIgnoringSafeArea(.top)
                }
                #if os(macOS)
                .contextMenu {
                    Button {
                        self.clearAllStrokes(forNoteWithID: self.scrollEvent.currentNoteId)
                    } label: {
                        Label("Clear all", systemImage: "trash")
                    }
                    Menu {
                        Section {
                            Button {
                                self.deleteSelectedLines()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                self.bringSelectedLinesToFront()
                            } label: {
                                Label("Bring to front", systemImage: "trash")
                            }
                        }
                    } label: {
                        Label("Selection...", systemImage: "cursorarrow")
                    }
                }
                #endif
                GeometryReader { gg in
                ZStack {
                    HStack {
                        ToolsView()
						#if os(iOS)
							.padding(.leading, self.horizontalSizeClass == .regular ? 250 : 0)
						#endif
                        Spacer()
                    }
                    
                    #if os(iOS)
                    VStack {
                        Spacer()
                        HStack {
                        Spacer()
                            self.__controls
                                .frame(width: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(5)
							
                        }
                    }
                    
                    #elseif os(macOS)
                    HStack {
                        Spacer()
                        self.__controls
                    }
                    #endif
                    
                }.frame(width: gg.size.width, height: gg.size.height, alignment: .center)
                }
                
                .edgesIgnoringSafeArea([])
                
                VStack {
                    ZStack {
                        Color.clear
                            .background(TranslucentBackground())
                        #if os(macOS)
                            .mask(LinearGradient(colors: [.clear, .black], startPoint: .bottom, endPoint: .top))
                        #endif
                        #if os(iOS)
                        .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
                        .edgesIgnoringSafeArea(.all)
                        #endif
                        VStack {
                            HStack {
                                
                                
                                
                                #if os(iOS)
                                Button {
                                    withAnimation {
                                        self.scrollEvent.currentNoteId = UUID(uuid: UUID_NULL)
                                    }
                                    self.scrollEvent.currentNoteName = ""
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color.blue.clipShape(Circle()))
                                }
                                #endif
                                Text(self.scrollEvent.currentNoteName)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                
                                Spacer()
                                
                                #if os(iOS)
                                Menu {
                                    Section {
                                        Button {
                                            self.deleteSelectedLines()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            self.bringSelectedLinesToFront()
                                        } label: {
                                            Label("Bring to front", systemImage: "arrow.right")
                                        }
                                    }
                                } label: {
                                    Text("Selection")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color.blue.clipShape(Capsule()))
                                }.buttonStyle(.plain)
                                #endif
                                
                                Button {
                                    withAnimation {
                                        self.showControlsView.toggle()
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .modifier(ToolbarButton())
                                }.buttonStyle(.plain)
                                
                                
                                #if os(iOS)
                                    .background(.thinMaterial, in: Rectangle())
                                    .clipShape(Circle())
                                #endif
                            }
                            
                            .padding(.leading)
                        }
                    }.frame(height: 40, alignment: .center)
                    Spacer()
                }
                #if os(macOS)
                .edgesIgnoringSafeArea(.all)
                #endif
            }
        }
    }
    
    var editGraphView: some View {
        VStack {
            ZStack {
                VStack {
                    ZStack {
                        EditGraphView()
                            
                        GestureGraphView()
                        //                        Text("Hwllo")
                    }.edgesIgnoringSafeArea(.top)
                }
                VStack(alignment: .leading) {
                    HStack {
                        #if os(macOS)
                        HStack(alignment: .center) {
                            Text("View graph")
                                .font(.title)
                            Text("BETA")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding([.vertical], 2)
                                .padding([.horizontal], 5)
                                .clipped()
                                .background(Color.white.edgesIgnoringSafeArea([]))
                                .clipShape(Capsule())
                            Divider().padding(5)
                                .frame(height: 40)
                            Text("\(self.scrollEvent.firstSelected().textValue)")
                                .font(.title)
                            Divider().padding(5)
                                .frame(height: 40)
                            Button {
                                self.scrollEvent.editGraph = false
                                self.scrollEvent.clearSelection()
                            } label: {
                                HStack {
                                    Text("Done")
                                }
                                .padding(5)
                                .background(Color.blue.edgesIgnoringSafeArea([]))
                                .cornerRadius(10)
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .padding([.top, .horizontal])
                        Spacer()
                        #elseif os(iOS)
                        HStack(alignment: .center) {
                            Text("View graph")
                                .font(.system(size: 15))
                            Text("BETA")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .font(.system(size: 10))
                                .padding([.vertical], 1)
                                .padding([.horizontal], 3)
                                .clipped()
                                .background(Color.white.edgesIgnoringSafeArea([]))
                                .clipShape(Capsule())
                            Divider().padding(5)
                                .frame(height: 40)
                            Text("\(self.scrollEvent.firstSelected().textValue)")
                                .font(.system(size: 15))
                            Divider().padding(5)
                                .frame(height: 40)
                            Button {
                                self.scrollEvent.editGraph = false
                                self.scrollEvent.clearSelection()
                            } label: {
                                HStack {
                                    Text("Done")
                                }
                                .padding(5)
                                .background(Color.blue.edgesIgnoringSafeArea([]))
                                .cornerRadius(10)
                            }.buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .padding([.top, .horizontal])
                        Spacer()
                        #endif
                    }
                    
                    Spacer()
                }
            }
        }
        #if os(macOS)
        .edgesIgnoringSafeArea(.all)
        #elseif os(iOS)
        .edgesIgnoringSafeArea(.bottom)
        #endif
    }
    
    func togglee() {
        self.showActionHistory = false
        self.showActionHistory = true
    }
	
	@State var marcajToAdd = ""
	
	var marcajeView: some View {
		GeometryReader { g in
			VStack {
				ScrollView(showsIndicators: false) {
					Spacer(minLength: 50)
					VSection(label:
								HStack {
						Text("Pins")
						VStack {
							TextField("Add new pin", text: self.$marcajToAdd) {
								if(self.marcajToAdd != "") {
									NotificationCenter.default.post(name: .getOffsetAndScale, object: nil)
									let pin = MarcajeData(context: self.moc)
									pin.savedAt = Date.now
									pin.x = Float(GetOffsetAndScale.offsetX)
									pin.y = Float(GetOffsetAndScale.offsetY)
									pin.scale = Float(GetOffsetAndScale.scale)
									pin.nume = self.marcajToAdd
									self.marcajToAdd = ""
									pin.ownedByNote = self.notes.first(where: {$0.noteId == self.scrollEvent.currentNoteId})
									try! self.moc.save()
								}
							}
							.font(.system(size: 15))
							.textFieldStyle(.roundedBorder)
						}
					}
					) {
						LazyVStack {
							
							
							LazyVStack {
								ForEach(marcaje) { (marcaj: MarcajeData) in
									if marcaj.ownedByNote?.noteId == self.scrollEvent.currentNoteId {
										Button {
											SetOffsetAndScale.offsetX = CGFloat(marcaj.x)
											SetOffsetAndScale.offsetY = CGFloat(marcaj.y)
											SetOffsetAndScale.scale = CGFloat(marcaj.scale)
											NotificationCenter.default.post(name: .setOffsetAndScale, object: nil)
										} label: {
											MarcajView(marcaj: marcaj)
										}.buttonStyle(.plain)
									}
								}
								
							}.background(Color.gray.opacity(0.2))
								.cornerRadius(10)
								.padding(.horizontal)
						}
					}
					#if os(iOS)
					Spacer(minLength: 300)
					#endif
					Spacer()
				}
			}
			#if os(macOS)
			.frame(minWidth: 250, maxWidth: 250, minHeight: 400)
			#elseif os(iOS)
			.frame(width: g.size.width, height: 400)
			#endif
		}
		.background(TranslucentBackground())
	}
    
    var noteView: some View {
        VStack {
            Group {
                if self.scrollEvent.currentNoteName == "" {
                    VStack {
                        #if os(iOS)
                        Spacer()
                        #endif
                        HStack {
                            #if os(iOS)
                            Spacer()
                            #endif
                            
                            Image("NotesIc")
                                .resizable()
                                .frame(width: 100, height: 100, alignment: .center)
                            Text("Welcome!")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                            
                            #if os(iOS)
                            Spacer()
                            #endif
                        }
                        Text("Create a note to start!")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .opacity(0.7)
                        Image("PlusButton")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300, alignment: .center)
                            .cornerRadius(30)
                            .shadow(radius: 40)
                        
                        #if os(iOS)
                        Spacer()
                        #endif
                    }
                    #if os(macOS)
                    .frame(minWidth: 500, minHeight: 500)
                    #endif
                    #if os(iOS)
                    .background(Color(.systemGray6))
                    #endif
                } else if self.scrollEvent.firstSelected().typeOfStroke == .graph && self.scrollEvent.editGraph && self.scrollEvent.toolInUse == .select {
                    self.editGraphView
                    
                } else {
                    self.drawAndControlsViews
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 500, alignment: .center)
        #endif
        .onAppear {
            NotificationCenter.default.addObserver(forName: .updateActionViewAction, object: nil, queue: nil) { _ in
                togglee()
            }
        }
        .navigationTitle(self.scrollEvent.currentNoteName)
    }

    #if os(macOS)
    var body: some View {
        NavigationView {
            ZStack {
                NotesSectionNav()
            }
            self.noteView
        }
        
        .onChange(of: self.scrollEvent.currentNoteId) { newValue in
            let currentNote = self.notes.first(where: { $0.noteId == newValue })
            let ownedStrokeData = currentNote?.ownedStrokes?.allObjects as? [StrokeData] ?? []

            let convertedStrokeData = ownedStrokeData.map { sd in
                
                Stroke(points: sd.pointSet?.toPointArray().arr ?? [], color: sd.color?.toXColor() ?? .red, width: CGFloat(sd.width), originalScale: 1, id: sd.strokeId ?? UUID(), createdAt: sd.createdAt ?? Date(), typeOfStroke: ToolInUse(rawValue: sd.typeOfStroke) ?? .line, textValue: sd.textValue ?? "", imageData: sd.imageData, skipIndexes: sd.skipIndexes?.toIntArray() ?? [], selected: false, boldArr: sd.boldArray?.toNSRangeArray() ?? [], italicArr: sd.italicArray?.toNSRangeArray() ?? [])
            }
            
            self.scrollEvent.removeFromSuperView = true
            self.scrollEvent.strokes = convertedStrokeData.sorted(by: { $0.createdAt < $1.createdAt })
            
            NotificationCenter.default.post(name: .didChangeNote, object: nil)
//            //print("CHANG")
        }
    }
    
    #elseif os(iOS)
    
    var iphoneView: some View {
        VStack {
            if self.scrollEvent.currentNoteId == UUID(uuid: UUID_NULL) {
                VStack {
                    NotesSectionNav()
                }.transition(.slide)
            } else {
                VStack {
                    self.noteView
                }.transition(.slide)
            }
        }
    }
    
    var ipadView: some View {
		ZStack {
			
            
            VStack {
                self.noteView
            }.transition(.slide)
			
			HStack {
				VStack {
					NotesSectionNav()
				}.frame(width: 250, alignment: .center)
					.background(.thinMaterial)
					.zIndex(99999999)
				Spacer()
			}
        }
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var body: some View {
        VStack {
            if self.horizontalSizeClass == .compact {
                self.iphoneView
            } else {
                self.ipadView
            }
        }
        .onChange(of: self.scrollEvent.currentNoteId) { newValue in
            let currentNote = self.notes.first(where: { $0.noteId == newValue })
            let ownedStrokeData = currentNote?.ownedStrokes?.allObjects as? [StrokeData] ?? []
            
            let convertedStrokeData = ownedStrokeData.map { sd in
                
                Stroke(points: sd.pointSet?.toPointArray().arr ?? [], color: sd.color?.toXColor() ?? .red, width: CGFloat(sd.width), originalScale: 1, id: sd.strokeId ?? UUID(), createdAt: sd.createdAt ?? Date(), typeOfStroke: ToolInUse(rawValue: sd.typeOfStroke) ?? .line, textValue: sd.textValue ?? "", imageData: sd.imageData, skipIndexes: sd.skipIndexes?.toIntArray() ?? [], selected: false)
            }
            self.scrollEvent.strokes = convertedStrokeData.sorted(by: { $0.createdAt < $1.createdAt })
            //            //print("CHANG")
        }
    }
    #endif
}

struct MarcajView: View {
	var marcaj: MarcajeData
	@State var hover: Bool = false
	var body: some View {
		HStack {
			Spacer()
			Text(marcaj.nume ?? "nan")
				.padding(5)
			Spacer()
		}.background(Color.gray.opacity(self.hover ? 0.2 : 0))
			.onHover { val in
				hover = val
			}
		
	}
}
