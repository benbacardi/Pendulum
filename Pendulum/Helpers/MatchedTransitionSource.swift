//
//  MatchedTransitionSource.swift
//  Pendulum
//
//  Created by Ben Cardy on 16/09/2025.
//

import SwiftUI

extension ToolbarItem {
    @ToolbarContentBuilder
    func matchedTransitionSourceIfPossible(id: some Hashable, in namespace: SwiftUICore.Namespace.ID) -> some ToolbarContent {
        if #available(iOS 26, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
