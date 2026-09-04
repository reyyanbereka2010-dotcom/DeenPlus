//
//  ScrollDetector.swift
//  Deen+
//
//  Created by Reyyan Bereka on 7/22/26.
//

import SwiftUI

struct ScrollDetector: View {

    @Binding var hideTabBar: Bool
    
    @State private var lastOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            
            Color.clear
                .onChange(
                    of: geo.frame(in: .global).minY
                ) { newOffset in
                    
                    let difference = newOffset - lastOffset
                    
                    if difference < -10 {
                        hideTabBar = true
                    }
                    
                    if difference > 10 {
                        hideTabBar = false
                    }
                    
                    lastOffset = newOffset
                }
        }
    }
}
