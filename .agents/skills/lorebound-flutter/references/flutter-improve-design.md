# UI/UX Design Catalog — Velastra Adapted

> Adapted from [flutterskills.md](https://flutterskills.md) by [@kamranbekirovyz](https://x.com/kamranbekirovyz).
> Each rule carries a **Link** to its original article for deeper context.
> Rules are filtered and adapted for the Velastra industrial IoT app — mining operators, sensor dashboards, GPS tracking.

---

## 1. Load network images smoothly

**Link:** https://flutterpro.design/details/md/smooth-image-loading

**Why:** Images in Flutter load with no transition, no placeholder and no failure state. They just pop in. Show a plain grey box until each picture is ready and fade it in. If it fails, show a subtle broken-image icon — never a technical message.

**Apply when:** Any `Image.network`, `CachedNetworkImage`, or `NetworkImage` usage — device photos, region maps, profile avatars.

**Pattern:**
```dart
// ✅ Smooth loading with placeholder + error + fade
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (_, __) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
  ),
  errorWidget: (_, __, ___) => Icon(
    Icons.broken_image_outlined,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
  fadeInDuration: const Duration(milliseconds: 300),
)

// ❌ Raw pop-in with no states
Image.network(imageUrl)
```

**Hunt:** grep `Image.network|NetworkImage|CachedNetworkImage` — any without placeholder + error + fade is a match.

---

## 2. Never show "null" on screen

**Link:** https://flutterpro.design/details/md/never-show-null

**Why:** When a sensor field comes back `null` or empty from the API and gets displayed directly, the operator sees "null" or a blank spot. Gate ALL display values through a shared helper covering `null`, `"null"` as a serialized string, and empty string.

**Apply when:** Any text displaying API-backed data — sensor readings, device names, operator info, timestamps.

**Pattern:**
```dart
// ✅ Shared extension — use everywhere
extension StringDisplay on String? {
  String get orPlaceholder {
    if (this == null || this!.isEmpty || this!.toLowerCase() == 'null') {
      return '—';
    }
    return this!;
  }
}

// Usage
Text(device.operatorName.orPlaceholder)
Text(sensor.lastReading.orPlaceholder)

// ❌ Scattered null checks that miss edge cases
Text(device.operatorName ?? '-')  // misses "null" string and empty
```

**Hunt:** grep `orPlaceholder|isUsable|!= 'null'` — nothing found means the app needs it.

---

## 3. Format numbers for user's locale

**Link:** https://flutterpro.design/details/md/format-numbers-for-humans

**Why:** A raw `1234567` is hard to read. Sensor readings, distances, and fuel values should be formatted for the user's locale: `1,234,567` in the US, `1.234.567` in Germany.

**Apply when:** Any numeric display — speed values, fuel readings, distances, device counts, coordinates.

**Pattern:**
```dart
// ✅ Locale-aware formatting
import 'package:intl/intl.dart';

Text(NumberFormat.decimalPattern().format(sensor.distance))
Text(NumberFormat.compact().format(deviceCount))

// ❌ Raw values
Text(sensor.distance.toString())
Text('${sensor.fuelLevel}')
```

**Hunt:** grep `NumberFormat|decimalPattern|compact(` — nothing found, then grep `.toString()` or `${}` with numeric values near `Text(`.

---

## 4. Format dates for user's locale

**Link:** https://flutterpro.design/details/md/format-date-times

**Why:** `2016-06-24 14:44:00.000` is what `DateTime` prints. Show `24 July 2016, 14:44` instead, in the user's language.

**Apply when:** Any timestamp display — last seen time, trip start/end, sensor data timestamps.

**Pattern:**
```dart
// ✅ Locale-aware date formatting
import 'package:intl/intl.dart';

Text(DateFormat.yMMMd().add_Hm().format(sensor.lastUpdate))
// → "Jul 24, 2016, 14:44"

// ❌ Raw DateTime
Text(sensor.lastUpdate.toString())
Text('${date.day}/${date.month}/${date.year}')
```

**Hunt:** grep `DateFormat` — if there's a shared helper used everywhere, it's handled. Otherwise grep `DateTime` near `Text(` for raw display.

---

## 5. Dismiss the keyboard when the user scrolls

**Link:** https://flutterpro.design/details/md/dismiss-keyboard-on-scroll

**Why:** The operator finishes typing and scrolls to see the rest, but the keyboard stays covering half the screen. Scrolling means they're done — close it for them.

**Apply when:** Any scrollable that contains text fields — settings forms, search screens, login/register.

**Pattern:**
```dart
// ✅ Keyboard dismisses on scroll
ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  children: [
    TextFormField(...),
    // ...
  ],
)

// ❌ Keyboard stays open while scrolling
ListView(
  children: [
    TextFormField(...),
    // ...
  ],
)
```

**Hunt:** grep `TextField|TextFormField` and check if the enclosing scrollable sets `keyboardDismissBehavior`. First one without it is a match.

---

## 6. Autofocus the field when the page has only one

**Link:** https://flutterpro.design/details/md/autofocus-single-field

**Why:** A page that exists to collect one input (OTP, phone number, change email) makes the user tap the field first. Focus it on open — the keyboard is up, they type and move on.

**Apply when:** OTP verification, single-input edit pages (change email, change phone), search screens.

**Pattern:**
```dart
// ✅ Auto-focused single field
TextFormField(
  autofocus: true,
  // ...
)

// ❌ User has to tap the field first
TextFormField(
  // no autofocus
)
```

**Hunt:** grep `otp|Otp|OTP|verification|change_email|change_phone|forgot_password` and check for `autofocus: true`.

---

## 7. Show the app version in settings

**Link:** https://flutterpro.design/details/md/show-app-version

**Why:** When a field operator reports a bug, the first question is which version they're on. The app needs a place to answer that.

**Apply when:** Settings screen, about page, or any user-accessible info area.

**Pattern:**
```dart
// ✅ Display version + build number
final info = await PackageInfo.fromPlatform();
Text('v${info.version} (${info.buildNumber})')
```

**Hunt:** grep `PackageInfo|package_info_plus|buildNumber` — nothing found means the app is missing it.

---

## 8. Add haptic feedback to key moments

**Link:** https://flutterpro.design/details/md/haptic-feedback

**Why:** The app feels flat when taps and results happen in silence. A subtle vibration on a tab switch, a successful submit, or an error makes the app feel responsive.

**Apply when:** Tab bar switches, form submits (login, register), error snackbars, toggle switches, long-press actions.

**Pattern:**
```dart
import 'package:flutter/services.dart';

// ✅ Tab switch
onTap: (index) {
  HapticFeedback.lightImpact();
  setState(() => _currentIndex = index);
}

// ✅ Successful submit
await submitForm();
HapticFeedback.mediumImpact();

// ✅ Error
showSnackBar(errorMessage);
HapticFeedback.heavyImpact();
```

**Hunt:** grep `HapticFeedback|vibrate` to see what's covered. Then check `BottomNavigationBar`, `SnackBar`, `Switch`, `Checkbox` for missing haptics.

---

## 9. Use tabular figures for changing numbers

**Link:** https://flutterpro.design/details/md/tabular-figures

**Why:** Digits have different widths in most fonts, so a speed reading or timer jumps around as it changes. Tabular figures make every digit the same width — numbers stay still.

**Apply when:** Speed displays, fuel gauges, counters, sensor readings — any number that updates live.

**Pattern:**
```dart
// ✅ Stable changing numbers
Text(
  '${speed.toStringAsFixed(1)} km/h',
  style: TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)

// ❌ Numbers that jitter as they change
Text('${speed.toStringAsFixed(1)} km/h')
```

**Hunt:** grep `tabularFigures` — if used where numbers change, nothing to flag. Otherwise grep `Timer|Stopwatch|speed|fuel|count|total` near `Text(` for changing numbers without the feature.

---

## 10. Don't let the system nav bar cover scrollable lists

**Link:** https://flutterpro.design/details/md/safe-area-replacement

**Why:** The last item of scrollable lists gets obscured by the system navigation bar. Leave dynamic space based on the device's actual bar height.

**Apply when:** Any vertical scrollable that runs to the bottom of the screen — device lists, sensor data, reports.

**Pattern:**
```dart
// ✅ Dynamic bottom padding from device
ListView.builder(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.md,
  ),
  itemCount: devices.length,
  itemBuilder: (_, i) => DeviceTile(device: devices[i]),
)

// ❌ SafeArea shrinks the scrolling area
SafeArea(
  child: ListView.builder(...),
)

// ❌ Fixed padding ignores device differences
ListView.builder(
  padding: const EdgeInsets.only(bottom: 24),
  ...
)
```

**Hunt:** grep `ListView|SingleChildScrollView|CustomScrollView|GridView` and check for dynamic bottom padding via `viewPadding.bottom`.

---

## 11. Give every text field the right keyboard action

**Link:** https://flutterpro.design/details/md/text-input-action

**Why:** Operators should fill a form using only the keyboard action key — it moves to the next field, and the last one submits. No tapping each field by hand.

**Apply when:** Any form with 2+ text fields — login, register, settings, device config.

**Pattern:**
```dart
// ✅ Chained form fields
TextFormField(
  textInputAction: TextInputAction.next,  // moves to next field
  // ...
),
TextFormField(
  textInputAction: TextInputAction.done,  // submits form
  onFieldSubmitted: (_) => _submitForm(),
),
```

**Hunt:** find files with 2+ `TextField|TextFormField`. Check for `textInputAction` — a multi-field form without it is a match.

---

## 12. Match text selection to your app's colors

**Link:** https://flutterpro.design/details/md/selection-color

**Why:** `MaterialApp` applies default tinted colors for text selection. Match them to Velastra's brand instead.

**Apply when:** App-wide theme setup — set once in `ThemeData`.

**Pattern:**
```dart
// ✅ In ThemeData
ThemeData(
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: colorScheme.primary,
    selectionColor: colorScheme.primary.withOpacity(0.3),
    selectionHandleColor: colorScheme.primary,
  ),
)
```

**Hunt:** grep `textSelectionTheme` — nothing found means the app uses defaults.

---

## 13. Make the whole GestureDetector area tappable

**Link:** https://flutterpro.design/details/md/gesture-detector-hit-area

**Why:** By default `GestureDetector` only takes taps on painted pixels, so padding and gaps between an icon and text do nothing. The operator taps the row and misses.

**Apply when:** Any `GestureDetector` wrapping a `Row`, `Column`, or `Container` with padding/gaps.

**Pattern:**
```dart
// ✅ Entire area is tappable
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => _openDetails(device),
  child: Row(
    children: [Icon(...), SizedBox(width: AppSpacing.sm), Text(...)],
  ),
)

// ❌ Only painted pixels register taps
GestureDetector(
  onTap: () => _openDetails(device),
  child: Row(...),
)
```

**Hunt:** grep `GestureDetector` and check for `behavior:`. One without `HitTestBehavior.opaque` or `.translucent`, whose child has gaps, is a match.

---

## 14. Limit text scaling so layouts don't break

**Link:** https://flutterpro.design/details/md/text-scale-factor

**Why:** Some operators increase device text size for readability. At high scales, layouts overflow and break. Cap the scale app-wide.

**Apply when:** App-wide — set once in `MaterialApp.builder`.

**Pattern:**
```dart
// ✅ Cap text scale in MaterialApp
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.3,
        ),
      ),
      child: child!,
    );
  },
)
```

**Hunt:** grep `textScaler|textScaleFactor` — nothing found means the app doesn't limit it.

---

## 15. Show a friendly view when a widget breaks

**Link:** https://flutterpro.design/details/md/friendly-error-view

**Why:** When a widget fails to build in release, operators see an empty grey box. Show a friendly "Something went wrong" in the app's own colors instead.

**Apply when:** App-wide — set once in `main()`.

**Pattern:**
```dart
// ✅ In main() before runApp()
ErrorWidget.builder = (details) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('Something went wrong',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
};
```

**Hunt:** grep `ErrorWidget.builder` — nothing found means the app shows the default grey box.

---

## 16. Scroll to top when the current bottom nav item is tapped again

**Link:** https://flutterpro.design/details/md/bottom-nav-reselect

**Why:** Tapping the bottom nav item you're already on should scroll that page to the top. It's muscle memory for native app users.

**Apply when:** Any screen with a bottom navigation bar.

**Pattern:**
```dart
// ✅ Handle reselect
onTap: (index) {
  if (index == _currentIndex) {
    // Scroll to top
    _scrollControllers[index].animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  } else {
    setState(() => _currentIndex = index);
  }
}
```

**Hunt:** grep `BottomNavigationBar|NavigationBar` and check for a same-index branch that scrolls to top.

---

## 17. Show scrollbars on vertical scrollables

**Link:** https://flutterpro.design/details/md/scrollbars

**Why:** A scrollbar shows the operator where they are in the list and how much is left. Essential for long device lists and reports.

**Apply when:** Any vertical scrollable with enough content to scroll — device lists, sensor data tables, reports.

**Pattern:**
```dart
// ✅ Wrapped in Scrollbar
Scrollbar(
  child: ListView.builder(
    itemCount: devices.length,
    itemBuilder: (_, i) => DeviceTile(device: devices[i]),
  ),
)

// ❌ No scroll position indicator
ListView.builder(
  itemCount: devices.length,
  itemBuilder: (_, i) => DeviceTile(device: devices[i]),
)
```

**Hunt:** grep `ListView|SingleChildScrollView|CustomScrollView|GridView` and check for a wrapping `Scrollbar`.

---

## 18. Unfocus the text field before opening a modal

**Link:** https://flutterpro.design/details/md/unfocus-before-modal

**Why:** Opening a modal while a text field is focused brings the keyboard back when the modal closes. Unfocus before opening.

**Apply when:** Any screen where a text field exists alongside a modal trigger (date picker, bottom sheet, dialog).

**Pattern:**
```dart
// ✅ Unfocus before opening
onTap: () {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet(...);
}

// ❌ Keyboard comes back after modal closes
onTap: () {
  showModalBottomSheet(...);
}
```

**Hunt:** grep `showModalBottomSheet|showDialog|showDatePicker` in files that also have `TextField|TextFormField`.

---

## 19. Reserve space for images before they load

**Link:** https://flutterpro.design/details/md/reserve-image-space

**Why:** A network image has no size until its bytes arrive. When it loads, it snaps to its real height and pushes everything below down. Size the box before the image arrives.

**Apply when:** Any network image in a list or content layout.

**Pattern:**
```dart
// ✅ Fixed aspect ratio reserves space
AspectRatio(
  aspectRatio: 16 / 9,
  child: CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    // ... placeholder and error
  ),
)

// ❌ Size snaps on load, layout jumps
CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
)
```

**Hunt:** grep `Image.network|CachedNetworkImage` — check for `AspectRatio`, explicit width+height, or height-bounding parent.
