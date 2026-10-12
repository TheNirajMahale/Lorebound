# Lorebound

> A lightweight, distraction-free, offline-first EPUB and webnovel reader built with native Flutter.

Lorebound is a simple ebook reader designed for long-form reading. It runs completely offline with a local SQLite database — no account, login, or internet connection required. Pick an EPUB from your storage and start reading immediately.

Cloud sync with the [**Lorekeeper API**](https://github.com/TheNirajMahale/lorekeeper-api) will be added later for multi-device reading, but account creation will always remain optional.

---

## Features

- **Paginated & Vertical Scroll:** Read page-by-page or with continuous vertical scroll for webnovels. Remembers your exact paragraph when switching modes.
- **Auto-Scroll:** Hands-free vertical scrolling with a floating pause/speed controller.
- **Reading Statistics:** Track reading speed (WPM), total time read, active days, peak reading hours, and a shelf for books untouched for over a week.
- **Search:** Search inside the active chapter (anchored above the keyboard) or search across all chapters from the book detail page.
- **Typography & Themes:** Custom font sizes, line spacing, book fonts (Merriweather, Literata, Atkinson Hyperlegible), and 5 themes (Light, Sepia, Grey, Dark, OLED Black).
- **100% Offline & Private:** Books, history, and reading sessions stay on your device in a local SQLite database.

---

## Tech Stack

- **Framework:** Flutter (3.24+)
- **State Management:** Riverpod
- **Database:** Drift (SQLite)
- **EPUB Parsing:** `epubx` + native Flutter widgets
- **Routing:** `go_router`
- **Networking (Optional Cloud):** `dio` + `flutter_secure_storage`

---

## Getting Started

```bash
git clone https://github.com/TheNirajMahale/lorebound.git
cd lorebound
flutter pub get
flutter run
```

---

## Documentation

For architectural notes, API contracts, and the development roadmap, see [Project Documentation](docs/Lorebound.md).
