//
//  PenPalListViewModel.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/04/2024.
//

import SwiftUI
import GRDBQuery

@MainActor
class PenPalListViewModel: ObservableObject {
    let penPalService: any PenPalServiceProtocol
    
    @Published var penPalsBySection: [PenPalSection] = []
    @Published var penPals: [PenPalModel] = []
    
    init(penPalService: any PenPalServiceProtocol) {
        self.penPalService = penPalService
    }
    
    func loadPenPals() async {
        penPals = await penPalService.fetchPenPals()
        penPalsBySection = penPalService.sectionPenPals(penPals)
    }
    
    func toggleArchived(for penPal: PenPalModel) {
        Task {
            await penPalService.update(penPal: penPal, isArchived: !penPal.isArchived)
            await loadPenPals()
        }
    }
    
}
