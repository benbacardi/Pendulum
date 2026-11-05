//
//  PenPalMapView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2026.
//

import SwiftUI
import MapKit

struct PenPalMapView: View {
    
    // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: State
    @Binding var cameraPosition: MapCameraPosition
    @State private var penpalPlacemarks: [PenPal: CLPlacemark] = [:]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                ForEach(Array(penpalPlacemarks.keys), id: \.self) { penpal in
                    if let placemark = penpalPlacemarks[penpal], let coord = placemark.location?.coordinate {
                        let group = penpal.groupingEventType
                        Marker(penpal.preferredName, systemImage: group.sectionHeaderIconName, coordinate: coord)
                            .tint(group.color)
                    }
                }
            }
            .ignoresSafeArea()
            
            Group {
                if #available(iOS 26, *) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 40, height: 40)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .accessibilityLabel("Close")
            .safeAreaPadding()
        }
        .task {
            let penpals = await PenPal.getPrimaryAddresses()
            self.penpalPlacemarks = penpals
        }
    }
    
}

#Preview {
    PenPalMapView(cameraPosition: .constant(.automatic))
}
