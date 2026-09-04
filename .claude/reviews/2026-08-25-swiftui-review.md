# Pendulum — SwiftUI Review

- **Date:** 2026-08-25
- **Branch:** `stationery-list-toolbar` (at commit `6ef28a0`)
- **Scope:** 79 Swift files, ~10,300 lines
- **Build context:** iOS 17.0 deployment target, Swift 5.0, strict concurrency off, no test target
- **Method:** `/swiftui-pro` skill — modern API, view structure, data flow, navigation, HIG/design, accessibility, performance, Swift concurrency, hygiene
- **Artifact:** `2026-08-25-swiftui-review.html` (published — see `INDEX.md` for URL)
- **Totals:** 65 findings — 9 high, 28 medium, 28 low (57 individual + 8 cross-cutting sweeps).
  Six of the nine high-severity items are genuine correctness or crash bugs; the other three are performance/resource.

> Line numbers refer to the working tree at time of review. Verify before acting if the file has changed since.

---

## Priority queue (fix in this order)

| # | Finding | Sev | Location |
|---|---------|-----|----------|
| 1 | Force-unwrapped URL from user-typed tracking reference — crash | High | `Views/Subviews/EventCell.swift:206` |
| 2 | `save(context:)` ignores its parameter | High | `Data/PersistenceController.swift:106` |
| 3 | Managed objects read off their own queue | High | `Data/PenPal+Extensions.swift:479` |
| 4 | `@AppStorage` inside `ObservableObject` doesn't publish | High | `Helpers/AppPreferences.swift:15` |
| 5 | N confirmation dialogs on one shared boolean | High | `Views/Subviews/PenPalListSection.swift:208` |
| 6 | Device-motion updates never stopped | Medium | `Views/SettingsList.swift:297` |
| 7 | Stats fetches block the main thread | Medium | `Views/StatsView.swift:246–360` + 30 sites |
| 8 | `.id(refreshID)` rebuilds the event list on every save | Medium | `Views/PenPalView.swift:206` |
| 9 | Dynamic Type / VoiceOver gaps | Medium | StatsView, PenPalView, EventCell, AddEventSheet |
| 10 | Deprecated API sweep | Low | app-wide |
| 11 | Oversized view files | Low | AddEventSheet, EventPropertyDetailsSheet, PenPalView |

---

## Data/PersistenceController.swift

### `save(context:)` ignores the context it is given — HIGH, correctness
`:106–116`. All 20 call sites pass a context that is discarded in favour of `container.viewContext`. Harmless today (everything is the view context), wrong the moment a background context exists. The `DispatchQueue.main.async` also defers every save by a runloop tick — which is why several call sites grew their own `asyncAfter` delays.

```swift
// Before
func save(context: NSManagedObjectContext) {
    if context.hasChanges {
        DispatchQueue.main.async {
            do { try container.viewContext.save() } catch { dataLogger.error("…") }
        }
    }
}

// After
@MainActor
func save(context: NSManagedObjectContext) {
    guard context.hasChanges else { return }
    do { try context.save() }
    catch { dataLogger.error("[CoreData:save] \(error.localizedDescription)") }
}
```

### Chained force unwraps on the launch path — MEDIUM, crash-risk
`:91, :101`. `persistentStoreDescriptions.first!.url!` in `migrateStore`. Guard and log instead.

---

## Data/PenPal+Extensions.swift (756 lines)

### Core Data objects read from a global dispatch queue — HIGH, concurrency
`:479–490`. `store.enumerateContacts` runs on `DispatchQueue.global`; the closure reads `self.wrappedName` and passes `self` to `setContactID(for:)` which reads `penpal.id`. Trips `-com.apple.CoreData.ConcurrencyDebug 1`; hard error under Swift 6.

Fix: snapshot `wrappedName` and `id` on the context's queue first, do the enumeration in a `Task.detached`, hop back to `MainActor` to write. Add an ID-based `UserDefaults.setContactID(forID:to:)` overload so no managed object crosses the boundary.

