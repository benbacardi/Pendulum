# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Pendulum is a native iOS/iPadOS app (SwiftUI + Core Data) for tracking pen pal correspondence: who you've written to, what's been sent/received, and what stationery (pen/ink/paper) was used. Data syncs across devices via CloudKit.

- Bundle ID: `uk.co.bencardy.Pendulum`, App Group: `group.uk.co.bencardy.Pendulum`, CloudKit container: `iCloud.uk.co.bencardy.Pendulum`
- Deployment target: iOS 17.0, Swift 5.0, universal (iPhone + iPad)
- Single Xcode target/scheme: `Pendulum` (no test target exists in the project)
- One SPM dependency: ZIPFoundation (used for backup/export archives)

## Commands

There is no CLI test suite or lint config in this repo — verification is done by building in Xcode and running on a simulator/device.

- Open the project: `open Pendulum.xcodeproj`
- Build from the CLI: `xcodebuild -project Pendulum.xcodeproj -scheme Pendulum -destination 'platform=iOS Simulator,name=iPhone 17' build`
- If a physical device is genuinely needed, use Gary: `-destination 'platform=iOS,name=Gary'`. Otherwise stick to the simulator.
- The build number (`CURRENT_PROJECT_VERSION`) is bumped manually per commit (see recent commit history, e.g. "build: 101") — bump it in the project settings when cutting a release, not per ordinary commit.

### Running on Gary (the physical device)

Signing is automatic and works; the app installs over the existing one and keeps its data.

```
xcodebuild -project Pendulum.xcodeproj -scheme Pendulum \
  -destination 'platform=iOS,name=Gary' -derivedDataPath /tmp/pendulum-dd build
xcrun devicectl device install app --device Gary /tmp/pendulum-dd/Build/Products/Debug-iphoneos/Pendulum.app
xcrun devicectl device process launch --device Gary uk.co.bencardy.Pendulum
xcrun devicectl device capture screenshot --device Gary --destination shot.png
```

- **`devicectl` cannot inject taps.** Ask the user to navigate, and screenshot what they land on.
- **`capture screen-record` is not supported on Gary** — it fails with "capability not supported" *and exits 0*, so it looks like it worked and produces no file. Don't use it. To cover a sequence, poll `capture screenshot` in a loop instead and diff the frames.
- Screenshots are 1170×2532; downscale with `ffmpeg -i in.png -vf scale=380:-1 out.png` before reading them, and crop at full resolution when a detail matters.
- **Logs from the device**: every logger call in this app except two is `.debug`, and os_log drops debug level on a device unless it is enabled for the subsystem. Xcode's console also shows nothing unless the app was launched from Xcode and is still attached. Use `log stream --device --level debug --predicate 'subsystem == "uk.co.bencardy.Pendulum"'`, or Console.app with *Include Debug Messages*.

## The code review and its artifact

`.claude/reviews/` holds a `/swiftui-pro` review of the whole app (65 findings, ranked) and the HTML
source of a published report. `INDEX.md` is the entry point; `2026-08-25-findings.json` is greppable by
`file`, `line`, `id`, `severity`.

The report is published at https://claude.ai/code/artifact/9dfc9504-c75a-462c-9370-37c569a6735a and
is kept up to date as findings are fixed. **To update it from a new conversation you must pass that URL
as `url` to the Artifact tool** — publishing the file without it creates a second, separate artifact.
Read it first; a publish to an artifact the conversation hasn't read is refused.

## Architecture

### Core Data model (`Pendulum/Data/Pendulum.xcdatamodeld`)

CloudKit-backed (`usedWithCloudKit=YES`) model with four entities:

