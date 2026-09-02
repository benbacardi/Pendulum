//
//  PenPalStateRepair.swift
//  Pendulum
//
//  Created by Ben Cardy on 02/09/2026.
//

import Foundation
import Combine
import CoreData

/// Keeps each Pen Pal's denormalised `lastEventType` honest.
///
/// The Pen Pal list sections are fetch requests predicated on `lastEventTypeValue`, so the value
/// has to be stored rather than derived — which means CloudKit mirrors it like any other
/// attribute. With `NSMergeByPropertyObjectTrumpMergePolicy` a stale copy arriving from another
/// device can win the merge, and nothing re-derives it until that Pen Pal's next event. The
/// symptom is a Pen Pal sitting in the wrong list section until something recalculates it, which
/// is why restoring a backup — which re-derives every Pen Pal — appeared to move people around.
///
/// So: whenever the store changes underneath us, re-derive from the events and write back only
/// the Pen Pals that disagree.
final class PenPalStateRepair {

    static let shared = PenPalStateRepair()

    private var disposables = Set<AnyCancellable>()

    private init() {
        /// Remote changes arrive on a background queue; the repair works on the view context, so
        /// hop to the main queue. Debounced because a CloudKit import posts in bursts.
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.repair()
            }
            .store(in: &disposables)
    }

    /// Re-derives every Pen Pal's last event, saving only if something actually moved.
    ///
    /// This converges rather than ping-ponging between devices: a Pen Pal whose stored state
    /// already matches its events is left untouched, `setLastEventType` skips writes of identical
    /// values, and `save(context:)` returns early without changes — so a device that agrees writes
    /// nothing, and there is no repair to import back.
    func repair() {
        let context = PersistenceController.shared.container.viewContext
        var repaired: [String] = []

        for penpal in PenPal.fetchAll(from: context) {
            let before = (penpal.lastEventType, penpal.lastEventDate, penpal.lastEventLetterType)
            penpal.updateLastEventType(saving: false, in: context)
            let after = (penpal.lastEventType, penpal.lastEventDate, penpal.lastEventLetterType)
            if before != after {
                repaired.append(penpal.wrappedName)
            }
        }

        guard !repaired.isEmpty else { return }

        dataLogger.debug("Repaired the last event type for \(repaired.joined(separator: ", "))")
        PenPal.updateAppState()
        PersistenceController.shared.save(context: context)
    }

}
