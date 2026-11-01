# Lorebound

A lightweight, offline-first EPUB and webnovel reader built with Flutter.

Lorebound is designed for distraction-free reading. It works fully offline using local SQLite storage—no account, login, or internet connection required. Pick an EPUB from your device and start reading.

Optional cloud sync with [Lorekeeper](https://github.com/TheNirajMahale/lorekeeper-api) is available if you want to back up books or sync progress across devices, but it remains strictly optional.

---

## Features

- **Reading Modes:** Paginated mode for traditional ebooks or vertical continuous scroll for webnovels. Remembers your exact position when switching.
- **Offline Dictionary:** Fast local dictionary powered by SQLite with pre-seeded words and offline caching for new lookups.
- **Text Selection:** Floating card with instant word definitions, auto-lookup, and quick copy/select-all toolbar. Selection pins cleanly hide when expanding the definition card.
- **Reading Aids:** Bionic reading mode and customizable reading tools.
- **Auto-Scroll:** Hands-free scrolling with adjustable speed for vertical reading.
- **Reading Stats:** Track reading speed (WPM), reading time, active days, and view stalled books.
- **Search:** Search within the current chapter or search across the entire book.
- **Typography & Themes:** 5 color themes (Light, Sepia, Grey, Dark, OLED Black) and custom reader fonts (Merriweather, Literata, Atkinson Hyperlegible).
- **Optional Cloud Sync:** Sync reading progress and back up books to your personal Lorekeeper server.

---

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift & SQLite
- **EPUB Engine:** Native Flutter render engine (no WebViews)
- **Networking & Storage:** Dio + Flutter Secure Storage

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

For architecture notes and detailed roadmaps, see [Docs](docs/Lorebound.md).