### `syncWithContact()` blocks the main actor — MEDIUM, performance
`:444`, called from `Views/PenPalView.swift:261`. Synchronous, invoked from `.task` (which inherits `@MainActor`). `store.unifiedContact(withIdentifier:)` is a blocking XPC call — opening any pen pal stalls the UI. Make it `async`.

### `displayImage` is `async` with no suspension point — MEDIUM, performance
`:62–68`. Runs on the caller's actor (always main, via `PenPalListItem.swift:49`), so every avatar decodes a `UIImage` on the UI thread while appearing not to. Wrap the decode in `Task.detached`.

---

## Helpers/AppPreferences.swift

### `@AppStorage` inside `ObservableObject` does not drive view updates — HIGH, data-flow
`:11–19`. Documented dead end. `didSet` fires after the change (SwiftUI needs `willSet`), and external writes to the same key never fire it. `StatsView` and `PenPalList` both depend on `trackPostingLetters`.

Fix: delete the class, use `@AppStorage` directly per view. Knock-on: also removes the `.environmentObject(AppPreferences.shared)` injection and the unused `@EnvironmentObject var appPreferences` in `PenPalList.swift:14` and `SettingsList.swift:33`.

### `static var shared` is a mutable global — LOW, concurrency
`:13`. Should be `static let`. Same for `PersistenceController.preview` (`:25`).

---

## Views/Subviews/PenPalListSection.swift (239 lines)

### One confirmation dialog per row, all on one boolean — HIGH, correctness
`:208`. The `.confirmationDialog` sits inside the `ForEach`, so N pen pals means N dialogs bound to `$showDeleteAlert`. Move it outside the loop and drive presentation from `currentPenPal != nil`.

### 50 ms sleep to dodge a presentation race — MEDIUM, correctness
`:210`. `DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)` before deleting. Should disappear once the dialog is moved; if a beat is genuinely needed use `Task.sleep(for: .milliseconds(50))`.

### `.animation(.default, value: penpal)` never fires — MEDIUM, correctness
`:199`, also `Views/Subviews/EventCell.swift:202`. `PenPal` is an `NSManagedObject`; `==` is `NSObject` identity comparison, so property mutations don't change the watched value. Use `value: penpal.lastEventType`.

### 65-line initializer — MEDIUM, performance
`:47–112`. Builds predicates, reads `UserDefaults`, constructs a `FetchRequest`. `PenPalList` creates one per `EventType.orderedCases` on every render. Hoist to static pure functions, following the existing `sortDescriptors(for:)` pattern at `:27`.

---

## Views/StatsView.swift (377 lines)

### Every stats fetch runs on the main thread — HIGH, performance
`:246–360`. `.task` inherits `@MainActor`, so `PenPal.averageTimeToRespond` (walks every pen pal × every event) blocks the UI. The `DispatchQueue.main.async` wrappers inside add a frame of latency and buy nothing. Same misconception at `MostUsedStationeryChart.swift:72`, `SettingsList.swift:246`, `TipJarView.swift:118`, `PenPalList.swift:66` — 30+ sites.

Fix: `Task.detached` + `newBackgroundContext()` + `performAndWait`, then assign directly. **Caveat:** returned values must be `Sendable` — the recipient blocks at `:314–336` return `[PenPal]` and need to hand back `NSManagedObjectID`s and re-fetch on the main context.

### Headline numbers ignore Dynamic Type — MEDIUM, accessibility
`:124, 135, 150, 156`. `.font(.system(size: 40, design: .rounded))` → `.font(.system(.largeTitle, design: .rounded))`.

### Manual pluralisation — MEDIUM, localisation
`:148, 220, 231`. Use `Text("^[\(count) item](inflect: true)")`.

### `UserDefaults.shared.trackPostingLetters` read in `body` — MEDIUM, data-flow
`:119, 121, 296`. Not observable — the Sent/Written label won't update. Use `@AppStorage`.

### `@ViewBuilder` methods `yearPill` / `mostUsed` — LOW, view-structure
`:41–83`. Extract to `YearPill` and `MostUsedStationeryRow` structs.

