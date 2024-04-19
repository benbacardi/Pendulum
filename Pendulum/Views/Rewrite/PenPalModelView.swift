//
//  PenPalModelView.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import SwiftUI
import GRDBQuery

struct PenPalModelView: View {
    
    // MARK: Environment
    @EnvironmentStateObject var viewModel: PenPalViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: State
    @State private var buttonHeight: CGFloat?
    
    // MARK: Initializers
    init(_ penPal: PenPalModel) {
        self._viewModel = EnvironmentStateObject { env in
            PenPalViewModel(for: penPal, penPalService: env.penPalService)
        }
    }
    
    @ViewBuilder
    func dateDivider(for date: Date, withDifference difference: Int, relativeToToday: Bool = false) -> some View {
        HStack {
            if relativeToToday {
                if difference == 0 {
                    Text("Today")
                } else {
                    Text("^[\(difference) day](inflect: true, partOfSpeech: noun) ago")
                }
            } else {
                Text("^[\(difference) day](inflect: true, partOfSpeech: noun) before")
            }
            Text("-")
            Text(date, style: .date)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .fullWidth(alignment: .center)
    }
    
    @ViewBuilder
    func actionButton(for eventType: EventType, text: String? = nil) -> some View {
        Button(action: {
            
        }) {
            Label(text ?? eventType.actionableTextShort, systemImage: eventType.icon)
                .fullWidth(alignment: .center)
                .font(.headline)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ButtonHeightPreferenceKey.self, value: geo.size.height)
                })
        }
        .tint(eventType.color)
        .buttonStyle(.borderedProminent)
    }
    
    @ViewBuilder
    var headerAndButtons: some View {
        VStack(spacing: 10) {
            PenPalModelHeader(penPal: viewModel.penPal)
                .padding(.horizontal)
            if viewModel.penPal.lastEventType != .noEvent && !viewModel.penPal.isArchived && viewModel.penPal.lastEventType != .nothingToDo {
                Text(viewModel.penPal.lastEventType.phrase)
                    .fullWidth()
                    .padding(.horizontal)
            }
            HStack {
                if viewModel.penPal.isArchived {
                    actionButton(for: .archived, text: "Unarchive")
                } else {
                    ForEach(viewModel.penPal.lastEventType.nextLogicalEventTypes) { eventType in
                        actionButton(for: eventType)
                    }
                }
                Menu {
                    ForEach(EventType.actionableCases) { eventType in
                        Label(eventType.actionableText, systemImage: eventType.icon)
                    }
                } label: {
                    Label("More actions", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .frame(height: buttonHeight)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            headerAndButtons
            if viewModel.events.isEmpty {
                Spacer()
                if let image = UIImage(named: "undraw_letter_re_8m03") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                }
                Text("You have no correspondence with \(viewModel.penPal.name) yet!")
                    .fullWidth(alignment: .center)
                    .padding()
                    .padding(.top)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.events) { section in
                        Section(header: dateDivider(for: section.events.first!.date, withDifference: section.dayInterval, relativeToToday: section.calculatedFromToday)) {
                            ForEach(section.events) { event in
                                EventModelCell(event: event, onDelete: { event in
                                    withAnimation {
                                        viewModel.delete(event: event)
                                    }
                                })
                                .padding(.horizontal)
                            }
                            .listRowSeparator(.hidden).listRowInsets(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
                        }
                        .listSectionSpacing(0)
                        .listSectionSeparator(.hidden)
                    }
                }
                .listSectionSeparator(.hidden)
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .onPreferenceChange(ButtonHeightPreferenceKey.self) {
            self.buttonHeight = $0
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PenPalModelView {
    struct ButtonHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

#Preview {
    PenPalModelView(MockPenPalService.penPals[0])
}
