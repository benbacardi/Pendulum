//
//  PenPalModelListView.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/04/2024.
//

import SwiftUI
import GRDBQuery

struct PenPalModelListView: View {
    
    // MARK: Environment
    @EnvironmentStateObject var viewModel: PenPalListViewModel
    
    // MARK: Initializers
    init() {
        self._viewModel = EnvironmentStateObject { env in
            PenPalListViewModel(penPalService: env.penPalService)
        }
    }
    
    // MARK: State
    @State private var iconWidth: CGFloat = .zero
    
    @ViewBuilder
    func sectionHeader(for eventType: EventType) -> some View {
        HStack {
            eventType.phraseImage
                .font(Font.title)
                .foregroundStyle(eventType.color)
            Text(eventType.phrase)
                .fullWidth()
                .font(.body)
                .foregroundStyle(Color.primary)
        }
    }
    
    var body: some View {
        List {
            ForEach(EventType.allCases) { eventType in
                sectionHeader(for: eventType)
            }
            ForEach(viewModel.penPalsBySection) { section in
                Section(header: sectionHeader(for: section.eventType)) {
                    ForEach(section.penPals) { penPal in
                        Button(action: {
                            print("FOO")
                        }) {
                            PenPalModelCell(penPal: penPal)
                                .padding(.horizontal)
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation {
                                    viewModel.toggleArchived(for: penPal)
                                }
                            }) {
                                Label(penPal.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
                }
                .listSectionSpacing(0)
                .listSectionSeparator(.hidden)
            }
        }
        .listSectionSeparator(.hidden)
        .listStyle(.plain)
        .navigationTitle("Pen Pals")
        .task {
            await viewModel.loadPenPals()
        }
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
    }
}

extension PenPalModelListView {
    struct PenPalListIconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

#Preview {
    NavigationStack {
        PenPalModelListView()
    }
}