### Sorting in `body` — LOW, performance
`:205`. `Array(mostUsedCustom.keys).sorted(using:)` every render. Sort once in the `.task`.

### One-parameter `onChange` — LOW, deprecated-api
`:106`.

### `NavigationLink(destination:)` — LOW, navigation
`:184–207`, also `SettingsList.swift:129, 166, 203, 227`. Destinations built eagerly every render. Extend the existing `Route` enum / `withAppRouter()`.

---

## Views/PenPalView.swift (316 lines)

### Event list destroyed and rebuilt on every Core Data save — HIGH, performance
`:206, :251–255, :278`. `.id(refreshID)` + `refreshID = UUID()` in the `NSManagedObjectContextDidSave` handler tears down the whole `ScrollView`/`LazyVStack`, losing scroll position, for *any* save app-wide. The `@FetchRequest` at `:22` already publishes changes.

Root cause is `eventsWithDifferences`, a cached derived array. It's a pure function of `events` — make it a computed property and delete `refreshID`, `.id()` and the `didSave` publisher.

### iOS 26 check duplicates the whole button — MEDIUM, performance
`:88–113`. Produces `_ConditionalContent` and different structural identity per OS. Extend the existing `Backport` shim (`Backport/Backport.swift`; `backport.glassEffect` already used in `PenPalListSection`) with a button-style case.

### Manual pluralisation in `dateDivider` — MEDIUM, localisation
`:148, 154, 157`. Also gets zero wrong in English.

### `buttonHeight` written but never read — LOW, dead-code
`:23, 80, 97, 107, 256, 309–315`. Three `GeometryReader`s feeding a preference key nothing consumes — three extra layout passes per render. Delete all of it.

### `headerAndButtons()` is ~90 lines — LOW, view-structure
`:44–164`. Also `eventTypeMenu` and `dateDivider(for:)`.

### Debug `asyncAfter` hook — LOW, hygiene
`:262–268`. Inside `#if DEBUG`, so it doesn't ship; `Task.sleep(for:)` would cancel with the view.

---

## Views/Subviews/EventCell.swift (256 lines)

### Force-unwrapped URL from free-text input — HIGH, crash
`:206`. `trackingReference` comes straight from a `TextField` with no validation. A pasted tracking number containing a space makes `URL(string:)` return nil and the `!` traps. **Most likely crash in the app.** Percent-encode and `if let`.

### `event.allPhotos()` called four times per render — MEDIUM, performance
`:97, 99, 101, 104`. Walks a to-many relationship each time, inside a `LazyVStack` row. Hoist to a `let`.

### Photo thumbnails are unlabelled buttons — MEDIUM, accessibility
`:54–60`. Add `.accessibilityLabel("View photo")`.

### `iconWidth` / `IconWidthPreferenceKey` unused — LOW, dead-code
`:21, 249–255`.

---

## Views/SettingsList.swift (350 lines)

### Device-motion updates started and never stopped — HIGH, resource-leak
`:36, :297–311`. Two compounding problems: `let motionManager = CMMotionManager()` is a stored property on a `View` struct (fresh manager per re-creation), and `.task` starts 10 Hz updates with no `stopDeviceMotionUpdates()`. The gyroscope keeps sampling after the sheet is dismissed.

Fix: `@State private var motionManager` (using `@State` as a cache for an expensive non-observable object), wrap in `AsyncStream`, `defer { stopDeviceMotionUpdates() }`.

### `@Environment(\.presentationMode)` deprecated — MEDIUM, deprecated-api
`:34, :318`, also `EventPropertyDetailsSheet.swift:44`. Use `\.dismiss`.

### Force-unwrapped literal URLs — MEDIUM, crash-risk
`:218, :240`. Hoist to named constants in `AppInfo.swift`.

### `.foregroundColor()` faking a disabled look — LOW, design
`:105, 113, 125`. `.disabled()` is already applied and draws the correct treatment, including under Increase Contrast / Differentiate Without Color.

### `SafariView` is a second type in the file — LOW, hygiene
`:13–26`. Move to `Helpers/SafariView.swift`.

