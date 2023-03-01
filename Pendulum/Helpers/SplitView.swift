//
//  SplitView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI

struct SplitView<SidebarContent: View, Content: View>: View {
    @ViewBuilder var sidebar: SidebarContent
    @ViewBuilder var content: Content
    
    let sidebarWidth: CGFloat
    
    public init(@ViewBuilder _ sidebar: () -> SidebarContent, @ViewBuilder content: () -> Content, sidebarWidth: CGFloat = 350) {
        self.sidebar = sidebar()
        self.content = content()
        self.sidebarWidth = sidebarWidth
    }
    
    var body: some View {
        HStack {
            sidebar
            .frame(width: sidebarWidth)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 1)
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            }
            content
            .frame(maxWidth: .infinity)
        }
    }
    
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        SplitView {
            Text("Sidebar")
        } content: {
            Text("Content")
        }
    }
}
