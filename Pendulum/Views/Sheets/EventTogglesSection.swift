//
//  EventTogglesSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

/// The "No further actions" / "No response needed" toggles — one section of `AddEventSheet`'s
/// form. The footer explains what "No further actions" actually does, which depends on the event
/// type and letter type, so it's computed here rather than passed in as a fixed string.
struct EventTogglesSection: View {

    let penPalName: String
    let eventType: EventType
    let letterType: LetterType
    @Binding var noFurtherActions: Bool
    @Binding var ignore: Bool

    private var footerText: String {
        if noFurtherActions {
            return "Pendulum will move \(penPalName) to the \"No actions pending\" section if this is the most recent event."
        } else {
            if eventType == .written || eventType == .sent || eventType == .theyReceived {
                return "If enabled, Pendulum won't indicate that you are waiting for a response to this \(letterType.description)."
            } else {
                return "If enabled, Pendulum won't trigger prompts to respond to this \(letterType.description)."
            }
        }
    }

    var body: some View {
        Section(footer: Text(footerText)) {
            Toggle("No further actions", isOn: $noFurtherActions.animation())
            if !noFurtherActions {
                Toggle("No response needed", isOn: $ignore)
            }
        }
    }
}