### `Task { }` wrapping synchronous calls — LOW, concurrency
`:265–272`. Buys an actor hop and nothing else; doesn't move the Core Data fetch off main either.

---

## Views/Sheets/AddEventSheet.swift (667 lines, 4 types)

### 100 ms sleep racing the change tracking — MEDIUM, correctness
`:603`. The `.task` populates state, firing all eight `onChange` handlers; `asyncAfter(0.1)` tries to reset `thingsHaveChanged` afterwards. On a slow launch the flag stays true and `interactiveDismissDisabled` blocks swipe-to-dismiss on an untouched sheet. Use an `isPopulating` guard flag.

### `lowercased().contains()` on user input — MEDIUM, localisation
`:39–42`, also `SymbolPicker.swift:29`. Breaks on diacritics and Turkish dotted-i. Use `localizedStandardContains`.

### Icon-only button with no label — MEDIUM, accessibility
`:74–78`. Use `Button(_:systemImage:)` + `.labelStyle(.iconOnly)`.

### 250-line `body`, save logic inline — MEDIUM, view-structure
`:392–649`; save action at `:633–639` is a ~200-char expression with 14 arguments, duplicated across create/update branches. Extract a `save()` method and an `EventDraft` value type.

### Eight near-identical `onChange` handlers — LOW, simplification
`:550–576`. Compose tracked fields into one `Equatable` value.

### Four types in one file — LOW, hygiene
`:11, 27, 117, 198` — `CustomStationeryTypeView`, `StationeryTypeView`, `AddStationeryTypeForm`, `AddEventSheet`.

### `cornerRadius()` + main-thread fetches — LOW, mixed
`:490` and `:651–656`. `updateStationery()` runs three `fetchDistinctStationery` calls on the main actor, from both `.task` and `onChange(of: eventType)`.

---

## Views/Charts/

### `@Binding` for read-only inputs — MEDIUM, data-flow
`SentByTypeChart.swift:13–16`, `SentAndWrittenByDayOfWeekChart.swift:39–40`, `SentAndWrittenByMonthChart.swift`. None of the three ever write back. Make them `let`.

### Chart data computed only in `onChange` — MEDIUM, correctness
`SentAndWrittenByDayOfWeekChart.swift:77`. If the view mounts with `events` already populated, it renders permanently empty. Currently works only because `StatsView`'s `.task` happens to assign after the chart mounts — coincidence of ordering, not a guarantee. Derive the data instead.

### `parsedData` filters+sorts in `body`, called twice — MEDIUM, performance
`MostUsedStationeryChart.swift:36–37, :61`. The `.frame(height: CGFloat(count * 50))` also ignores Dynamic Type — use `@ScaledMetric`.

### `.filter { }.count` — LOW, simplification
`ByDayOfWeek:90`, `ByMonth:73` → `count(where:)`.

### Sample data ships in the release binary — LOW, dead-code
`ByDayOfWeek:18–33` (`SENT_AND_WRITTEN_BY_DAY_OF_WEEK_DATA`, referenced nowhere), `MostUsedStationeryChart:19–34` (15 lines of commented-out placeholders in a `@State` initialiser).

---

## Views/Sheets/EventPropertyDetailsSheet.swift (448 lines)

### `ParameterCount.id` is a fresh `UUID()` per construction — HIGH, correctness
`:10–27`. Values are rebuilt from Core Data on every fetch, so `ForEach` sees entirely new identities each time and destroys/recreates every row — killing animations, scroll position and in-flight edits. `Identifiable` and `Equatable` also disagree (custom `==` ignores `id`). Derive: `var id: String { "\(typeName):\(name)" }`.

### `presentationMode` and `.navigationBarLeading` — MEDIUM, deprecated-api
`:44, 349, 394, 419`.

---

## Smaller files

