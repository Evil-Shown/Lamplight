# Library App

Mobile UI for the **Library Book Reservation & Reading Room Seat Booking System**.

## Modules

| Module | Screens | Requirements |
|--------|---------|--------------|
| **Books** | Search, Detail, My Reservations | FR01–FR07 |
| **Seats** | Map/List, Detail, My Bookings | FR08–FR12 |
| **Waitlist** | Join, Status, Countdown | FR13–FR15 |
| **Notifications** | Settings, Reminders | FR16–FR18 |
| **QR** | Scan check-in / pickup | FR19 |
| **Account** | Profile, Privacy, Accessibility | NFR04–NFR06 |

## Getting started

1. Install [Flutter](https://docs.flutter.dev/get-started/install)
2. From this folder:

```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
├── main.dart
├── app.dart
├── core/           # Theme, constants, shared widgets
├── data/mock/      # Sample data (no backend yet)
├── models/         # Domain models
└── features/       # Feature modules by screen
```

## Figma

Design file: [Library UI](https://www.figma.com/design/UwmGSbPjOtHRDai9KnA02V/Library-UI)
