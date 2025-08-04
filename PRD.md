# PebbleBoard Product Requirements Document

## 1. Overview

PebbleBoard is a privacy-focused bookmarking application for Android and iOS, built with Flutter. Inspired by the way penguins collect pebbles for their nests, the app allows users to "collect" and organize web links into "boards." The core philosophy is that all user data is stored locally on the device, ensuring complete privacy. There are no accounts, no ads, and no analytics.

## 2. App Structure

The application is structured into several key directories, each with a specific responsibility:

*   **/lib**: The main source code of the application.
    *   **/database**: Contains the database schema, data access objects (DAOs), and migration logic. It uses the `drift` package for persistence.
    *   **/models**: Defines the data models used throughout the application, such as `BoardWithThumbnail`.
    *   **/providers**: Contains the application's state management logic, using `flutter_riverpod`. This includes providers for the database, paginated bookmarks, and application settings.
    *   **/screens**: Contains the UI for each screen of the application, such as the home screen, board screen, and settings screen.
    *   **/theme**: Defines the application's visual theme, including colors, fonts, and component styles.
    *   **main.dart**: The entry point of the application.
    *   **router.dart**: Defines the application's routing and navigation logic, using the `go_router` package.

## 3. Key Features

*   **Local-First Storage**: All data is stored in a local SQLite database on the user's device.
*   **Boards**: Users can create, rename, and delete boards to organize their bookmarks.
*   **Bookmarks**: Users can save bookmarks to boards, which include a title, description, and image thumbnail. Bookmarks can be added from within the app or by sharing a URL from another app.
*   **Metadata Fetching**: When a URL is added, the app automatically fetches the title, description, and image from the web page.
*   **Customizable Thumbnails**: Users can choose to use the automatically fetched image as the board thumbnail, or they can select a custom image from their device's gallery.
*   **Customizable Appearance**: Users can choose between a light, dark, or system theme, and can select a custom accent color.
*   **Data Management**: Users can export and import their entire database, allowing for backups and easy migration to a new device.
*   **Privacy-Focused**: The app has no user accounts, no ads, and no analytics. All data is stored locally and is never sent to a server.

## 4. Dependencies

The application uses the following key dependencies:

*   **flutter_riverpod**: For state management.
*   **drift**: For the local database.
*   **go_router**: For routing and navigation.
*   **receive_sharing_intent**: To receive shared URLs from other apps.
*   **share_plus**: To share URLs from the app.
*   **metadata_fetch**: To fetch metadata from web pages.
*   **image_picker**: To pick images from the device's gallery.
*   **cached_network_image**: To display and cache network images.
*   **file_picker**: To export and import the database.
*   **google_fonts**: For custom fonts.
*   **url_launcher**: To open URLs in the browser.
*   **shared_preferences**: To store user settings.
