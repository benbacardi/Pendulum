//
//  WhatsNew.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/04/2023.
//

import SwiftUI

struct WhatsNewGridRow: View {
    
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var icon: String? = nil
    var iconColor: Color? = nil
    let title: String
    let summary: String
    var suffix: String? = nil
    
    @ViewBuilder
    var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(iconColor ?? .primary)
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        GridRow(alignment: .top) {
            if dynamicTypeSize < .accessibility3 {
                iconView
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.headline)
                        .fullWidth()
                        .fixedSize(horizontal: false, vertical: true)
                    if dynamicTypeSize >= .accessibility3 {
                        Spacer()
                        iconView
                    }
                }
                Text(summary)
                    .fixedSize(horizontal: false, vertical: true)
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .fullWidth()
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
            }
            .fullWidth()
        }
    }
    
}

struct WhatsNew: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var grid: some View {
        Grid(horizontalSpacing: 20, verticalSpacing: 30) {
            WhatsNewGridRow(icon: "sparkles", iconColor: .accentColor, title: "New Design", summary: "With the release of iOS 26, Pendulum sports a brand new design for your list of Pen Pals, highlighting where in the world your letters are going to or coming from.")
            WhatsNewGridRow(icon: "mappin.and.ellipse", iconColor: .green, title: "Local Addresses", summary: "For those of you who choose not to sync your Pen Pals with your device contacts, you can now store their addresses directly in Pendulum for easy access.")
            WhatsNewGridRow(icon: "person.crop.circle", iconColor: .pink, title: "What's in a name?", summary: "If any of your Pen Pal contacts have nicknames, they'll now be displayed instead of their full name.", suffix: "This can be disabled in Settings.")
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    @ViewBuilder
    var dismissButton: some View {
        if #available(iOS 26.0, *) {
            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.headline)
                    .fullWidth(alignment: .center)
                    .padding(5)
            }
            .foregroundStyle(.white)
            .buttonStyle(.glass(.regular.tint(.accentColor)))
        } else {
            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.headline)
                    .fullWidth(alignment: .center)
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    var header: some View {
        VStack(spacing: 4) {
            Text("What's New")
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .center)
            Text("Version \(Bundle.main.appVersionNumber) (Build \(Bundle.main.appBuildNumber))")
        }
        .foregroundColor(.white)
        .padding()
        .padding(.vertical)
        .background(Color.accentColor)
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            if dynamicTypeSize >= .accessibility3 {
                
                ScrollView {
                    header
                    grid
                }
                Spacer()
                dismissButton
                    .padding(.horizontal)
                    .padding(20)
                
            } else {
                
                header
                VStack {
                    ViewThatFits(in: .vertical) {
                        grid
                        ScrollView {
                            grid
                        }
                    }
                    Spacer()
                    dismissButton
                        .padding(20)
                }
                
            }
        }
    }
}

struct WhatsNew_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNew()
    }
}
