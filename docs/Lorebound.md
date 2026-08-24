# Lorebound

## 1. Project Overview
**Lorebound** is a personal ebook reader and reading tracker app built with Flutter. It serves as the user-facing frontend for the [**Lorekeeper API**](https://github.com/TheNirajMahale/lorekeeper-api) (Private Reading Cloud backend) and the **RuneGlass** reading-assistance module.

### Vision
A premium, offline-first ebook reader with cloud sync. Users can import EPUBs locally, read with a fully customizable native reader engine, track their progress, and optionally sync everything to their private Lorekeeper server.

### Project Ecosystem

| Project | Name | Role |
|---|---|---|
| Backend API | [**LoreKeeper**](https://github.com/TheNirajMahale/lorekeeper-api) | Private book library + reading tracker + reading assistance APIs |
| Reading Module | **RuneGlass** | Bionic highlighting, dictionary lookup, PDF extraction (Lorekeeper sub-module) |
| Mobile App | **Lorebound** | Flutter reader app consuming Lorekeeper's APIs |

---

## 2. Architecture & Structure

The project follows a **Layered Feature-First Architecture**. Each feature is self-contained with its own data, domain, and presentation layers. 

### Pattern Per Feature
```text
lib/
├── core/                          # Shared infrastructure
│   ├── constants/                 # App-wide constants (API base URLs, keys)
│   ├── routing/                   # GoRouter configuration and route definitions
│   ├── services/                  # Core cross-cutting services (ApiService, AuthInterceptor)
│   ├── theme/                     # ColorScheme, Typography, Spacing, Presets
│   └── utils/                     # Generic helpers (formatters, extensions)
│
├── features/                      # Feature modules
│   └── [feature_name]/
│       ├── data/                  # Data layer: API calls, local DB queries, parsers
│       │   ├── repositories/      # Repository implementations
│       │   └── services/          # Feature-specific services (e.g., EpubParserService)
│       ├── domain/                # Domain layer: Pure models, business logic
│       │   └── models/            # Data classes (ReaderConfig, Book, etc.)
│       └── presentation/          # Presentation layer: UI + state
│           ├── providers/         # Riverpod Notifiers / AsyncNotifiers
│           ├── screens/           # Full-page screen widgets
│           └── widgets/           # Feature-specific reusable widgets
│
├── shared/                        # Reusable widgets across features
│   └── widgets/                   # Common UI components (loading indicators, error cards)
│
└── main.dart                      # App entry point
```

### Key Architectural Principles
- **Data Layer** → talks to APIs, databases, file system. Returns domain models.
- **Domain Layer** → pure Dart. No Flutter imports. Models, business rules.
- **Presentation Layer** → Flutter widgets + Riverpod providers. Consumes domain models.

---

## 3. Tech Stack & State Management

| Category | Technology | Reason |
|---|---|---|
| **Framework** | Flutter | Cross-platform mobile |
| **State Management** | `flutter_riverpod` (v3.x) | Modern, compile-safe, scoped providers |
| **Local Database** | `drift` (SQLite) | Relational queries, schema migrations, actively maintained |
| **Networking** | `dio` | Interceptors for auth, retry logic, better error handling |
| **Routing** | `go_router` | Official Flutter team router, deep linking, auth guards |
| **EPUB Parsing** | `epubx` + `html` | We use a custom **Native Render Engine**! We parse the EPUB internally, chunk the HTML, and map it directly to native Flutter Text/Image widgets for absolute control over performance, layout, and UI. No WebViews! |
| **Secure Storage** | `flutter_secure_storage` | JWT token persistence |
| **File Picking** | `file_picker` | Local EPUB import |
| **File Storage** | `path_provider` | App document directory for cached EPUBs |

### State Management Approach
1. **Providers:** All state lives in Riverpod `Notifier` or `AsyncNotifier` classes.
2. **Dependency Injection:** Services (parsers, repositories, API clients) are provided via `Provider` — never instantiated directly inside controllers.
3. **Rebuilds:** UI components use `ConsumerWidget` or tightly scoped `Consumer` blocks to minimize wasted rebuilds.
4. **Async Handling:** Rely on Riverpod's `AsyncValue` to handle loading/error/data states for all API and DB calls.
5. **Model Separation:**
   - `ReaderBook` → in-memory parsed EPUB (full HTML content of every chapter). Used only inside the Reader feature.
   - `Book` → lightweight metadata model (title, author, cover path, progress %). Used in Library grids and lists.

---

## 4. Reader Engine — Feature Specification

The Reader is the core feature of Lorebound. It provides a premium, distraction-free native reading experience with zero WebViews.

### 4.1 Dual Reading Modes

| Mode | Description |
|---|---|
| **Vertical Scroll** | Webnovel-style infinite scroll. Chapters flow vertically, with horizontal swiping to jump between chapters. Includes an immersive Top/Bottom custom HUD with scroll-activated gradients. |
| **Paginated** | Traditional ebook mode. Content is intelligently chunked into exact physical screen bounds via binary search layout measurement. Swipe left/right to turn pages. |

#### Immersive HUD & Pure Overlay Architecture
- **Pure Overlay Layout:** HUDs are built as animated overlays in a `Stack`. The underlying reading canvas height remains 100% constant and stable, completely eliminating word-shifting or paragraph reflows when opening/closing menus.
- **Swipe Auto-Dismiss & Scroll-to-Reveal:** 
  - **Paginated Mode:** Swiping left/right to change pages smoothly dismisses the HUD.
  - **Vertical Scroll Mode:** Scrolling down hides the HUD; scrolling up smoothly reveals the Top & Bottom HUDs ("Quick-Peek").
- **100% Resilient Direct-Zip Engine:** Built-in `ZipDecoder` rescue parser that safely unzips and recovers all valid chapters/images even if an EPUB has broken manifest hrefs or missing files.
- **Broken Image Placeholder Card:** Corrupted or missing image tags render a theme-adaptive "Image unavailable" card with `Icons.broken_image_outlined` to preserve layout beauty.
- **Flicker-Free Image Caching:** Image nodes use `gaplessPlayback: true` and persistent `ValueKey`s to eliminate reload flicker during widget rebuilds.
- **Adaptive System UI:** Status bar icons dynamically adjust (dark icons on Light/Sepia themes, light icons on Dark/Black themes) with zero navigation button scrim.
- **Phone EPUB Import:** Direct `file_picker` integration allows opening any `.epub` file from local storage or switching books via the Top HUD folder icon.

#### Future Vertical Scroll Options
- **Default (Lithium Style):** Vertical scroll within the chapter, hard stop at the bottom, horizontal swipe to change chapters. *(Built & Active)*.
- **Soft Stop Overscroll:** Vertical scroll within the chapter, but pulling hard against resistance (overscrolling) at the bottom transitions to the next chapter. *(Future scope)*.
- **Continuous Infinite Scroll:** Seamless vertical scrolling where chapters flow directly into the next without any stops. *(Future scope)*.

---

### 4.2 Reader Bottom Card (Settings & Controls)
The reader has a bottom modal card (triggered by tapping the center of the screen or the Settings gear icon in the Top HUD). It is organized into **3 tabs** with pill indicators and full safe-area protection:

> **Future Scope (Main App Settings):** Users will be able to customize the order of these 3 tabs from the global App Settings screen (e.g. prioritize Appearance as Tab 1 instead of Navigation).

#### Tab 1: Navigation
| Control | Description |
|---|---|
| **Book Info Header** | Displays book title, author name, and total chapter count. |
| **Table of Contents (TOC)** | Scrollable list of all chapters. Tap any chapter to instantly jump to it and dismiss the card. Active chapter is highlighted with a primary pill badge. |
| **Bookmarks** | Saved user bookmarks with custom labels *(Phase 5)*. |

#### Tab 2: Appearance
| Control | Description |
|---|---|
| **Reading Mode** | Segmented toggle between **Paginated** and **Vertical Scroll**. |
| **Theme Presets** | One-tap presets: White, Cream/Sepia, Grey, Dark, Black (AMOLED). |
| **Font Family** | Choice chips: Default (Sans-Serif), Serif, Monospace. |
| **Font Size** | Symmetric layout: Slider (12px – 32px) + `-` / `+` stepper buttons. |
| **Line Spacing** | Symmetric layout: Slider (1.0x – 2.5x) + `-` / `+` stepper buttons. |
| **Text Alignment** | Native Flutter Text alignment toggle: Left, Right, Center, Justify *(Phase 7)*. |
| **Brightness** | In-app brightness override slider. |

#### Tab 3: Reading Tools
| Control | Description |
|---|---|
| **Auto-Scroll** | Toggle on/off + speed controller. |
| **Search in Book** | Full-text search across all chapters. |
| **RuneGlass Integration** | Enable/disable bionic reading mode & tap-to-lookup dictionary *(Phase 6)*. |

### 4.4 Settings & Configuration
The app includes a comprehensive settings hub with:
- **Appearance:** Global theme (Light/Dark/System), AMOLED Pitch Black, Dynamic Colors (Material You), and premium Theme Presets (e.g. Catppuccin, Nord, Dracula).
- **Library:** Default category assignment and Chapter Swipe Actions configuration (e.g., swipe left to mark read, swipe right to download).
- **Reader:** Global defaults for the reader engine (fonts, weights, text alignments, tab ordering).
- **Data & Storage:** Storage location configuration, cache clearing, and CSV/JSON library exports.
- **More:** Incognito Mode (disables history recording) and Download management.

### 4.5 History & Tracking
Lorebound automatically tracks reading history across the library. 
- Records whenever a book is opened or a chapter is completed.
- History entries are securely stored in the local Drift database with a join on the `Books` table to retrieve cover art and metadata.
- **Incognito Mode:** When active, history recording is suspended, ensuring privacy for specific sessions.

---

### 4.3 Cross-Mode Reading Position Persistence & Context Overlap
- **Intra-Chapter Progress Tracking:** The reader continuously tracks fractional chapter progress (`_chapterProgress = scrollOffset / maxScroll` in Scroll mode, `pageIndex / totalPages` in Paginated mode).
- **Context Overlap Buffer:** When switching between Paginated and Scroll modes, an intentional **1-page / ~0.7 screen height buffer** is applied so the user always lands with the previous paragraph clearly visible at the top of the screen for seamless reading continuity.
- **Local Persistence (Drift):** Chapter index and progress are persisted locally on chapter change *(Integrated in Phase 2)*.

---

## 5. Backend Integration (Lorekeeper API)

Lorebound acts as a strict consumer of the Lorekeeper backend (Private Reading Cloud model).

- **Private Cloud:** Every book belongs to a single user. No shared catalog. When User A uploads an EPUB, User B cannot see it.
- **Data Sync:** Frontend models mirror the JSON responses provided by the Lorekeeper backend.
- **Contract Driven:** We maintain API contracts in `.agents/references/api-contract.md` to ensure smooth integration.
- **Single Source of Truth:** Any new feature requiring backend support is added to the Lorekeeper API first to avoid mock endpoints or fragile logic in the frontend.

---

## 6. Development Roadmap

Phases are ordered so that **Phases 1–2 work completely offline** — no backend needed. Backend integration starts at Phase 3.

### Phase 1: Reader Engine v2 (Completed)
Rebuilt the core reader using a 100% Native Flutter engine instead of clunky WebViews.
- **Native Render Engine:** Uses `epubx` to extract HTML, then parses DOM directly into native Flutter widgets (`Text`, `Image`, `RichText`).
- **Binary Search Mathematical Pagination:** Chunks HTML nodes into pixel-exact screen bounds with word-boundary splitting.
- **Pure Overlay HUDs:** Slide-in Top & Bottom HUDs in a `Stack` that never reflow text or resize the reading canvas.
- **Swipe Auto-Dismiss:** Swiping page or scrolling automatically dismisses menus.
- **Cross-Mode Position Sync:** Real-time fractional progress tracking with 1-page context overlap buffer.
- **3-Tab Bottom Card:** Navigation TOC (direct chapter jumping), Appearance controls (steppers, sliders, chips, theme presets), Tools.

### Phase 2: Local Library (In Progress)
Build the offline book management library and local database.
- **Step 1 — Data Layer:**
  - `file_picker` integration for selecting `.epub` files from device storage.
  - `path_provider` storage service to copy and persist imported EPUBs in the app's document directory.
  - `drift` SQLite database schema: `BooksTable` (id, title, author, coverPath, filePath, totalChapters, lastReadChapter, lastReadProgress, lastReadAt).
- **Step 2 — Domain Layer:**
  - Lightweight `Book` entity model (metadata only — lightweight for fast grid rendering).
  - Repository interface for CRUD operations on local books.
- **Step 3 — State Layer (Riverpod):**
  - `LibraryController` (`AsyncNotifier`): Handles importing, listing, sorting (Recent, Title, Author), searching, and deleting books.
- **Step 4 — Presentation Layer (UI):**
  - **Library Screen:** Grid and List toggle view of imported books with high-res cover art, reading progress indicator bars, and sort/filter bar.
  - **Empty State & FAB:** Premium empty-state illustration + Floating Action Button to "Import Book".
  - **Book Details Sheet/Page:** Quick modal showing book metadata, reading stats, and "Resume Reading" / "Read Chapter 1" buttons.
  - **Seamless Navigation:** Tapping any book opens `ReaderScreen` with the selected book file path.
- **Step 5 — Settings & Customization Hub:**
  - `AppearanceSettingsScreen`: Theme modes, AMOLED toggles, and premium theme preset carousel.
  - `LibrarySettingsScreen`: Chapter swipe actions configuration.
  - `ReaderSettingsScreen`: Tab ordering and global text alignment, font weight, and expanded font options.
  - `DataStorageSettingsScreen`: CSV/JSON export dialog.
- **Step 6 — History & Tracking:**
  - `ReadingHistories` schema table.
  - `HistoryScreen`: Date-grouped list view with fast swipe-to-delete.
  - Wire-up with `ReaderScreen` to automatically log chapter changes (respecting `Incognito Mode`).

### Phase 3: Authentication
User accounts to enable cloud features.
- **Data:** Connect to Lorekeeper Auth APIs (JWT). `flutter_secure_storage` for token persistence.
- **State:** Global Session Provider (auth state, token refresh, logout)
- **UI:** Splash screen, Login/Register forms, profile section
- `go_router` auth redirect guards

### Phase 4: Cloud Library Sync
Connect the local library to the Lorekeeper Private Cloud.
- Upload EPUBs to Lorekeeper
- Download/sync book metadata and files
- Conflict resolution for books that exist both locally and in cloud
- `dio` with auth interceptor for all API calls

### Phase 5: Progress Tracking & Sync
Wire reading progress to both local DB and cloud.
- Save reading position locally on every chapter change (drift)
- Background sync worker: debounce progress updates to Lorekeeper
- Conflict resolution ("Resume from Chapter 15?")
- Progress bars on Library book covers

### Phase 6: RuneGlass Integration
Reading assistance features from the Lorekeeper RuneGlass module.
- Bionic highlighting (bold first half of each word for speed reading)
- Tap-to-lookup dictionary
- PDF text extraction / import

### Phase 7: Polish & Premium UX
Final touches for a premium feel.
- Hero animations between Library → Reader transitions
- Haptic feedback on page turns and bookmarks
- Onboarding flow for first-time users
- Reading statistics dashboard (books read, pages per day, streaks)
- Custom font import

---

## 7. Development Standards

- **Const Usage:** Static widgets, padding, and layout structures are marked `const` whenever possible to optimize rendering.
- **Strict Theming & Design Tokens:** We avoid hardcoded colors, spacing, margins, or font sizes to maintain a consistent design system:
  - Colors use `Theme.of(context).colorScheme`.
  - Spacing/Paddings use `AppSpacing.sm`, `AppSpacing.md`, etc.
  - Typography uses `Theme.of(context).textTheme`.
- **Performance:** Heavy UI components (charts, maps, complex animations) are isolated using `RepaintBoundary`.
- **Validation:** We strive for a clean codebase with zero warnings from `flutter analyze`.
- **Dependency Injection:** Services are provided via Riverpod `Provider` rather than being instantiated manually inside controllers.
