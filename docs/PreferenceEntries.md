# Preference Entries

This document describes the current preference-entry pattern used by the `Windscribe/Features` preference screens and the shared `MenuEntryView` components.

## Core components

### `MenuEntryItemType`

`MenuEntryItemType` is the smallest row contract. It describes the visible content and optional behaviour for a row-like item:

- `id`: stable identifier used by `ForEach` and action routing.
- `title`: left-side title. Can be empty for secondary info rows or icon-only actions.
- `icon`: left-side image asset. Can be empty.
- `iconSize`: per-entry icon size. The protocol extension defaults this to `defaultIconSize` (`16`), so ordinary preference entries do not need to declare it. Category-style entries such as `PreferencesMainEntryType` can override it (`23`).
- `action`: optional `MenuEntryActionType` describing how `MenuEntryActionView` should render and what response it should emit.
- `useOriginalIconRendering`: opt-in when an icon should not be template-tinted.

Secondary rows conform to this protocol directly. `MenuSecondaryEntryItem` copies the source entry's `iconSize`, so secondary rows preserve custom sizing when needed.

### `MenuEntryHeaderType`

`MenuEntryHeaderType` extends `MenuEntryItemType` for top-level preference cards:

- `message`: optional descriptive text shown under an interactive header or at the trailing side for non-interactive info rows.
- `secondaryEntries`: nested `MenuSecondaryEntryItem` rows rendered under the header with optional separators.

Top-level screen enums such as `GeneralMenuEntryType`, connection entry types, `RobertEntryType`, and `PreferencesMainEntryType` conform to this protocol.

### `MenuEntryActionType` → `MenuEntryActionResponseType`

`MenuEntryActionType` is a view-rendering input. `MenuEntryActionResponseType` is the callback emitted back to the view model.

Current behaviours:

- `.multiple(currentOption:options:parentId:)`: shows a dropdown action and emits `.multiple(newOption:parentId:)`.
- `.toggle(isSelected:parentId:)`: shows switch art and emits `.toggle(isSelected:parentId:)` with the inverted value.
- `.button(title:parentId:)`: makes the row tappable and emits `.button(parentId:)`. It is implemented as the default-tinted version of `MenuTintedButtonActionView` (`.titleColor`) and shows the normal disclosure icon.
- `.tintedButton(title:tintColor:parentId:)`: makes the row tappable, applies the supplied tint/background styling, and emits `.button(parentId:)`. This is for button rows whose tint/background differs from the default, currently the destructive Preferences logout row.
- `.none(title:parentId:)`: renders a non-icon text action and emits `.none(parentId:)`.
- `.link(title:parentId:)`: renders the external-link icon and emits `.link(parentId:)`.
- `.infoLink(message:parentId:)`: renders descriptive/info text as an action and emits `.infoLink(parentId:)`.
- `.field(value:placeHolder:parentId:)`: renders editable field-style content and emits `.field(value:parentId:)`.
- File actions (`.file`, `.buttonFile`, `.buttonFileExport`) render edit/navigation affordances and emit the matching file/export responses.

The `parentId` is important: a callback from a secondary row arrives through the same `MenuEntryView` callback as the parent card, so the view model uses the `parentId` to decide whether the interaction belonged to the header or a secondary entry.

### `MenuEntryTintColor`

`MenuEntryTintColor` centralizes tint/background colours for button-like rows:

- `.titleColor`: the default button/category-row tint. Used by `.button` through `MenuButtonActionView`.
- `.deepOrange`: destructive/logout tint. Used by `.tintedButton` for Preferences logout.

Important rule: conceptually, every `.button` is a `.tintedButton` with the default `.titleColor` tint and normal disclosure affordance. Keep `.button` for the common/default case and use `.tintedButton` only when a row needs non-default tint/background treatment.

### `MenuEntryView`

`MenuEntryView` renders one `MenuEntryHeaderType` card:

- If the entry has either an action or secondary entries, it uses `MenuEntryInteractiveView`.
- If the entry has no action and no secondary entries, it uses `MenuEntryInfoView`.
- Header actions with `.button` or `.tintedButton` wrap the header in a `Button` and emit `.button(parentId:)`.
- Secondary entries are rendered in the same card below the header and share the same callback.
- The card background can be overridden by `item.action?.backgroundColor(...)`; otherwise it uses the normal menu background.
- The header icon uses `item.iconSize`, so screens can opt into category-sized icons without a separate row component.

### `PreferencesContentView`

`PreferencesContentView<Entry: MenuEntryHeaderType>` is the screen-level list wrapper for plain preference-detail screens:

```swift
PreferencesContentView(entries: viewModel.entries) { entry, action in
    viewModel.entrySelected(entry, action: action)
}
.task {
    await viewModel.startObservers()
}
```

Use this when the whole screen can be expressed as a list of `MenuEntryHeaderType` cards.

## General screen pattern

`GeneralScreen` is the simplest target shape:

- The screen reads dependencies from `@Environment` and constructs `GeneralViewModel`.
- The content view owns the view model in `@State`.
- `GeneralViewModel.entries` maps current state into `[GeneralMenuEntryType]`.
- `GeneralMenuEntryType` encodes row identity, copy, icons, descriptions, and behaviour.
- `PreferencesContentView` renders the entries and forwards all row actions back to `viewModel.entrySelected`.
- `startObservers()` updates private state from async streams; because `entries` is computed, the visible rows refresh from the current state.

