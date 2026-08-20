# Lorebound

Lorebound is a premium, offline-first ebook reader and reading tracker built with Flutter. It features a custom 100% native render engine for EPUBs, offering both infinite vertical scroll and paginated reading modes with an immersive, distraction-free UI. 

Currently, Lorebound operates as a powerful standalone offline reader. In the future, it will serve as the mobile frontend for the **Lorekeeper API** (a private reading cloud backend) and **RuneGlass** (reading assistance module).

## Key Features

- **100% Native Render Engine:** No WebViews. EPUBs are parsed directly into native Flutter widgets for absolute control over performance, typography, and layout.
- **Dual Reading Modes:** Choose between Paginated (traditional ebook) and Vertical Scroll (webnovel style).
- **Immersive HUD:** Pure overlay architecture that never shifts or reflows your text when opening menus.
- **Local Library Management:** Import EPUBs directly from your device, track your reading progress, and manage your collection offline.
- **Highly Customizable:** Multiple theme presets (including true AMOLED black), font choices, and typography controls.

## Getting Started

To run Lorebound locally:

```bash
# Clone the repository
git clone https://github.com/yourusername/lorebound.git

# Navigate to the directory
cd lorebound

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Documentation

For a deep dive into the project's architecture, roadmap, and development standards, please refer to the comprehensive [Project Documentation](docs/Lorebound.md).
