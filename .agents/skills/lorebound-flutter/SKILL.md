---
name: lorebound-flutter
description: Lorebound-specific Flutter development patterns and best practices. Covers state management, connecting to the Lorekeeper API, and UI/UX design polish.
---

## Use this skill when
- Building or modifying Flutter screens or widgets in the Lorebound frontend.
- Connecting the frontend to the Lorekeeper API backend.

## Architecture Principles
As Lorebound is a new project, follow these general best practices for scalability:
- **Separation of Concerns:** Keep business logic out of UI files. 
- **Modular Design:** Group files by feature rather than strictly by type, enabling easier maintainability as the app grows.

## State Management
- **State Holders:** State should live in dedicated controllers or view models, depending on the chosen state management solution.
- **Optimize Rebuilds:** Avoid wrapping large parts of the UI in state listeners. Ensure state listeners are tightly scoped so only the exact UI element that needs the data rebuilds.
- **Accessing State:** Read state without listening when executing callbacks or functions. Avoid listening to state unconditionally in the root of a large `build()` method.

## Networking & Lorekeeper API Context
- **Centralized API Calls:** All HTTP calls should go through a dedicated service layer (like an `ApiService`) rather than being called directly inside widgets.
- **Model Alignment:** The frontend models MUST exactly match the JSON response fields provided by the Lorekeeper backend. If unsure about the backend model, ask the user to provide the backend DTO or check the backend contract.

## Theming & UI
- **Dynamic Theming:** Always use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` instead of hardcoded hex colors or font sizes.
- **Performance:** Keep widget files small and use the `const` keyword generously on static widgets, paddings, and layouts to avoid unnecessary repaints.
- **Heavy Rendering:** Wrap complex charts, maps, or intensive animations in a `RepaintBoundary`.