Current General entry behaviours:

- `locationOrder`: `.multiple`; writes the selected location order.
- `language`: `.multiple`; sets active language.
- `locationLoad`: `.toggle`; writes show-server-net-load.
- `hapticFeedback`: `.toggle`; writes haptic preference.
- `notification`: `.none`; opens system/app notification settings.
- `version`: no action; rendered as an info row with the app version as message.

This is the reference pattern for ordinary preference-detail screens.

## Connection screen pattern

`ConnectionScreen` uses the same `PreferencesContentView` shape, but proves that the entry model can support richer cards:

- Top-level entries conform to `MenuEntryHeaderType`.
- Secondary rows conform to `MenuEntryItemType` and are wrapped into `MenuSecondaryEntryItem`.
- Some entries conditionally expose secondary rows based on current state.
- Navigation and sheets remain screen-owned state instead of being hidden inside `MenuEntryView`.

Current Connection entry behaviours:

- `networkOptions`: `.button` header row, with a secondary info row.
- `antiCensorshipOptions`: `.button` header row.
- `connectionMode`: `.multiple`; when manual, secondary protocol and port `.multiple` rows appear.
- `ipStack`: `.none` header; secondary info plus egress `.multiple` row.
- `connectedDns`: `.multiple`; when custom, secondary field row appears.
- `alwaysOn`: `.toggle` with message text.
- `allowLan`: `.toggle` with secondary info row.

Subscreens follow the same pattern:

- `AntiCensorshipScreen`: list of `AntiCensorshipOptionsEntryType`, conditional secondary rows, info-link sheet routing.
- `NetworkSettingsScreen`: list of `NetworkSettingsEntryTpe`, conditional secondary protocol/port rows.
- `NetworkOptionsScreen`: mostly uses `MenuEntryView`, but is not fully reducible to `PreferencesContentView` yet because it has visible section labels (`Current Network`, `All Networks`) and optional grouped entries.

## Preferences main screen pattern

`PreferencesMainScreen` now uses the same entry abstraction as the detail screens:

- `PreferencesMainEntryType` conforms to `MenuEntryHeaderType`.
- Normal main-menu rows use `.button(title: "", parentId: id)`, which is the default-tinted button path.
- `logout` uses `.tintedButton(title: "", tintColor: .deepOrange, parentId: id)`, which applies the destructive tint/background and does not show the normal disclosure icon.
- `PreferencesMainEntryType.iconSize` overrides the default icon size to `23`, matching the old category-row visual weight.
- The screen still owns route state, confirmation sheet state, logout alert state, and bottom action buttons because those are screen-level behaviours rather than row-rendering behaviours.

This keeps Preferences main on the shared `MenuEntryView` path while preserving the visual exceptions that previously required `MenuCategoryRowType`.

Current Preferences main entry behaviours:

- `general`, `account`, `connection`, `robert`, `referForData`, `lookAndFeel`, `helpMe`, `about`, `screenTest`: `.button(title: "", parentId: id)`; route through `PreferencesRouteID`.
- `logout`: `.tintedButton(title: "", tintColor: .deepOrange, parentId: id)`; opens the logout confirmation alert.

The screen renders entries directly with `MenuEntryView` instead of wrapping them in `Button` manually:

```swift
ForEach(viewModel.visibleItems, id: \.id) { item in
    if !viewModel.shouldHideRow(item: item) {
        MenuEntryView(item: item) { _ in
            handleEntrySelection(item)
        }
    }
}
```

## Findings from the Preferences main migration

- `MenuCategoryRowType` was effectively a narrower `MenuEntryHeaderType` for category buttons. Migrating Preferences main to `MenuEntryHeaderType` removed that separate abstraction from the new screen path.
- The only real visual exception was logout: same row structure, but centered/destructive, no disclosure arrow, and a custom tint/background. `tintedButton` captures that exception without making every category row unique.
- The normal `.button` path should be treated as the default-tinted button path. Use `.button` first; reach for `.tintedButton` only when the colour/background needs to differ.
- Icon size belongs on the entry contract, not inside a one-off category-row view. This lets category-sized rows and ordinary 16pt setting rows share `MenuEntryView`.
- Tests exposed why `iconSize` needs a protocol-extension default: lightweight conformers and test stubs should not be forced to restate the default value.

## How to add a new preference screen

1. Add an entry enum that conforms to `MenuEntryHeaderType`.
2. Put user-visible state in associated values, not inside the view.
3. Build `var entries: [Entry]` in the view model from the current observed state.
4. Use `MenuEntryActionType` only to describe UI behaviour; do writes/navigation in `entrySelected` or the screen-level selection handler.
5. Use `.button` for default-tinted tappable rows. Use `.tintedButton` only for non-default tint/background treatment.
6. For nested controls, add a secondary enum conforming to `MenuEntryItemType`, then wrap with `MenuSecondaryEntryItem`.
7. In `entrySelected`, switch on both the parent entry and the `MenuEntryActionResponseType.parentId` when secondary rows need different handling.
8. Render with `PreferencesContentView(entries: viewModel.entries)` whenever the whole screen is a plain preference-card list; render `MenuEntryView` directly when the screen also has extra non-list UI such as bottom action buttons.
