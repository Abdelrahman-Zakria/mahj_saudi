# Implementation Plan - Fix App Store Rejection and Notifications

This plan addresses the App Store rejection regarding Guideline 2.3.10 (Accurate Metadata) and Guideline 2.1 (App Tracking Transparency), and ensures push notifications work correctly on iOS.

## User Review Required

> [!IMPORTANT]
> **GoogleService-Info.plist**: I noticed that `GoogleService-Info.plist` is missing from the `ios/Runner` directory. For Firebase and Push Notifications to work on iOS, you **must** download this file from your Firebase Console and place it in the `ios/Runner` folder. Since you are using CodeMagic, ensure this file is either committed to your repository or provided via CodeMagic environment variables/scripts.

> [!WARNING]
> **App Store Link**: I have updated the "Rate App" link to be platform-specific. However, you should verify the iOS App Store URL once your app is live or has an App ID assigned.

## Proposed Changes

### 1. Fix App Tracking Transparency (ATT)
The ATT prompt was likely not showing because it was called too early in the app lifecycle. I will move it to be called after the app is initialized and add a slight delay to ensure the system is ready to display the dialog.

#### [MODIFY] [main.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/main.dart)
- Move the ATT request logic out of `AdService.init()` (where it might be called before the window is ready) and into a safer initialization sequence in `main()`.

#### [MODIFY] [ad_service.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/core/services/ad_service.dart)
- Remove the ATT request from `init()` to avoid redundancy and potential race conditions.

---

### 2. Remove Google Play References (Guideline 2.3.10)
Apple rejects apps that reference other platforms like "Google Play" in the iOS binary or metadata.

#### [MODIFY] [more_cubit.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/features/home/presentation/screens/more/cubit/more_cubit.dart)
- Update `launchStore` to use the correct store URL based on the platform (`Platform.isIOS` vs `Platform.isAndroid`).

---

### 3. Ensure Notifications Work (without Xcode)
To ensure notifications work without opening Xcode, we must correctly configure the native iOS `AppDelegate`.

#### [MODIFY] [AppDelegate.swift](file:///C:/Users/tiger/StudioProjects/mahj_saudi/ios/Runner/AppDelegate.swift)
- Add `FirebaseApp.configure()` to the `application(_:didFinishLaunchingWithOptions:)` method. This is a critical step for Firebase services on iOS.

---

## Verification Plan

### Automated Tests
- N/A (UI and native integration changes)

### Manual Verification
1. **ATT Prompt**: Launch the app on an iOS device/simulator. Verify that the "Allow Tracking" prompt appears shortly after the splash screen disappears.
2. **Rate App Link**: Go to the "More" screen and tap "Rate App". Verify it opens the browser/App Store on iOS and Play Store on Android.
3. **Notifications**:
   - Ensure `GoogleService-Info.plist` is present.
   - Send a test notification from the Firebase Console to a physical iOS device.
   - Verify the notification is received in both foreground and background.
