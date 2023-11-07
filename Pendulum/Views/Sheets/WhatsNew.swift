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
            WhatsNewGridRow(icon: "arrow.down.circle", iconColor: .pink, title: "Backup and Restore", summary: "From Settings, you can now generate an archive of your current data—including Pen Pals, events, photos, and stationery—that can be restored at any point.")
            GroupBox {
                WhatsNewGridRow(title: "Just so you know…", summary: "An initial archive has been created for you already. If you need to free up storage or do not wish to keep it around, it can be exported or deleted from the Backup and Restore settings.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    var dismissButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Continue")
                .font(.headline)
                .fullWidth(alignment: .center)
                .padding(5)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
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
