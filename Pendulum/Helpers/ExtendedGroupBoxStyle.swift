//
//  ExtendedGroupBoxStyle.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/04/2023.
//

import SwiftUI

struct ExtendedGroupBoxStyle: GroupBoxStyle {
    var background: Color = Color(.systemGroupedBackground)
    var cornerRadius: CGFloat = 8
    var includePadding: Bool = true
    
    func content(_ configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
    }
    
    func withPadding(_ configuration: Configuration) -> some View {
        content(configuration)
            .padding()
    }
    
    func stack(_ configuration: Configuration) -> some View {
        Group {
            if includePadding {
                withPadding(configuration)
            } else {
                content(configuration)
            }
        }
    }
    
    var contentShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        stack(configuration)
            .background(background)
            .clipped()
            .contentShape(contentShape)
            .clipShape(contentShape)
    }
    
}

struct ExtendedGroupBoxStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GroupBox {
                Text("Hello")
                Text("Everybody")
            }
            .contextMenu {
                Button(action: {}) {
                    Label("Hello", systemImage: "image")
                }
            }
            ForEach(0..<4) { _ in
                GroupBox {
                    Text("Hello")
                    Text("Everybody")
                }
                .contextMenu {
                    Button(action: {}) {
                        Label("Hello", systemImage: "image")
                    }
                }
            }
            .groupBoxStyle(ExtendedGroupBoxStyle(background: .red))
            GroupBox {
                Text("Hello")
                    .padding([.horizontal, .top])
                Rectangle().frame(height: 20)
                Text("Everybody")
                    .padding([.horizontal, .bottom])
            }
            .groupBoxStyle(ExtendedGroupBoxStyle(includePadding: false))
            .contextMenu {
                Button(action: {}) {
                    Label("Hello", systemImage: "image")
                }
            }
        }
        .padding()
    }
}
