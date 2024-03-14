//
//  ActionsView.swift
//  NoteTakerApp (macOS)
//
//  Created by Alexandru Ariton on 14.05.2022.
//

import Foundation
import SwiftUI

extension Array where Element == NoteAction {
    func filtered() -> Self {
        let c = self.count
        
        var v: Self = []
        
        for (n, act) in self.enumerated() {
            if act.primordialType == .reverted {
            } else {
                v.append(act)
            }
        }
        return v
    }
}

struct ActionsView: View {
    @EnvironmentObject var environment: ScrollEnv
    var mainBody: some View {
        VStack {
            LazyVStack(spacing: 5) {
                if self.showActionsJustForSelected {
                    ForEach(self.environment.allActions.filter({$0.noteOwnerID == self.environment.currentNoteId && $0.strokeID == self.environment.firstSelected().id}), id: \.selfId) { action in
                        OneCardActionView(action: action)
                            .padding(.horizontal)
                    }
                } else {
                    ForEach(self.environment.allActions.filter({$0.noteOwnerID == self.environment.currentNoteId}), id: \.selfId) { action in
                        OneCardActionView(action: action)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    @State var showActionsJustForSelected = false
    
    var body: some View {
        VStack {
            
            ScrollView(showsIndicators: false) {
                Spacer(minLength: 50)
                VSection(showContent: true,
                         label:
                HStack {
                    Text("Actions")
                    
                    
                }
                
                ) {
                    VStack {
                        if self.environment.selectedLinesCount() == 1 {
                            Button {
                                self.showActionsJustForSelected.toggle()
                            } label: {
                                HStack {
                                    Spacer(minLength: 0)
                                    Text(self.showActionsJustForSelected ? "All" : "Just selected")
                                        .font(.system(size: 13))
                                        .padding(3)
                                    Spacer(minLength: 0)
                                }
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            }.buttonStyle(.plain)
                                .padding(.horizontal)
                        }
                        self.mainBody
                    }
                }
                Spacer(minLength: 100)
            }
            #if os(macOS)
            .edgesIgnoringSafeArea(.all)
            .frame(minWidth: 250, maxWidth: 250, minHeight: 400)
            #elseif os(iOS)
            .frame(height: 400)
            #endif
        
            .background(TranslucentBackground().edgesIgnoringSafeArea(.all))
        }
    }
}

extension View {
    @ViewBuilder func blockOfCode() -> some View {
        self
            .font(.system(size: 10, weight: .thin, design: .monospaced))
            .padding(5)
            .background(.black)
            .cornerRadius(10)
            .foregroundColor(.white)
            .padding(5)
    }
}

struct OneCardActionView: View {
    @State var action: NoteAction
    @EnvironmentObject var environment: ScrollEnv
    
    func str(for val: [CGPoint]) -> String {
        if val.count >= 2 {
            return "\(String(format: "%.1f", val[0].x)), \(String(format: "%.1f", val[0].y))"
        } else {
            return "translated"
        }
    }
    
    @ViewBuilder func viewOldValue(forProperty property: StrokeAttributes?, action: NoteAction) -> some View {
        VStack {
            if property == .color {
                Color(action.previousValue as! XColor).clipShape(Circle())
            } else if property == .textValue {
                Text(action.previousValue as! String)
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else if property == .width {
                Text("\(String(format: "%.2f", action.previousValue as! CGFloat))")
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else if property == .points {
                Text("\(str(for: action.previousValue as! [CGPoint]))")
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder func viewNewValue(forProperty property: StrokeAttributes?, action: NoteAction) -> some View {
        VStack {
            if property == .color {
                Color(action.currentValue as! XColor).clipShape(Circle())
            } else if property == .textValue {
                Text(action.currentValue as! String)
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else if property == .width {
                Text("\(String(format: "%.2f", action.currentValue as! CGFloat))")
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else if property == .points {
                Text("\(str(for: action.currentValue as! [CGPoint]))")
                    .frame(width: 55, height: 40, alignment: .center)
                    .blockOfCode()
            } else {
                EmptyView()
            }
        }
    }
    
    @State var hov = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(Date.format(date: action.actionDate))")
                    .font(.system(size: 10, weight: .thin, design: .monospaced))
                    
                Spacer()
            }
            .padding(3)
            .background(Color.gray.opacity(0.3))
            VStack {
                HStack {
                    Text("\(self.action.strokeID.uuidString)")
                        .lineLimit(1)
                        .frame(width: 75, alignment: .center)
                        .blockOfCode()
                    
                    
                    Text(".\(self.action.strokeProperty?.rawValue ?? "none")")
                        .blockOfCode()
                    
                }
                HStack {
                    Spacer()
                    if self.action.primordialType == .reverted {
                        self.viewNewValue(forProperty: action.strokeProperty, action: action)
                    } else {
                        self.viewOldValue(forProperty: action.strokeProperty, action: action)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                    Spacer()
                    if self.action.primordialType == .reverted {
                        self.viewOldValue(forProperty: action.strokeProperty, action: action)
                    } else {
                        self.viewNewValue(forProperty: action.strokeProperty, action: action)
                    }
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text(action.primordialType == .normal ? "Undo" : "Redo")
                    Spacer()
                }
                .padding(5)
            }
            .padding(5)
        }
        
        
        .background(
            Group {
                if hov {
                    Group {
                        if action.primordialType == .normal {
                            Color.blue.opacity(0.9).cornerRadius(10)
                        } else {
                            Color.red.opacity(0.9).cornerRadius(10)
                        }
                    }
                    
                } else {
                    Group {
                        if action.primordialType == .normal {
                            HighlightedBackground(cornerRadius: 10)
                        } else {
                            Color.red.opacity(0.5).cornerRadius(10)
                        }
                    }
                }
            }
        
        )
        .cornerRadius(10)
        .onTapGesture {
           
            action.revert()
        }
        .onHover { va in
            self.hov = va
        }
    }
}
