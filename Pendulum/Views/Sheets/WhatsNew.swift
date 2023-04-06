//
//  WhatsNew.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/04/2023.
//

import SwiftUI

struct WhatsNewGridRow: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    
    let icon: String
    let iconColor: Color
    let title: String
    let summary: String
    
    @ViewBuilder
    var iconView: some View {
        Image(systemName: icon)
            .font(.title)
            .foregroundColor(iconColor)
    }
    
    var body: some View {
        GridRow(alignment: .top) {
            if sizeCategory < .accessibilityExtraLarge {
                iconView
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.headline)
                        .fullWidth()
                        .fixedSize(horizontal: false, vertical: true)
                    if sizeCategory >= .accessibilityExtraLarge {
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
    @Environment(\.sizeCategory) var sizeCategory
    
    var grid: some View {
        Grid(horizontalSpacing: 20, verticalSpacing: 30) {
            WhatsNewGridRow(icon: "photo", iconColor: .blue, title: "Photos", summary: "Add photos of the letters that you send and receive, so you never forget what you wrote.")
            WhatsNewGridRow(icon: "smallcircle.filled.circle", iconColor: .yellow, title: "Tracking references", summary: "Save parcel reference numbers to more easily track items you've sent.")
            WhatsNewGridRow(icon: "paperplane", iconColor: .green, title: "Record received stationery", summary: "Keep track of the pens, ink, and paper your Pen Pals used when they wrote to you.")
            WhatsNewGridRow(icon: "rectangle.and.pencil.and.ellipsis", iconColor: .purple, title: "Edit your stationery", summary: "Fix typos or make changes to your logged stationery.")
            WhatsNewGridRow(icon: "questionmark.app.fill", iconColor: .pink, title: "FAQs", summary: "View frequently asked questions from the Settings screen.")
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
            
            if sizeCategory >= .accessibilityExtraLarge {
                
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
