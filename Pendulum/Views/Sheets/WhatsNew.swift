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
    var iconColor: Color = .accentColor
    let title: String
    let summary: String
    var suffix: String? = nil
    
    @ViewBuilder
    var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(iconColor)
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
            WhatsNewGridRow(icon: "checkmark.seal", title: "Custom Stationery", summary: "Add your own items to track for each letter you send! What type of envelope did you use? Was it sent with a special stamp? What about a wax seal?\n\nManage your custom stationery types from the Stationery list view.")
        }
        .padding(.horizontal, 40)
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
        VStack(spacing: 0) {
            Text("What's new in")
                .font(.title)
                .bold()
                .fullWidth(alignment: .leading)
                .foregroundStyle(Color.accentColor)
            HStack(spacing: 0) {
                Text("Pendulum ")
                Text(Bundle.main.appVersionNumber)
                    .fullWidth(alignment: .leading)
                    .foregroundStyle(.secondary)
            }
            .font(.title)
            .bold()
        }
        .padding()
        .padding(.top, 60)
        .padding(.horizontal, 20)
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
                        .padding(40)
                }
                
            }
        }
    }
}

struct WhatsNew_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                WhatsNew()
            }
    }
}