| File:line | Finding | Sev |
|---|---|---|
| `Extensions/UIApplication.swift:23` | `applicationIconBadgeNumber` deprecated in iOS 17 → `UNUserNotificationCenter.setBadgeCount(_:)` | Medium |
| `Extensions/Bundle.swift:13, 21, 25` | `infoDictionary?["…"] as! String` — force-casting `Any?`, traps on nil | Medium |
| `Views/TipJarView.swift:107` | `alert(isPresented:) { Alert(...) }` is the iOS 13 API; lone OK button can be omitted | Medium |
| `Views/Sheets/AddPenPalSheet.swift:98` | `Text` concatenation with `+` — deprecated, breaks localisation | Low |
| `Views/DebugView.swift:45`, `TipJarView.swift:31`, `Data/Export.swift:228` | Remaining force unwraps; `Export.swift` should use `URL.documentsDirectory` | Low |

---

## Cross-cutting sweeps

| Replace | With | Sites | Concentrated in |
|---|---|---:|---|
| `foregroundColor(_:)` | `foregroundStyle(_:)` | 58 | SettingsList (8), EventPropertyDetailsSheet (7), AddEventSheet (7), StatsView (5) |
| `onChange(of:) { v in }` | `onChange(of:) { _, v in }` | 23 | 9 files — AddEventSheet (8), SettingsList (7) |
| `PreviewProvider` | `#Preview { }` | 18 | app-wide |
| `.navigationBarLeading/Trailing` | `.topBarLeading/.topBarTrailing` | 13 | PenPalSplitView, PenPalTab, four sheets |
| `showsIndicators: false` | `.scrollIndicators(.hidden)` | 4 | StatsView, AddEventSheet ×2, EventCell |
| `cornerRadius(_:)` | `clipShape(.rect(cornerRadius:))` | 3 | SymbolPicker, AddEventSheet, EventCell |
| `Color(uiColor: UIColor.x)` | `Color(.x)` | 3 | AppInfo, SettingsList, AddEventSheet |
| `DispatchQueue.main.async` in `.task` | direct assignment | 30+ | StatsView (6), SettingsList (3), charts, TipJarView |

Note: `PenPalTab.swift:46` and `PenPalView.swift:234` already use `.topBarLeading`/`.topBarTrailing` while siblings in the same files don't — drift, not a style choice.

---

## Moving to `@Observable`

All four observable classes are iOS 17-compatible.

- **`Views/Navigation/AppRouter.swift:45` — `Router`.** Clearest win: `ObservableObject` publishes at object granularity, so a `presentedSheet` change invalidates everything watching `path` too. Migration: `@Observable` + `@State` for ownership + `@Environment(Router.self)` for passing.
- **`Helpers/Orientation.swift:17` — `OrientationObserver`.** Combine sink captures `self` strongly and mutates `@Published` on an arbitrary queue. Singleton so nothing leaks, but unsafe under strict concurrency. Replace with `NotificationCenter.notifications(named:)` + `for await` on `@MainActor`.
- **`Data/SyncMonitor.swift:35` — `SyncMonitor`.** Same shape. Plus a dead `if #available(iOS 14.0, *)` at `:44` against a 17.0 target.
- **`Helpers/ImageViewerController.swift:24`.** Straightforward. Note `urls` calls `item.temporaryURL()` per image on every access — writes files to disk from a getter that `QLPreviewCoordinator` reads per item. Worth caching.

---

## Test coverage

No test target exists. Two areas are pure logic worth covering:

| Target | Why | Cases |
|---|---|---|
| `Model/EventType.swift` — `nextLogicalEventTypes`, `groupingEventType` | Every list section, header and action button derives from these. Both branch on `trackPostingLetters`, so each has two behaviours that must stay consistent. Regressions are invisible until a user reports wrong buttons. | ~24 (9 types × 2 modes) |
| `Data/PenPal+Extensions.swift:533` — `averageTimeToRespond` | Pairs received events with the next written/sent, skipping ignored, with a special case for a still-unanswered last letter. Easy to get subtly wrong. | ~8 |
| `Extensions/Calendar.swift` — `numberOfDaysBetween` | Used for every date divider and "N days ago" subheader. DST and timezone changes are the classic failure mode. | ~6 |

**Secrets:** none checked in. `@AppStorage` holds only preferences and the pen-pal → contact ID map.
