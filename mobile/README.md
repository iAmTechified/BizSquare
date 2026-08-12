# Akawo Mobile App - Recommended Directory Structure

For a highly maintainable and scalable Flutter application, a feature-first approach (like Domain-Driven Design or layered architecture) is recommended. Here is the recommended directory structure for Akawo:

```text
lib/
│
├── core/                       # Core functionalities shared across the app
│   ├── constants/              # App-wide constants (colors, text styles, keys)
│   ├── errors/                 # Exception and failure classes
│   ├── network/                # HTTP clients, interceptors (e.g., Dio setup)
│   ├── utils/                  # Helper functions (e.g., formatters, validators)
│   └── widgets/                # Reusable global widgets (buttons, dialogs)
│
├── features/                   # Feature-based modules
│   ├── auth/                   # Authentication (Login, OTP, etc.)
│   ├── matchmaking/            # The core Akawo matches feed
│   ├── profile/                # User profile & Akawo points
│   └── contacts/               # Native contact syncing logic & WhatsApp Integration
│       ├── data/
│       │   ├── models/         # DTOs and JSON serializers
│       │   └── repositories/   # Implementations of domain repositories
│       ├── domain/
│       │   ├── entities/       # Pure Dart business objects
│       │   └── repositories/   # Repository interfaces
│       └── presentation/
│           ├── pages/          # Screens related to this feature
│           ├── widgets/        # Widgets specific to this feature
│           └── bloc/           # State management (Bloc, Riverpod, etc.)
│
├── services/                   # App-wide services (often singletons)
│   ├── contact_sync_service.dart # Our Native Bridge Service (flutter_contacts)
│   └── whatsapp_service.dart     # Service for url_launcher deep-linking
│
└── main.dart                   # Entry point of the app
```

### Key Considerations

1. **Services Layer**:
   `services/contact_sync_service.dart` lives here because it directly interacts with the underlying OS. Depending on your state management preference (e.g., Riverpod, GetIt), you will inject this service directly into your controllers or blocs.

2. **OS Permissions**:
   Before `flutter_contacts` can write to the OS address book, you must declare these permissions:
   
   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSContactsUsageDescription</key>
   <string>Akawo requires contacts access to automatically sync your weekly business matches.</string>
   ```

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.READ_CONTACTS"/>
   <uses-permission android:name="android.permission.WRITE_CONTACTS"/>
   ```

3. **WhatsApp Deep-Linking (`url_launcher`)**:
   Create a dedicated helper method or a `whatsapp_service.dart` using `url_launcher` to handle deep links format: `whatsapp://send?phone=+1234567890`. You will also need to add `<queries>` for WhatsApp in Android manifest and `LSApplicationQueriesSchemes` in iOS plist.
