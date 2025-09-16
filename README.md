# PebbleBoard

PebbleBoard is a versatile Flutter application designed to help you organize and manage your web content (bookmarks) efficiently. It allows you to create custom "boards" to categorize your links, complete with thumbnails and detailed metadata. Whether you're saving articles, videos, or any other web resource, PebbleBoard provides an intuitive interface to keep your digital life organized.

## Features

*   **Board Management:**
    *   Create, view, rename, and delete custom boards to categorize your links.
    *   Display boards in a flexible grid or list view.
*   **Bookmark Management:**
    *   Add new bookmarks (URLs) with automatic metadata fetching (title, description, image).
    *   View bookmarks within specific boards in grid or list layouts.
    *   Search, edit, and delete individual bookmarks.
    *   Interact with bookmarks: open in browser, copy URL, or share.
*   **Theming:**
    *   Personalize your experience with Light, Dark, and OLED Dark themes.
*   **Intuitive UI/UX:**
    *   Clean and modern design with a focus on user experience.
    *   Utilizes the Montserrat font for a polished look.
*   **Cross-Platform:**
    *   Available on Android, iOS, Web, macOS, Linux, and Windows.

## Technologies Used

*   **Framework:** Flutter
*   **State Management:** `flutter_riverpod`
*   **Routing:** `go_router`
*   **Database:** `drift` (for local data persistence)
*   **Image Handling:** `cached_network_image` (for efficient image loading and caching)
*   **Fonts:** `google_fonts` (Montserrat)
*   **Sharing & Launching:** `receive_sharing_intent`, `share_plus`, `url_launcher`
*   **Metadata Fetching:** `metadata_fetch`
*   **Preferences:** `shared_preferences`
*   **File Picking:** `image_picker`, `file_picker`
*   **UI Components:** `reorderable_grid`

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/jeremyxlewis/pebble.git
    cd pebble
    ```
2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Generate Drift files (if needed):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

### Running the Application

To run the application on your preferred platform:

```bash
flutter run
```

For a specific platform (e.g., Android):

```bash
flutter run -d android
```

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

MIT License