//
//  Section.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 20.04.2022.
//

import Foundation
import SwiftUI

struct VSection<LabelContent: View, MainContent: View>: View {
    @State var showContent = true
    var label: LabelContent
    #if os(macOS)
    var restrictWidth: Bool = true
    #elseif os(iOS)
    var restrictWidth: Bool = false
    #endif
	var spacing: CGFloat? = nil
    var mainView: () -> MainContent
	
    
    var body: some View {
        VStack(spacing: 0) {
//            Divider().padding()
            HStack {
                self.label.font(.title)
                    .onTapGesture {
                        withAnimation {
                            self.showContent.toggle()
                        }
                    }
                Spacer()
                Button {
                    withAnimation {
                        self.showContent.toggle()
                    }
                } label: {
                    Image(systemName: self.showContent ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20, alignment: .center)
                        .animation(.none, value: 0)
                }
                .buttonStyle(.plain)
            }.padding([.horizontal])
                .padding(.bottom, 5)
                .zIndex(2)
			VStack(spacing: spacing) {
                if self.showContent {
                    self.mainView()
                        
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Divider().padding([.horizontal])
                }
            }
            
            .clipped()
            .restricting(width: 250, if: {self.restrictWidth})
                .zIndex(1)
        }
        .clipped()
    }
}

extension View {
    @ViewBuilder func restricting(width: CGFloat? = nil, height: CGFloat? = nil, if condition: () -> Bool) -> some View {
         
        if condition() {
            self.frame(width: width, height: height, alignment: .center)
        } else {
            self
        }
    }
}

struct PrincipalSection<LabelContent: View, MainContent: View>: View {
    var vertical: Bool = false
    var label: LabelContent
    var mainView: () -> MainContent
    
    var body: some View {
        if vertical {
            
            VStack {
                Divider().padding()
                HStack {
                    self.label.font(.title)
                    Spacer()
                    
                }.padding([.bottom, .horizontal])
                
                self.mainView()
            }
        } else {
            HStack {
                self.label.font(.title)
                Spacer()
                self.mainView()
            }.padding([.horizontal, .top])
        }
    }
}
