//
//  FieldChoiceView.swift
//  Pendulum
//
//  Created by Ben Cardy on 14/11/2022.
//

import SwiftUI

struct FieldChoiceView: View {
    
    let choices: [(String, String)] = [
        ("Date", "calendar"),
        ("Pen", "pencil"),
        ("Ink", "drop"),
        ("Paper", "doc.plaintext"),
    ]
    
    @State private var selectedChoices: Set<String> = []
    @State private var iconWidth: CGFloat = 0
    
    var body: some View {
        List {
            ForEach(choices, id: \.0.self) { (choice, icon) in
                Button(action: {
                    withAnimation {
                        if selectedChoices.contains(choice) {
                            selectedChoices.remove(choice)
                        } else {
                            selectedChoices.insert(choice)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: icon)
                            .background(GeometryReader { geo in
                                Color.clear.preference(key: IconWidthPreferenceKey.self, value: geo.size.width)
                            })
                            .frame(width: iconWidth)
                            .foregroundColor(.primary)
                        Text(choice)
                            .fullWidth()
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedChoices.contains(choice) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .onPreferenceChange(IconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .navigationTitle("Entry Fields")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.selectedChoices = UserDefaults.shared.entryFields
        }
        .onChange(of: selectedChoices) { choices in
            UserDefaults.shared.entryFields = selectedChoices
        }
    }
}

fileprivate struct IconWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FieldChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FieldChoiceView()
        }
    }
}
