//
//  DrawWiew.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 04.05.2022.
//

import Foundation
import SwiftUI
struct DrawView: View {
    @EnvironmentObject var scrollEvent: ScrollEnv
    @State var v = _MyView()
    var GRAPHSCALE: CGFloat = 5 // JUST FOR DESIGN
    var bodyMAIN: some View {
        GeometryReader { geo in
            ZStack {

                if !(self.scrollEvent.firstSelected().typeOfStroke == .graph && self.scrollEvent.editGraph && self.scrollEvent.toolInUse == .select) {
                    
                        
                        self.v
                        
                    
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geo.size.width, height: geo.size.height)
                    
                } 
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 500, alignment: .center)
        #endif
    }
    
    var body: some View {
        self.bodyMAIN
        #if os(iOS)
            .sheet(isPresented: self.$scrollEvent.presentIOSPhotoPicker) {
                ImagePicker { image in
                    self.scrollEvent.addIOSImage = image
                    self.scrollEvent.add(iosImage: image, at: self.scrollEvent.addImageLocation)
                }
            }
        #endif
    }
}
