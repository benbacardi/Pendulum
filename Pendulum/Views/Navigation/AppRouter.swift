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
            PenPalView(penpal: penpal)
                .id(penpal.id ?? UUID())
        }
    }
    
}

enum SheetDestination: Identifiable {
    case stationeryList(namespace: Namespace.ID?)
    case addPenPalFromContacts(namespace: Namespace.ID?, done: (PenPal) -> ())
    case addPenPalManually(namespace: Namespace.ID?, done: (PenPal) -> ())
    case settings(namespace: Namespace.ID)
    
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
            case .stationeryList(let namespace):
                if #available(iOS 26, *) {
                    if let namespace {
                        EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
                            .navigationTransition(.zoom(sourceID: "stationeryList", in: namespace))
                    } else {
                        EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
                    }
                } else {
                    EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
                }
            case let .addPenPalFromContacts(namespace, done):
                if #available(iOS 26, *) {
                    if let namespace {
                        AddPenPalSheet(done: done)
                            .navigationTransition(.zoom(sourceID: "addPenPal", in: namespace))
                    } else {
                        AddPenPalSheet(done: done)
                    }
                } else {
                    AddPenPalSheet(done: done)
                }
            case let .addPenPalManually(namespace, done):
                if #available(iOS 26, *) {
                    if let namespace {
                        ManualAddPenPalSheet(done: done)
                            .navigationTransition(.zoom(sourceID: "addPenPal", in: namespace))
                    } else {
                        ManualAddPenPalSheet(done: done)
                    }
                } else {
                    ManualAddPenPalSheet(done: done)
                }
            case .settings(let namespace):
                if #available(iOS 26, *) {
                    SettingsList()
                        .navigationTransition(.zoom(sourceID: "settings", in: namespace))
                } else {
                    SettingsList()
                }
            }
        }
    }
}
