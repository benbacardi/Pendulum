//
//  PenPalContactSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI
import Contacts

struct PenPalContactSheet: View {
    
    // MARK: Parameters
    let penpal: PenPal
    
    // MARK: State
    @State private var addresses: [CNLabeledValue<CNPostalAddress>] = []
    
    var body: some View {
        VStack {
            
            if let image = penpal.displayImage {
                image
                    .clipShape(Circle())
                    .frame(width: 60, height: 60)
            } else {
                ZStack {
                    Circle()
                        .fill(.gray)
                    Text(penpal.initials)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
            }
            
            Text(penpal.fullName)
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .center)
            
            ScrollView {
                ForEach(addresses, id: \.self) { address in
                    GroupBox {
                        Text(CNLabeledValue<NSString>.localizedString(forLabel: address.label ?? "No label"))
                            .font(.caption)
                            .bold()
                            .fullWidth()
                        Text(address.value.fullAddress)
                            .fullWidth()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                let store = CNContactStore()
                let keys = [
                    CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactPostalAddressesKey,
                    CNContactImageDataAvailableKey,
                    CNContactImageDataKey,
                ] as! [CNKeyDescriptor]
                do {
                    let contact = try store.unifiedContact(withIdentifier: penpal.id, keysToFetch: keys)
                    self.addresses = contact.postalAddresses
                } catch {
                    dataLogger.error("Could not fetch contact with ID \(penpal.id): \(error.localizedDescription)")
                }
            }
        }
    }
    
}
