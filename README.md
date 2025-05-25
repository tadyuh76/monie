# Monie - Personal Finance Management App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x.x-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x.x-blue.svg)](https://dart.dev)

## Overview

Monie is a mobile application designed to help users, particularly students and young professionals, manage their personal finances effectively. It provides a user-friendly interface to track income, expenses, set budgets, and gain insights into spending habits.

## Features

The application includes the following core features:

- **User Authentication:** Secure sign-up and login functionality.
  - (Located in `lib/features/authentication/`)
- **Transaction Management:** Easily add, edit, and view income and expense transactions.
  - (Located in `lib/features/transactions/`)
- **Budgeting:** Create and manage budgets for different spending categories.
  - (Located in `lib/features/budgets/`)
- **Account Management:** Manage user profile and linked accounts (if applicable).
  - (Located in `lib/features/account/`)
- **Group Spending (if applicable):** Functionality to manage shared expenses within groups.
  - (Located in `lib/features/groups/`)
- **Home Dashboard:** An overview of financial status, recent transactions, and budget progress.
  - (Located in `lib/features/home/`)
- **Application Settings:** Customize app preferences, notifications, and themes.
  - (Located in `lib/features/settings/`)

## Tech Stack & Architecture

Monie is built with a modern tech stack and follows a robust architectural pattern:

- **Language:** [Dart](https://dart.dev/)
- **Framework:** [Flutter](https://flutter.dev/)
- **Architecture:** Clean Architecture
  - **Presentation Layer:** Manages UI and user interaction (Widgets, BLoCs/Cubits, Pages).
  - **Domain Layer:** Contains business logic (Entities, Use Cases, Repository Interfaces).
  - **Data Layer:** Handles data retrieval and storage (Repositories, Data Sources, Models).
- **State Management:** BLoC / Cubit (evident from `bloc` subdirectories in features).
- **Dependency Injection:** Using `get_it` (inferred from `lib/di/injection.dart` and `injection_container.dart`).
- **Routing:** (Specify your routing solution here, e.g., GoRouter, AutoRoute, or Flutter's Navigator 2.0)
- **Database:** Supabase (PostgreSQL)
- **Asset Management:** Utilizes Flutter's asset system, with generated asset references in `lib/gen/assets.gen.dart`.

## Project Structure

The project follows a feature-first directory structure within a Clean Architecture framework:

```
monie/
├── lib/
│   ├── main.dart               # Application entry point
│   ├── core/                   # Shared core functionalities
│   │   ├── constants/          # App-wide constants
│   │   ├── errors/             # Error handling (Failures, Exceptions)
│   │   ├── localization/       # Localization files and setup
│   │   ├── model/              # Core data models (if any, not feature-specific)
│   │   ├── network/            # Network utilities
│   │   ├── themes/             # App themes and styling
│   │   ├── utils/              # Utility functions
│   │   └── widgets/            # Common reusable widgets
│   ├── di/                     # Dependency injection setup
│   │   ├── injection.dart
│   │   └── injection_container.dart
│   ├── features/               # Feature-specific modules
│   │   ├── authentication/     # Authentication feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── transactions/       # Transactions feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── budgets/            # Budgets feature
│   │   ├── groups/             # Groups feature
│   │   ├── account/            # User account feature
│   │   ├── settings/           # Settings feature
│   │   └── home/               # Home/Dashboard feature
│   └── gen/                    # Auto-generated files (e.g., assets)
│       └── assets.gen.dart
├── android/                    # Android specific code
├── ios/                        # iOS specific code
├── assets/                     # Static assets (images, fonts, icons, lang)
│   ├── icons/
│   └── lang/
├── test/                       # Unit and widget tests (Create this directory if not present)
├── .env                        # Environment variables (ignored by Git)
├── pubspec.yaml                # Project dependencies and metadata
└── README.md                   # This file
```

## Getting Started

Follow these instructions to get the project up and running on your local machine.

### Prerequisites

- Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install) (Ensure you have a version compatible with the project, e.g., 3.x.x)
- Dart SDK: (Comes with Flutter)
- An IDE: Android Studio or VS Code (with Flutter and Dart plugins)
- Supabase Account: For backend services.

### Installation & Setup

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/tadyuh76/monie.git
    cd monie
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Environment Variables:**
    This project uses a `.env` file for managing sensitive information and environment-specific configurations, particularly for Supabase. - Create a file named `.env` in the root of the project. - Add your Supabase URL and Anon Key:
    `env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
`
    _Note: The `.env` file is included in `.gitignore` and should not be committed to version control._

### Running the App

1.  **Ensure an emulator is running or a device is connected.**
    You can check connected devices with:

    ```bash
    flutter devices
    ```

2.  **Run the app:**
    ```bash
    flutter run
    ```
    Alternatively, you can run the app from your IDE (VS Code or Android Studio).

## Screenshots / Demo

_(Consider adding a few screenshots or a GIF showcasing the main features of your application here.)_

**Example:**

|          Login Screen          |         Home Screen          |      Add Transaction       |
| :----------------------------: | :--------------------------: | :------------------------: |
| ![Login](link_to_login_ss.png) | ![Home](link_to_home_ss.png) | ![Add](link_to_add_ss.png) |

## Future Enhancements

- (List any planned future features or improvements based on your "Hướng Phát triển trong Tương lai" section)
- Example: Advanced financial reporting and analytics.
- Example: Integration with bank accounts for automatic transaction import.

## Contributing

(If this were an open project, you'd add contribution guidelines here. For a university project, you might mention team members or leave this section out.)

---

Built with ❤️ by tadyuh76 - PeanLut - Leonn2285 - ayo-lole
