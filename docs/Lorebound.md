# Lorebound

## 1. Project Overview
**Lorebound** is a personal ebook reader and reading tracker app built with Flutter. It serves as the user-facing frontend for the [**Lorekeeper API**](https://github.com/TheNirajMahale/lorekeeper-api) (Private Reading Cloud backend) and the **RuneGlass** reading-assistance module.

### Vision
A lightweight, distraction-free, offline-first ebook reader with optional cloud sync. Lorebound is 100% functional out-of-the-box as an autonomous offline reader without requiring an account, login, or internet connection. Users can import local EPUBs, read with a custom native Flutter engine, track detailed reading stats locally, and optionally connect to their personal Lorekeeper server to sync libraries across devices.

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
│   ├── database/                  # Centralized Drift SQLite database & providers
│   ├── constants/                 # App-wide constants (API base URLs, keys)
│   ├── routing/                   # GoRouter configuration and route definitions
│   ├── services/                  # Core cross-cutting services (ApiService, AuthInterceptor)
│   ├── theme/                     # Plus Jakarta Sans, ColorScheme, Spacing, Presets
│   └── utils/                     # Generic helpers (formatters, extensions)
│
├── features/                      # Feature modules (Feature-First)
│   ├── library/                   # Local book import, grid/list shelves, categories
│   ├── reader/                    # Native EPUB engine, scroll/paginated modes, HUD
│   ├── history/                   # Reading history accordion, time-range batch deletion
│   ├── statistics/                # Immersion time, WPM, 1-week stall shelf, circadian chart
│   ├── settings/                  # Global appearance, cache management, date formats
│   └── more/                      # More menu coordinator, about, statistics screen
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
| **Bookmarks** | Saved user bookmarks with custom labels *(Phase 9 / Backlog)*. |

#### Tab 2: Appearance
| Control | Description |
|---|---|
| **Reading Mode** | Segmented toggle between **Paginated** and **Vertical Scroll**. |
| **Theme Presets** | One-tap presets: White, Cream/Sepia, Grey, Dark, Black (OLED). Cards use solid M3 surface containers with crisp borders across all 5 themes. |
| **Font Family** | Curated typefaces: **Merriweather** (#1 favorite), **Literata** (#2), **Atkinson Hyperlegible** (#3), followed by Inter, Lora, Fira Code, Outfit, Playfair, Nunito, and Comic Neue. |
| **Font Size** | Symmetric layout: Slider (12px – 32px) + `-` / `+` stepper buttons. |
| **Line Spacing** | Symmetric layout: Slider (1.0x – 2.5x) + `-` / `+` stepper buttons. |
| **Text Alignment** | Native Flutter Text alignment toggle: Left, Right, Center, Justify. |
| **Brightness** | In-app brightness override slider. |

#### Tab 3: Reading Tools
| Control | Description |
|---|---|
| **Auto-Scroll Engine** | Toggle on/off + speed stepper (15 – 120 px/s). Activates a floating control pill with pause/resume, live speed counter, touch-drag pause, and dismiss button (exclusive to Vertical Scroll mode). |
| **In-Chapter Search** | Quick search directly in the Reader Top Bar with occurrence stepper (`▲`/`▼`), keyboard-safe viewport anchoring (28px below top HUD), and text highlighting. |
| **RuneGlass Integration** | Enable/disable bionic reading mode & tap-to-lookup dictionary *(Phase 8.4)*. |

### 4.3 Auto-Scroll Reading Engine & Floating HUD
Continuous hands-free reading engine designed for vertical webnovel and long-form chapters:
- **Floating Ergonomic Controller:** Sleek floating pill in `ScrollReader` with Pause / Resume toggle, live speed indicator (`X px/s`), and instant Dismiss button (`X`).
- **Touch-Drag Auto-Pause:** Touching or dragging anywhere on the screen immediately suspends scrolling; releasing smoothly resumes reading without jarring momentum jumps.
- **Speed Adjustment:** Stepper controls and slider spanning 15 px/s to 120 px/s.
- **Mode-Restricted:** Exclusively enabled during continuous vertical scroll mode (`ReaderMode.scroll`), cleanly disabled and hidden in paginated mode.

### 4.4 Dual Search Architecture
To balance speed and comprehensive research, search is split into two specialized interfaces:
1. **In-Chapter Quick Search:** Located directly in the Reader Top Bar. Highlights matches in text, provides `▲` and `▼` steppers, anchors matches 28px below the top HUD (keeping matches visible above the on-screen keyboard), and displays a floating "Resume Reading" pill to return to the reading position.
2. **Book-Wide Deep Search:** Accessible from the `BookDetailScreen` header. Scans all chapters, displaying context snippets with bold keyword matching, and jumps straight into that chapter.

### 4.5 Cross-Mode Reading Position Persistence & Context Overlap
- **Intra-Chapter Progress Tracking:** The reader continuously tracks fractional chapter progress (`_chapterProgress = scrollOffset / maxScroll` in Scroll mode, `pageIndex / totalPages` in Paginated mode).
- **Context Overlap Buffer:** When switching between Paginated and Scroll modes, an intentional **1-page / ~0.7 screen height buffer** is applied so the user always lands with the previous paragraph clearly visible at the top of the screen for seamless reading continuity.
- **Local Persistence (Drift):** Chapter index and progress are persisted locally on chapter change *(Integrated in Phase 2)*.

### 4.6 Settings & Configuration Hub
The app includes a comprehensive settings hub with:
- **Appearance:** Global theme (Light/Dark/System), AMOLED Pitch Black, Dynamic Colors (Material You), and premium Theme Presets (e.g. Catppuccin, Nord, Dracula).
- **Date Formats:** Customizable timestamp rendering (Relative, Indian 12h, UK, US) synced reactively across history.
- **Library:** Default category assignment and Chapter Swipe Actions configuration (e.g., swipe left to mark read, swipe right to download).
- **Reader:** Global defaults for the reader engine (fonts, weights, text alignments, tab ordering).
- **Data & Storage:** Storage location configuration, cache clearing, and CSV/JSON library exports.
- **More:** Incognito Mode (disables history recording) and Download management.

### 4.7 History & Tracking
Lorebound automatically tracks reading history across the library. 
- Records whenever a book is opened or a chapter is completed.
- History entries are securely stored in the local Drift database with a join on the `Books` table to retrieve cover art and metadata.
- **Accordion Organization:** History entries are grouped by book with 12h Indian time and relative date stamps (`Today, 10:30 am`), featuring single-expand accordions and time-range batch deletion confirmation prompts.
- **Incognito Mode:** When active, history recording is suspended, ensuring privacy for specific sessions.

### 4.8 Specialized Reading Statistics Dashboard
Lorebound features a dedicated reading analytics engine powered by Drift SQLite schema v6 (`ReadingSessions` table) and live lifecycle session tracking in `ReaderScreen`:
- **KPI Summary Ribbon:** Displays total immersion time (formatted in hours and minutes), total completed chapters, and active reading days this month.
- **1-Week Stalled Books Shelf:** Automatically highlights books in `READING` status that have remained untouched for 7+ days. Shows book cover, author, paused chapter progress (`Ch. X / Y`), and exact stall duration (`X days stalled`), with immediate one-tap actions:
  - **Resume Reading:** Directly launches the reader at the exact paused chapter.
  - **Move to On-Hold:** Transitions the book status to `ON_HOLD` in Drift and reactively refreshes the active reading shelf.
- **Reading Velocity & Pace:** Computes historical Words Per Minute (WPM), average minutes per chapter, and dynamic reading pace badges (*Sprint Reader*, *Steady Immersion*, *Deep Reflective*). Strictly excludes any book completion time / ETA estimations.
- **Circadian Peak Reading Hours:** 24-hour reading distribution bar chart wrapped in `RepaintBoundary` for zero scroll-lag, with dynamic circadian archetype badges (*Night Owl*, *Early Bird*, *Afternoon Browser*, *Evening Scholar*).
- **30-Day Activity Heatmap:** GitHub-style visual intensity grid mapping daily reading density, current streak count, and longest reading streak.
- **Library Completion Funnel:** Segmented progress bar visualizing reading, completed, and want-to-read distributions.

---

## 5. Backend Integration (Lorekeeper API)

Lorebound acts as an optional consumer of the Lorekeeper backend (Private Reading Cloud model).

- **Guest / Offline-First Autonomy:** The core reader, local library, and reading statistics do NOT require an account. Lorebound boots directly into the local Library as an offline guest. All imported books and SQLite records remain 100% private and on-device.
- **Optional Cloud Connection:** Cloud sync is initiated optionally from the Settings/More screen for users who wish to back up their library or sync reading progress across mobile and web.
- **Private Cloud:** Every book belongs to a single user. No shared catalog. When User A uploads an EPUB, User B cannot see it.
- **Data Sync:** Frontend models mirror the JSON responses provided by the Lorekeeper backend.
- **Contract Driven:** We maintain API contracts in `.agents/references/api-contract.md` to ensure smooth integration.
- **Single Source of Truth:** Any new feature requiring backend support is added to the Lorekeeper API first to avoid mock endpoints or fragile logic in the frontend.

### 5.1 Cloud Deletion Strategy (Point to Remember)
When implementing the Lorekeeper Cloud Sync, we must split book deletion in the UI into two distinct actions to handle local vs cloud data properly:

1. **"Remove Download" (Local Only)**
   - **Action:** Deletes the heavy `.epub` file, cover image, and extracted cache off the device to save space.
   - **Database:** Keeps the book row in both the local SQLite database and the cloud database. The reading history is preserved, and the book can be re-downloaded later.
2. **"Delete from Library" (Nuclear Option)**
   - **Action:** Wipes all local files (EPUB, cache, cover).
   - **Database:** Hard deletes the book row from the local database, AND fires a `DELETE /api/books/{id}` request to the Lorekeeper cloud to completely wipe the book and its reading history from the user's account.

### 5.2 Multi-Cycle Rereading Architecture & Sync Strategy (Future Roadmap / Long-Term Scope)
Readers of webnovels and sprawling EPUB sagas frequently re-read favorite books or revisit specific climax arcs. While tracking re-reads is a core long-term feature on the future roadmap, implementing it before establishing rock-solid single-stream cloud integration creates severe architectural risks.

#### Why Re-reading Belongs in the Future Roadmap (Post-Integration)
1. **Database Schema Shift:** A standard reader stores a flat `currentChapter` index and a boolean `isRead` or `status: COMPLETED`. For re-reading, the database cannot simply overwrite `currentChapter = 1` because doing so erases previous completion timestamps, total read velocity, and history records. It requires a dedicated `ReadCycle` model with distinct cycle keys (`cycleIndex: 1, 2...`).
2. **Cloud Sync Conflict & State Reconciliation:** If a user completes a 1,200-chapter book on Web (Cycle 1, 100%), but begins re-reading Chapter 15 offline on Mobile (Cycle 2, 1.2%), a naive sync would mistakenly regress the cloud book status backwards from `COMPLETED` to `READING`, wiping out their completion badge. The sync protocol must support cycle-aware merging and monotonic progression per cycle.
3. **Library & Shelf UI Ambiguity:** If a book is completed once, how should the progress bar and shelf look? If the user is on Chapter 3 of their second read, showing `3 / 1,200` without context makes the book appear barely started. The UI requires cyclical status badges (e.g., `Completed (2nd Read • Ch. 3/1,200)`).
4. **Arc Affinity vs. Full Sequential Re-reading:** Many webnovel readers do not re-read from chapter 1 to 1,000; they repeatedly revisit specific arcs (e.g. chapters 350–420). Re-reading support must differentiate between **Full Book Cycles** and **Arc Revisit Affinity** to avoid skewing completion statistics.

#### Future Implementation Plan (After Core Cloud Sync)
Once Phase 8 (Single-Stream Backend Sync) is 100% hardened and verified in production:
- Local Drift schema migration introducing `ReadCyclesTable` (`id`, `bookId`, `cycleIndex`, `startedAt`, `completedAt`, `isCurrentCycle`).
- Lorekeeper API extension: `POST /books/{id}/cycles/start`, `GET /books/{id}/cycles`.
- UI additions: "Start Re-read" prompt on completed books, cyclical shelf chips, and a "Re-read Affinity & Arc Revisit" card in the Reading Statistics dashboard.

---

## 6. Development Roadmap

Phases are ordered so that **Phases 1–7 work completely offline** — no backend needed. Backend integration begins at **Phase 8**.

### Phase 1: Reader Engine v2 (Completed)
Rebuilt the core reader using a 100% Native Flutter engine instead of clunky WebViews.
- **Native Render Engine:** Uses `epubx` to extract HTML, then parses DOM directly into native Flutter widgets (`Text`, `Image`, `RichText`).
- **Binary Search Mathematical Pagination:** Chunks HTML nodes into pixel-exact screen bounds with word-boundary splitting.
- **Pure Overlay HUDs:** Slide-in Top & Bottom HUDs in a `Stack` that never reflow text or resize the reading canvas.
- **Swipe Auto-Dismiss:** Swiping page or scrolling automatically dismisses menus.
- **Cross-Mode Position Sync:** Real-time fractional progress tracking with 1-page context overlap buffer.
- **3-Tab Bottom Card:** Navigation TOC (direct chapter jumping), Appearance controls (steppers, sliders, chips, theme presets), Tools.

### Phase 2: Local Library (Completed)
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
  - **Library Screen:** Grid and List toggle view, selection mode for batch actions (delete, categorize, mark read), animated inline search, and sort/filter bar.
  - **Empty State & FAB:** Premium empty-state illustration + Floating Action Button to "Import Book".
  - **Book Details Sheet/Page:** Quick modal showing book metadata, reading stats, and "Resume Reading" / "Read Chapter 1" buttons.
  - **Seamless Navigation:** Tapping any book opens `ReaderScreen` with the selected book file path.
- **Step 5 — Settings & Customization Hub:**
  - `AppearanceSettingsScreen`: Theme modes, AMOLED toggles, and premium theme preset carousel.
  - `LibrarySettingsScreen`: Chapter swipe actions configuration.
  - `ReaderSettingsScreen`: Tab ordering and global text alignment, font weight, and expanded font options.
  - `DataStorageSettingsScreen`: CSV/JSON export dialog.
  - **Search:** Universal inline search across all settings.
- **Step 6 — History & Tracking:**
  - `ReadingHistories` schema table.
  - `HistoryScreen`: Date-grouped list view with fast swipe-to-delete, batch clear history, and inline search.
  - Wire-up with `ReaderScreen` to automatically log chapter changes (respecting `Incognito Mode`).

### Phase 3: Dual Search Architecture & In-Chapter Navigation (Completed)
- In-Chapter Quick Search & Proportional Auto-Scroll (`Scrollable.ensureVisible` at 25% viewport height, text highlighting, floating "Resume Reading" pill).
- Book-Wide Search in `BookDetailScreen` (`BookSearchSheet`) searching across all chapters with snippet highlighting.
- Proportional character offset calculation to guarantee matches appear at the top of the viewport above the on-screen keyboard with extra bottom viewport padding.

### Phase 4: Auto-Scroll Reading Engine & Control HUD (Completed)
- Built floating ergonomic control pill in `ScrollReader` with Pause / Resume toggle, live speed indicator, and Dismiss button (`X`).
- Touch-drag auto-pause with smooth resumption.
- Restricted auto-scroll controls exclusively to continuous vertical scroll mode (`ReaderMode.scroll`), cleanly disabling the active toggle in paginated mode.

### Phase 5: Codebase Cleanup & Architectural Reorganization (Completed)
- Relocated Drift database from `features/library/data/local/` to `lib/core/database/` eliminating cross-feature leaks.
- Renamed `native_scroll_reader.dart` -> `scroll_reader.dart` and `native_paginated_reader.dart` -> `paginated_reader.dart`.
- Decomposed monolithic `reader_settings_sheet.dart` (724 lines down to 140 lines) by extracting sub-tabs into `settings_sheet/reader_navigation_tab.dart`, `reader_appearance_tab.dart`, and `reader_tools_tab.dart`.
- Split `reader_bars.dart` into `reader_top_bar.dart` and `reader_bottom_bar.dart`.

### Phase 6: Reading Statistics Dashboard & Drift Schema v6 (Completed)
- Added `ReadingSessions` table in Drift schema v6 tracking `bookId`, `chapterIndex`, `durationSeconds`, and `sessionDate`.
- `ReadingStatisticsRepository` with graceful fallback for pre-existing history (~4.5 min/chapter) and 7-day stall queries.
- Connected `ReaderScreen` with `WidgetsBindingObserver` to track reading session durations on chapter changes, reader exit, or app backgrounding with accidental-bounce filtering and safe disposal guards.
- Comprehensive UI Dashboard:
  - `StatsKpiRibbonCard`: Total immersion time, completed chapters, active reading days.
  - `StalledBooksShelfCard`: 1-Week stall shelf with cover art, paused chapter (`Ch. X / Y`), stall duration, `Resume Reading`, and `Move to On-Hold`.
  - `ReadingVelocityCard`: Words Per Minute (WPM) & minutes/chapter with pace badges (Strictly zero ETA).
  - `PeakReadingHoursCard`: 24-hour circadian histogram in `RepaintBoundary` with archetype badge.
  - `ReadingActivityHeatmapCard`: 30-day activity intensity grid and reading streak tracking.
  - `LibraryCompletionFunnelCard`: Segmented status funnel for Reading, Completed, and Want to Read.

### Phase 7: Global Industry Typography & Theme Elevation (Completed)
- Upgraded global UI typography from Roboto to **Plus Jakarta Sans** via `google_fonts`.
- Curated top-3 in-reader reading typefaces with user-favorite **Merriweather** (#1), **Literata** (#2), and **Atkinson Hyperlegible** (#3) directly at the start of the reader font picker.
- Elevated card surfaces across all 5 theme presets (Light, Dark, OLED Black, Sepia, Grey) with solid M3 surface containers, crisp outline borders, and subtle elevation drop shadows.
- Responsive layout refactoring on all dashboard cards (Wrap for action buttons, FittedBox on metrics, Expanded headers) to eliminate horizontal mobile overflows.

---

### Phase 8: Lorekeeper Backend Integration (Up Next — Active Focus)
With the local reader engine, library management, and reading tracker fully built and polished offline, the app is ready for cloud synchronization with the [**Lorekeeper API**](https://github.com/TheNirajMahale/lorekeeper-api).

- **8.1 — Optional Authentication & Session Management:**
  - Login is 100% optional: the app starts in local guest mode and never blocks reader access behind a login wall.
  - Connect to Lorekeeper Auth endpoints: `POST /auth/register`, `POST /auth/login`, `POST /auth/google`.
  - JWT token storage via `flutter_secure_storage`.
  - Global `SessionController` (login, logout, token refresh, user profile).
  - Cloud sync settings toggle in More/Settings to enable/disable cloud sync.
- **8.2 — Cloud Library Sync & Remote Catalog:**
  - Connect to `/books` endpoints (`GET /books`, `POST /books/upload`, `DELETE /books/{id}`).
  - Implement two-tier deletion strategy ("Remove Download" local-only vs "Delete from Library" cloud nuclear wipe).
  - Background synchronization worker with `dio` interceptors and retry policies.
- **8.3 — Reading Progress & History Synchronization:**
  - Sync reading sessions and chapter progress with `/reading-history` and `/books/{id}/progress`.
  - Debounced progress sync on chapter transition.
  - Conflict resolution dialog ("You were on Chapter 14 on Web, resume from Chapter 14?").
- **8.4 — RuneGlass Module Integration:**
  - Bionic reading mode rendering (bold leading half of words).
  - Tap-to-lookup dictionary and word definitions via RuneGlass API.

---

### Phase 9: In-Reader Bookmarks, Highlights & Annotations (Future Scope)
Deep study and annotation capabilities for the native reading engine:
- In-chapter bookmarks with custom labels and chapter jump targets.
- Text selection and multi-color highlighting (Yellow, Mint, Lavender, Coral) with attached notes.
- Centralized annotations drawer and review sheet.
- Export annotations to Markdown and JSON formats.

---

### Phase 10: Multi-Cycle Reread Engine & Arc Affinity (Future Scope / Long-Term Roadmap)
Once core cloud synchronization and study tools are established, introduce full multi-cycle re-reading and arc revisit tracking:
- **Drift Schema Extension (`ReadCycles` Table):** Track cycle indices (`cycleIndex: 1, 2...`), distinct start/completion dates, and isolated chapter coordinates per cycle.
- **Cycle-Aware Cloud Protocol:** Extend Lorekeeper API endpoints (`POST /books/{id}/cycles/start`, `GET /books/{id}/cycles`) with conflict-free merge rules so starting a second read never overwrites the cloud completion badge.
- **Library Shelves & Badging:** Cyclical progress indicators on book cards (e.g., `Completed (2nd Read • Ch. 24 / 900)`).
- **Re-read Affinity & Arc Revisit Analytics:** Distinguish full sequential rereads from frequent chapter/arc revisits, adding an Arc Affinity module to the Statistics Dashboard.

---

### Phase 11: Multi-Platform Polish & Offline Queue Sync (Future Scope)
- Offline-first mutation queue (stores progress/library modifications locally when offline and pushes to Lorekeeper automatically when connection is restored).
- Immersive edge-to-edge system navigation bar adaptations across Android 15 and iOS.
- Full local backup & restore bundle (`.lorebackup` archive).

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
