//
//  ChooseTextSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

struct TextOptions: Identifiable {
    let id = UUID()
    let text: Binding<String>
    let options: [String]
    let title: String
}

struct ChooseTextSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: External State
    @Binding var text: String
    
    // MARK: Parameters
    let options: [String]
    let title: String
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if self.text.trimmingCharacters(in: .whitespaces) != "" {
                            self.text = "\(self.text); \(option)"
                        } else {
                            self.text = option
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(option)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct ChooseTextSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChooseTextSheet(text: .constant(""), options: ["One", "Two"], title: "Choose Something")
    }
}
