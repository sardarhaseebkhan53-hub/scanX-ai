# Google Play Compliance Checklist & Policy Guide

ScanX AI is engineered to comply strictly with **Google Play Developer Policies**, optimizing for **Android 10 (API Level 29) and above**, ensuring user data protection, privacy, and transparent monetization.

- **Developer**: Developed by Sardar Haseeb
- **Company**: Sardar Haseeb Technologies
- **Copyright**: © Sardar Haseeb. All Rights Reserved.
- **Support**: support@sardarhaseeb.com

---

## 1. Permissions Justification & Scoped Storage

ScanX AI requests only minimal, functionally required permissions and adheres to **Android Scoped Storage** policies:

| Permission | Android API Level | Justification |
| :--- | :--- | :--- |
| `android.permission.CAMERA` | All APIs | Essential for capturing document, receipt, and ID card photos in real-time. |
| `android.permission.READ_MEDIA_IMAGES` | API 33+ (Android 13+) | Required only when the user explicitly chooses to import existing images from their gallery. |
| `android.permission.READ_EXTERNAL_STORAGE` | API 29–32 (Android 10–12) | Fallback for importing photos on legacy Android SDKs. |
| `android.permission.USE_BIOMETRIC` | API 28+ | Allows fingerprint/face recognition to unlock secure vaults and locked folders. |
| `android.permission.INTERNET` | All APIs | Required for AI cloud processing (Gemini/OpenAI), cloud sync (Firebase/Drive), and Google Play Billing. |
| `com.android.vending.BILLING` | All APIs | Enables Google Play in-app purchases and subscriptions. |

### Why ScanX AI Does NOT Require `MANAGE_EXTERNAL_STORAGE`:
- In compliance with Google Play guidelines for non-file-manager utilities, ScanX AI stores documents within its **app-specific directory** and uses the Android MediaStore / Storage Access Framework for user-directed exports.

---

## 2. Google Play Data Safety Section Answers

When completing the Data Safety Form in Google Play Console, use the following specifications:

1. **Data Collection & Security**:
   - **Is data encrypted in transit?** -> **YES** (TLS 1.3 / HTTPS for Firebase, OpenAI, and Gemini APIs).
   - **Can users request data deletion?** -> **YES** (Users can delete individual files permanently or purge all cloud records from app settings).

2. **Data Types Collected**:
   - **Files and Docs**: Document scans and OCR text are collected *only* for user-requested cloud backups or AI analysis. Data is not shared with third parties for advertising.
   - **Financial Info**: In-app purchase history is managed entirely by Google Play Billing. ScanX AI never processes credit card numbers.

---

## 3. AdMob & Monetization Policy Compliance

- **No Accidental Clicks**: AdMob banners are positioned outside interactive UI flows. Interstitial ads only trigger between complete document scan sessions and never interrupt camera preview or cropping.
- **Instant Premium Ad Removal**: Upgrading to any ScanX Premium plan immediately disables the Google Mobile Ads SDK across the app.

---

## 4. Privacy Policy & Terms of Service

ScanX AI includes standard, accessible **Privacy Policy**, **Terms of Service**, and **Open-Source Licenses** screens in `lib/features/settings/presentation/screens/legal_policy_screen.dart`. Before publishing to production:
1. Host your official Privacy Policy on a public URL (e.g., `https://sardarhaseeb.com/scanx-privacy.html`).
2. Update the Privacy Policy link in Google Play Console under **App Content -> Privacy Policy**.
