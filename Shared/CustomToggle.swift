//
//  CustomToggle.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 20.04.2022.
//

import Foundation
import SwiftUI

struct CustomToggle<Content: View>: View {

    @Binding var value: Bool
    
    var label: () -> Content
    
    var body: some View {
        
        HStack {
            
            self.label()
            Spacer()
            ZStack {
                ZStack {
                    
//                    Color.blue
                    if self.value {
                        Color.blue
                            .transition(.slide)
                    } else {
                        Color.gray
                            .transition(.slide)
                    }
                }
                HStack {
                    if self.value {
                        Spacer()
                    }
                    Color.white
                        .frame(width: 20, height: 20, alignment: .center)
                        .padding(.horizontal, 2)
                        .clipShape(Circle())
                    if !self.value {
                        Spacer()
                    }
                    
                }
                
            }.frame(width: 40, height: 25)
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation {
                        self.value.toggle()
                    }
                }
        }
    }
}
