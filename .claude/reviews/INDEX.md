# Pendulum code reviews

Reference material for future sessions. Not part of the app target — `.claude/` is untracked.

---

## 2026-08-25 — SwiftUI review (`/swiftui-pro`)

| | |
|---|---|
| **Artifact** | https://claude.ai/code/artifact/9dfc9504-c75a-462c-9370-37c569a6735a |
| **Readable report** | [`2026-08-25-swiftui-review.md`](2026-08-25-swiftui-review.md) |
| **Structured index** | [`2026-08-25-findings.json`](2026-08-25-findings.json) — grep by `file`, `line`, `id`, `severity`, `category` |
| **Artifact source** | [`2026-08-25-swiftui-review.html`](2026-08-25-swiftui-review.html) — republish this exact path to update the artifact in place |
| **Reviewed at** | branch `stationery-list-toolbar`, commit `6ef28a0` |
| **Scope** | 79 Swift files, ~10,300 lines. iOS 17.0 target, Swift 5.0, strict concurrency off, no test target |
| **Totals** | 65 findings — 9 high, 28 medium, 28 low (57 individual + 8 cross-cutting sweeps) |

### Status: top 5 fixed on branch `review-fixes` (5 commits, each build-verified)

### Top of the queue

1. `EventCell.swift:206` — force-unwrapped URL from a user-typed tracking reference (**crash**)
2. `PersistenceController.swift:106` — `save(context:)` ignores its parameter
3. `PenPal+Extensions.swift:479` — managed objects read off their owning queue
4. `AppPreferences.swift:15` — `@AppStorage` in an `ObservableObject` doesn't publish
5. `PenPalListSection.swift:208` — N confirmation dialogs on one shared boolean
6. `SettingsList.swift:297` — device-motion updates never stopped

### Using this later

- Line numbers are from 2026-08-25. **Verify before acting** — check `git log --since=2026-08-25 -- <file>` first.
- Nothing here has been fixed yet. When findings are addressed, add an `outcome` field to the JSON entry rather than deleting it, so the history stays legible.
- To refresh the artifact after fixes: edit `2026-08-25-swiftui-review.html` and republish **the same path** — it keeps the URL above.
- The JSON `priority` array carries three aggregate ids (`a11y-dynamic-type-voiceover`, `sweep-deprecated-api`, `oversized-view-files`) that intentionally have no matching `findings` entry; they group several individual findings each.
