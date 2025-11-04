//
//  CNContact.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import Contacts
import SwiftUI

let contactFormatter = CNContactFormatter()

extension CNContact {
    
    var fullName: String? {
        contactFormatter.string(from: self)
    }
    
    var initials: String {
        let givenNamePrefix = String(self.givenName.trimmingCharacters(in: .whitespaces).prefix(1))
        let familyNamePrefix = String(self.familyName.trimmingCharacters(in: .whitespaces).prefix(1))
        let initialCandidates: String
        if givenNamePrefix.isEmpty && familyNamePrefix.isEmpty {
            initialCandidates = "\(self.organizationName.prefix(1))".uppercased()
        } else {
            initialCandidates = "\(givenNamePrefix)\(familyNamePrefix)".uppercased()
        }
        return String(initialCandidates.filter { $0.isLetter || $0.isNumber })
    }
    
    func matches(term: String) -> Bool {
        self.fullName?.lowercased().contains(term) ?? false
    }
    
    var image: Image? {
        if self.imageDataAvailable, let imageData = self.thumbnailImageData, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
}

#if DEBUG
extension CNContact {
    static func create(
        givenName: String,
        familyName: String,
        nickname: String? = nil,
        address: CNMutablePostalAddress? = nil,
        addressLabel: String? = nil,
        in passedStore: CNContactStore? = nil,
    ) async {
        let store = passedStore ?? CNContactStore()
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        if let nickname {
            contact.nickname = nickname
        }
        if let address {
            contact.postalAddresses.append(CNLabeledValue(label: addressLabel, value: address))
        }
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        try? store.execute(saveRequest)
    }
    static func addDummyData() async {
        let store = CNContactStore()
        
        let buckPalace = CNMutablePostalAddress()
        buckPalace.street = "Buckingham Palace"
        buckPalace.city = "London"
        buckPalace.postalCode = "SW1A 1AA"
        
        let sydneyOperaHouse = CNMutablePostalAddress()
        sydneyOperaHouse.street = "Sydney Opera House"
        sydneyOperaHouse.subLocality = "Bennelong Point"
        sydneyOperaHouse.city = "Sydney"
        sydneyOperaHouse.postalCode = "NSW 2000"
        sydneyOperaHouse.country = "Australia"
        
        await Self.create(givenName: "Evan", familyName: "Carlisle", address: buckPalace, addressLabel: "Home", in: store)
        await Self.create(givenName: "Molly", familyName: "Whitaker", in: store)
        await Self.create(givenName: "Grant", familyName: "Ellison", in: store)
        await Self.create(givenName: "Sophie", familyName: "Hargrove", in: store)
        await Self.create(givenName: "Lucas", familyName: "Merritt", in: store)
        await Self.create(givenName: "Clara", familyName: "Winslow", in: store)
        await Self.create(givenName: "Nathaniel", familyName: "Pierce", nickname: "Nate", in: store)
        await Self.create(givenName: "Amelia", familyName: "Trowbridge", nickname: "Milly", address: sydneyOperaHouse, in: store)
        await Self.create(givenName: "Owen", familyName: "Callahan", in: store)
        await Self.create(givenName: "Fiona", familyName: "Radcliffe", in: store)
    }
}

extension PenPal {
    static func addDummyData() async {
        let context = PersistenceController.shared.container.newBackgroundContext()

        let evan = PenPal(context: context)
        evan.id = UUID()
        evan.name = "Evan Carlisle"
        evan.initials = "EC"
        evan.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Evan-Carlisle1")!) {
            evan.image = imageData
        }
        
        evan.addEvent(
            ofType: .written,
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            pen: "TWSBI Eco Irish Green",
            ink: "Endless Alchemy Mystic Forest",
            paper: "Clairefontaine Triomphe A5 Plain",
            letterType: .letter,
            in: context, saving: false,
        )
        
        evan.addEvent(
            ofType: .received,
            date: Calendar.current.date(byAdding: .day, value: -10, to: .now),
            letterType: .letter,
            in: context, saving: false,
        )
        
        evan.addEvent(
            ofType: .inbound,
            date: Calendar.current.date(byAdding: .day, value: -13, to: .now),
            letterType: .letter,
            in: context, saving: false,
        )
        
        evan.addEvent(
            ofType: .sent,
            date: Calendar.current.date(byAdding: .day, value: -25, to: .now),
            letterType: .letter,
            in: context, saving: false,
        )
        
        evan.addEvent(
            ofType: .written,
            date: Calendar.current.date(byAdding: .day, value: -27, to: .now),
            pen: "TWSBI Eco Irish Green",
            ink: "Robert Oster Fire on Fire",
            paper: "Clairefontaine Triomphe A5 Plain",
            letterType: .letter,
            in: context, saving: false,
        )

