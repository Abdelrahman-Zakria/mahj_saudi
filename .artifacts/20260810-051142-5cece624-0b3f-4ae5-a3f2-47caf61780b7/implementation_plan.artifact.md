# AdMob Integration Implementation Plan

This plan outlines the integration of Google AdMob to monetize the app using Banner, Interstitial, and App Open ads with the provided keys.

## User Review Required

- **Interstitial vs Rewarded**: The user mentioned "rewarded ad", but provided "Inter" (Interstitial) keys. I will implement **Interstitial ads** (non-skippable/skippable full-screen) as per the keys provided, which is common for "unlocking" content.
- **Ad Frequency**: Showing an ad on *every* final leaf might be aggressive. I'll implement it such that it attempts to show before opening a PDF or video.

## Proposed Changes

### [Dependencies]

#### [pubspec.yaml](file:///C:/Users/tiger/StudioProjects/mahj_saudi/pubspec.yaml)
- Add `google_mobile_ads: ^5.1.0` to `dependencies`.

---

### [Platform Configuration]

#### [AndroidManifest.xml](file:///C:/Users/tiger/StudioProjects/mahj_saudi/android/app/src/main/AndroidManifest.xml)
- Add `<meta-data>` tag for `com.google.android.gms.ads.APPLICATION_ID` with `ca-app-pub-5716551354866412~5995294174`.

#### [Info.plist](file:///C:/Users/tiger/StudioProjects/mahj_saudi/ios/Runner/Info.plist)
- Add `GADApplicationIdentifier` with `ca-app-pub-5716551354866412~2079385888`.
- Add `SKAdNetworkItems` for ad attribution.

---

### [Ad Management Service]

#### [NEW] [ad_service.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/core/services/ad_service.dart)
- Create a singleton service to:
    - Initialize the SDK.
    - Load and show **App Open Ads** on startup.
    - Provide a helper to load/return **Banner Widgets**.
    - Manage **Interstitial Ads** (Load, show with a callback to proceed to content).

---

### [Presentation Layer Integration]

#### [main.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/main.dart)
- Initialize `AdService` during app startup.

#### [home_page.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/features/home/presentation/screens/home/home_page.dart)
- Integrate a Banner Ad at the bottom of the home content.

#### [content_page.dart](file:///C:/Users/tiger/StudioProjects/mahj_saudi/lib/features/home/presentation/screens/content/content_page.dart)
- Modify navigation to final leaves (PDF/Video):
    - Trigger `AdService.showInterstitialAd(onAdDismissed: () => navigateToLeaf())`.

## Verification Plan

### Manual Verification
- **Banner**: Confirm the banner appears at the bottom of the Home screen.
- **Interstitial**: Confirm that when clicking a subject that leads to a PDF, an ad is shown before the PDF viewer opens.
- **App Open**: Confirm an ad is shown when the app is brought from background to foreground (or on fresh launch if configured).
- **Log Verification**: Check console logs for "Ad loaded" or "Ad failed to load" to debug keys.