- **PenPal** — a correspondent. Holds denormalized `lastEventTypeValue`/`lastEventLetterTypeValue`/`lastEventDate` (kept in sync whenever an `Event` is added, see below) so list/section queries don't need to walk the full event history. Has many `Event`s (cascade delete).
- **Event** — a single occurrence in the correspondence lifecycle for a PenPal (see `EventType` below), with the pen/ink/paper used, an optional `trackingReference`, notes, an `ignore` flag (event doesn't count towards "next logical action"), and `noFurtherActions`. Has many `EventPhoto`s (cascade delete).
- **EventPhoto** — binary photo + thumbnail data attached to an event (external binary storage).
- **Stationery** — a flat list of pens/inks/papers the user has used, typed by a `type` string field, used to populate autocomplete pickers.

`PenPal+Extensions.swift`, `Event+Extensions.swift`, `EventPhoto+Extensions.swift`, `Stationery+Extensions.swift` add all business logic on top of the generated Core Data classes (fetch helpers, computed display properties, mutation helpers like `PenPal.addEvent(...)`).

### The EventType state machine (`Pendulum/Model/EventType.swift`)

This is the heart of the app. `EventType` models where a piece of correspondence is in its lifecycle: `written → sent → inbound → received` (their side: `theyReceived`), plus sentinel cases `noEvent`/`nothingToDo`/`archived`. Every PenPal has a `lastEventType`, and the whole UI (list grouping/sections, section header text/icon/color, the "next logical action" buttons on `PenPalView`, per-event descriptions) is derived from this enum rather than being hardcoded per-screen. `nextLogicalEventTypes` decides which action buttons are offered next, and it — along with several `description`/`phrase` variants — branches on `UserDefaults.shared.trackPostingLetters` (whether the user records the separate "posted" step or collapses `written`→`sent`). `LetterType` (letter/postcard/card/parcel) is an orthogonal axis substituted into `EventType` strings via `%TYPE%` placeholders.

`PenPal.groupingEventType` reconciles `lastEventType` + `archived` into the bucket actually used for list sectioning (e.g. `theyReceived` groups under `sent` since the user still awaits a reply).

### Persistence (`Pendulum/Data/PersistenceController.swift`)

Wraps `NSPersistentCloudKitContainer`. Notable non-obvious behavior:
- Store can live in the app's local container or in the shared App Group container (`appGroupStoreURL`); `migrateStore(for:)` performs a one-time copy to the app group location, guarded by `UserDefaults.shared.hasPerformedCoreDataMigrationToAppGroup`. The `IN_EXTENSION` compilation flag skips the migration path (an extension should never attempt to migrate — it just points at the already-migrated app group store), implying an extension target is expected to link this file even though only the `Pendulum` app target currently exists in the project.
- `viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy` with `automaticallyMergesChangesFromParent` — local in-memory edits win on conflict, CloudKit changes merge automatically.
- `setQueryGenerationFrom(.current)` keeps fetches live as CloudKit syncs in.
- `SyncMonitor.swift` separately observes `NSPersistentCloudKitContainer` sync events for surfacing sync status in the UI.

### Shared preferences (`Pendulum/Extensions/UserDefaults.swift`)

All settings live in `UserDefaults.shared`, an app-group-scoped suite (`APP_GROUP`, defined in `Pendulum/App Info/AppInfo.swift`) rather than `.standard` — required so a future/other target sharing the app group sees the same prefs. Keys are a `UserDefaults.Key` enum with typed computed accessors added in an extension; follow that pattern (enum case + typed var) rather than using raw string keys when adding a new setting. `AppPreferences` (`Helpers/AppPreferences.swift`) wraps a subset of these in `@AppStorage`/`ObservableObject` for SwiftUI observation.

### Navigation (`Pendulum/Views/Navigation/AppRouter.swift`)

A single `Router` (`ObservableObject`, `@MainActor`) drives navigation: `path: [Route]` for the `NavigationStack` destination (currently only `.penPalDetail`), and `presentedSheet: SheetDestination?` for modal sheets (stationery list, add-pen-pal-from-contacts, add-pen-pal-manually, settings). Sheets conditionally use `navigationTransition(.zoom(...))` on iOS 26+ via a passed `Namespace.ID`, falling back to a plain sheet on older OS versions. `ContentView` picks between `PenPalSplitView` (iPad, regular width) and `PenPalTab` (iPhone/compact) — both presumably share the same `Router`/sheet plumbing.

### iOS-version compatibility (`Pendulum/Backport/Backport.swift`)

New SwiftUI APIs (e.g. iOS 26 `Glass` effects) are backported behind a `view.backport.xxx` shim (pattern from davedelong.com) rather than scattering `if #available` checks through view code — follow this pattern when adding UI that depends on a newer OS API.

### Notifications (`Pendulum/Notifications/PenPal+Notifications.swift`)

Two independent local-notification flows, both `UserDefaults`-gated: a single repeating daily "you have letters to post" notification (only scheduled if `trackPostingLetters` is on and at least one PenPal is in `.written` state), and one "don't forget to write back" notification per PenPal (keyed by `"\(penpal.id):shouldWriteBack"`), scheduled `sendWriteBackNotificationDelay` after the last event (7 days in release builds, 120 seconds in `DEBUG` for fast manual testing).

### Export / Backup (`Pendulum/Data/Export.swift`, `Views/Data/*`)

Exports the full Core Data graph (PenPals, Events, photos) to a `Codable` JSON representation plus photo files, zipped via ZIPFoundation/AppleArchive. `ContentView` triggers a one-time automatic initial backup on first launch after `hasGeneratedInitialBackup` is unset.

### Logging (`Pendulum/Debug/Loggers.swift`)

Use the existing category-scoped `Logger` globals (`appLogger`, `dataLogger`, `sqlLogger`, `cloudKitLogger`, `storeLogger`) via `os.log` rather than `print`, matching the area of the code you're touching.
