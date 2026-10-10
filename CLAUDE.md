# Lamplight — Claude working instructions

## Model and effort routing

Use these models and effort levels when delegating work with the Agent tool. Pick by task type, not by habit.

- **File reads, lookups and token-light tasks** (finding files, grepping, reading a file to answer a question, small summaries): use **haiku** with **low** effort, or no extended thinking.
- **Coding** (writing, editing or refactoring Dart/Flutter code, running analyze and tests): use **sonnet** with **low** effort.
- **Thinking and planning** (architecture, design decisions, debugging with unclear cause, trade-off analysis, reviewing a plan): use **sonnet** with **medium** effort.

When in doubt between coding and thinking, choose thinking if the answer is a decision or explanation, and coding if the answer is a change to files.

## Project context

- Flutter app: `lib/`. Firebase backend (Auth, Firestore). Entry point `lib/main.dart`.
- Shared design layer lives in `lib/core/` (theme, glass widgets, feedback service, app state). Feature screens live in `lib/features/`.
- `production/library_app/` is a stale copy. Do not edit it.
- Validate changes with `flutter analyze` and `flutter test` before reporting them done.
- Do not commit or push unless the user asks.
