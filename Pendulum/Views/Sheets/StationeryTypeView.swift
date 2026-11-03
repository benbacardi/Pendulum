//
//  StationeryTypeView.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct StationeryTypeView: View {

    let icon: String
    let title: String
    @Binding var text: String
    let suggestions: [String]
    let suggestionTitle: String
    @Binding var iconWidth: CGFloat

    @FocusState private var isTextFieldActive: Bool
    @State private var presentSuggestionSheetFor: TextOptions? = nil

    var autoSuggestions: [String] {
        let search = text.lowercased().trimmingCharacters(in: .whitespaces)
        return suggestions.filter { $0.lowercased().contains(search) }
    }

    var image: Image {
        StationeryType.image(forIcon: icon)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                image
                    .foregroundStyle(.secondary)
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: IconWidthPreferenceKey.self, value: geo.size.width)
                        }
                    }
                    .frame(width: iconWidth)
                Text("?")
                    .accessibilityHidden(true)
                    .opacity(0)
            }
            TextField(title, text: $text, axis: .vertical)
                .focused($isTextFieldActive)
            if !suggestions.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("?")
                        .accessibilityHidden(true)
                        .opacity(0)
                    Button(suggestionTitle, systemImage: "ellipsis") {
                        presentSuggestionSheetFor = TextOptions(text: $text, options: suggestions, title: suggestionTitle)
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .toolbar {
            if isTextFieldActive {
                ToolbarItemGroup(placement: .keyboard) {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(autoSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    text = suggestion
                                }) {
                                    Text(suggestion)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(5)
                                .background {
                                    Color(.secondarySystemBackground)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    Button(action: {
                        isTextFieldActive = false
                    }) { Text("Done")}
                }
            }
        }
        .sheet(item: $presentSuggestionSheetFor) { option in
            ChooseTextSheet(text: option.text, options: option.options, title: option.title)
                .presentationDetents([.medium, .large])
        }
    }

}

extension StationeryTypeView {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
