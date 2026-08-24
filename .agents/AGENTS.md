# Lorebound Project Rules

These rules MUST be followed by all AI agents working on the Lorebound frontend project.

## 1. Professional Flutter Standards
- **Zero Wasted Rebuilds:** Optimize your UI to prevent unnecessary rebuilds of large widget trees. Only rebuild the specific UI elements that need the updated data.
- **Const Everything:** Static widgets, padding, and layout structure MUST be marked `const`.
- **State Management:** Keep business logic in the state management layer, NOT in the UI layer. Never instantiate lists or complex data directly inside a `build()` method.
- **Isolate Heavy UI:** Wrap complex charts, maps, or heavy animations in `RepaintBoundary`.

## 2. Backend Context & Lorekeeper API
- **Truth Source:** This frontend consumes the **Lorekeeper API**. Do NOT invent endpoints, payloads, or database logic.
- **Verification:** Before implementing API integrations, ALWAYS check the `references/api-contract.md` or ask the user for the specific Lorekeeper API DTO/Controller details.
- **Service Layer:** All HTTP calls must be routed through a dedicated `ApiService` or repository class. UI widgets should never make HTTP calls directly.

## 3. Git Workflow
- **Branching:** Do not commit directly to `main` or `master`. Always create a `feat/`, `fix/`, or `refactor/` branch.
- **Commits:** Use conventional commits (e.g., `feat(auth): add login screen`).

## 4. Agent Workflow
- **Native Tools:** Use specific file editing tools instead of raw bash scripts.
- **Verification:** Run `flutter analyze` and ensure zero errors before completing a task.

## 5. Documentation Syncing
- **Follow the Blueprint:** ALWAYS consult and follow `docs/Lorebound.md` while planning and making changes.
- **Keep it Updated:** If we implement new changes during development that conflict with the current `docs/Lorebound.md`, you MUST ask or suggest to update the documentation file to reflect the new reality.

## 6. Proactive Architectural Advising
- **Industry Standards Check:** Whenever you are asked to implement a design or architecture, you MUST evaluate if the approach aligns with industry standards and best practices.
- **Pros, Cons, and Alternatives:** If a requested approach has significant downsides, you MUST proactively explain the pros and cons, and strongly recommend the most efficient, project-appropriate alternative before proceeding.

## 7. Execution Strategy: Inside-Out Vertical Slicing
- **Feature-by-Feature:** Build one complete feature at a time (e.g., Reader Engine, then Library). Do NOT build all screens first.
- **Inside-Out:** Inside each feature, ALWAYS build the Data Layer (Models) -> State Layer (Riverpod) -> Presentation Layer (UI). 
- **Step-by-Step Verification:** Execute tasks step-by-step. Verify the functionality after every step. Update the `task.md` artifact after every successful verification so the user can track progress.

## 8. Artifact Generation Exemption
- **Override Hard Stop:** The global "Mandatory Question Check" rule is lifted when the user asks a question about generating or showing an `implementation_plan.md`, `walkthrough.md`, `task.md`, or other non-code-affecting artifacts. You may generate these artifacts immediately without pausing your turn.

## 9. Constant Code Analysis
- **Analyze After Edits:** You MUST run `flutter analyze` in the terminal immediately after making ANY edits to a `.dart` file. Do not wait until the end of a feature to analyze. Fix any errors before proceeding.

## 10. Custom Widget Justification
- **Document Alternatives:** Whenever a custom widget is chosen over an existing native Flutter package, you MUST document (e.g., in comments or PR notes): what the alternatives were, why the custom approach was chosen, and the long-term trade-offs for maintainability. Use custom widgets only when necessary.
