//
//  AppRouter.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/02/2023.
//

import SwiftUI

enum Route: Hashable {
    case penPalDetail(penpal: PenPal)
    
    @ViewBuilder
    var view: some View {
        switch self {
        case let .penPalDetail(penpal):
//            PenPalView(penpal: penpal)
            PenPalModelView(penpal.toPenPalModel())
        }
    }
    
}

enum SheetDestination: Identifiable {
    case stationeryList
    case addPenPalFromContacts(done: (PenPal) -> ())
    case addPenPalManually(done: (PenPal) -> ())
    case settings
    
    var id: String {
        switch self {
        case .stationeryList:
            return ".stationeryList"
        case .addPenPalFromContacts:
            return ".addPenPalFromContacts"
        case .addPenPalManually:
            return ".addPenPalManually"
        case .settings:
            return ".settings"
        }
    }
}

@MainActor
class Router: ObservableObject {
    @Published var path: [Route] = []
    @Published public var presentedSheet: SheetDestination?
    public func navigate(to route: Route) {
        replace(with: route)
    }
    public func replace(with routes: [Route]) {
        path = routes
    }
    public func replace(with route: Route) {
        replace(with: [route])
    }
}

@MainActor
extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: Route.self) { destination in
            destination.view
        }
    }
    func withSheetDestinations(sheetDestination: Binding<SheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            switch destination {
            case .stationeryList:
                EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
            case let .addPenPalFromContacts(done):
                AddPenPalSheet(done: done)
            case let .addPenPalManually(done):
                ManualAddPenPalSheet(done: done)
            case .settings:
                SettingsList()
            }
        }
    }
}