        let molly = PenPal(context: context)
        molly.id = UUID()
        molly.name = "Molly Whitaker"
        molly.initials = "MW"
        molly.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Molly-Whitaker2")!) {
            molly.image = imageData
        }
        
        molly.addEvent(ofType: .inbound, date: Calendar.current.date(byAdding: .day, value: -3, to: .now), in: context, saving: false)

        let grant = PenPal(context: context)
        grant.id = UUID()
        grant.name = "Grant Ellison"
        grant.initials = "GE"
        grant.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Grant-Ellison1")!) {
            grant.image = imageData
        }
        
        grant.addEvent(
            ofType: .sent,
            date: Calendar.current.date(byAdding: .day, value: -12, to: .now),
            pen: "Kaweco Brass Sport",
            ink: "Robert Oster Fire on Fire",
            paper: "Rhodia Pad",
            in: context, saving: false,
        )

        let sophie = PenPal(context: context)
        sophie.id = UUID()
        sophie.name = "Sophie Hargrove"
        sophie.initials = "SH"
        sophie.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Sophie-Hargrove1")!) {
            sophie.image = imageData
        }
        
        sophie.addEvent(ofType: .sent, date: Calendar.current.date(byAdding: .day, value: -25, to: .now), in: context, saving: false)
        
        let lucas = PenPal(context: context)
        lucas.id = UUID()
        lucas.name = "Lucas Merritt"
        lucas.initials = "LM"
        lucas.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Lucas-Merritt")!) {
            lucas.image = imageData
        }
        
        lucas.addEvent(ofType: .sent, date: Calendar.current.date(byAdding: .day, value: -28, to: .now), in: context, saving: false)
        
        let clara = PenPal(context: context)
        clara.id = UUID()
        clara.name = "Clara Winslow"
        clara.initials = "CW"
        clara.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Clara-Winslow")!) {
            clara.image = imageData
        }

        clara.addEvent(ofType: .sent, date: Calendar.current.date(byAdding: .day, value: -40, to: .now), in: context, saving: false)
        
        let nathaniel = PenPal(context: context)
        nathaniel.id = UUID()
        nathaniel.name = "Nathaniel Pierce"
        nathaniel.initials = "NP"
        nathaniel.lastEventType = EventType.noEvent
        nathaniel.nickname = "Nate"
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Nathaniel-Pierce")!) {
            nathaniel.image = imageData
        }
        
        nathaniel.addEvent(ofType: .received, date: Calendar.current.date(byAdding: .day, value: -32, to: .now), in: context, saving: false)

        let amelia = PenPal(context: context)
        amelia.id = UUID()
        amelia.name = "Amelia Trowbridge"
        amelia.initials = "AT"
        amelia.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Amelia-Trowbridge")!) {
            amelia.image = imageData
        }

        amelia.addEvent(ofType: .sent, date: Calendar.current.date(byAdding: .day, value: -14, to: .now), in: context, saving: false)
        
        let owen = PenPal(context: context)
        owen.id = UUID()
        owen.name = "Owen Callahan"
        owen.initials = "OC"
        owen.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Owen-Callahan")!) {
            owen.image = imageData
        }
        
        owen.addEvent(ofType: .sent, date: Calendar.current.date(byAdding: .day, value: -20, to: .now), in: context, saving: false)
        
        let fiona = PenPal(context: context)
        fiona.id = UUID()
        fiona.name = "Fiona Radcliffe"
        fiona.initials = "FR"
        fiona.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-Fiona-Radcliffe2")!) {
            fiona.image = imageData
        }
        
        let james = PenPal(context: context)
        james.id = UUID()
        james.name = "James Burbank"
        james.initials = "JB"
        james.lastEventType = EventType.noEvent
        if let (imageData, _) = try? await URLSession.shared.data(from: URL(string: "https://i.pravatar.cc/150?u=pendulum-James-Burbank")!) {
            james.image = imageData
        }
        james.address = "1600 Pennsylvania Avenue NW\nWashington\nDC 20500\nUSA"
        
        let pen = Stationery(context: context)
        pen.type = StationeryType.pen.rawValue
        pen.value = "Jinhao Shark"
        
        let paper = Stationery(context: context)
        paper.type = StationeryType.paper.rawValue
        paper.value = "Tomoe River"
        
        let ink = Stationery(context: context)
        ink.type = StationeryType.ink.rawValue
        ink.value = "Lamy Crystal Amazonite"
        
        try? context.save()
        
    }
}

#endif
