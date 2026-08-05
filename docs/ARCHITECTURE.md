# ScanX AI — System Architecture & Clean Architecture Guide

ScanX AI is engineered with an enterprise-grade **Clean Architecture** combined with **Riverpod** state management, **GetIt** dependency injection, and a dual local-first (`Hive` + `Flutter Secure Storage`) / cloud-sync (`Firebase Enterprise Stack` + `OAuth Cloud Providers`) data layer.

- **Developer**: Developed by Sardar Haseeb
- **Company**: Sardar Haseeb Technologies
- **Copyright**: © Sardar Haseeb. All Rights Reserved.
- **Support**: support@sardarhaseeb.com

---

## 1. Architectural Layers

```
                                +--------------------------------------+
                                |           PRESENTATION               |
                                |   Material 3 Screens & Components    |
                                +--------------------------------------+
                                                   |
                                                   v
                                +--------------------------------------+
                                |      RIVERPOD STATE NOTIFIERS        |
                                |   UI Controllers & Reactive States   |
                                +--------------------------------------+
                                                   |
                                                   v
                                +--------------------------------------+
                                |          DOMAIN LAYER                |
                                | Entities, UseCases & Repos interfaces|
                                +--------------------------------------+
                                                   |
                                                   v
                                +--------------------------------------+
                                |           DATA LAYER                 |
                                | Repository Impls, Hive / Firebase    |
                                +--------------------------------------+
                                                   |
                                                   v
                                +--------------------------------------+
                                |         SERVICES LAYER               |
                                | AI, OCR, PDF, Keystore, Billing, Ads |
                                +--------------------------------------+
```

### Core Architecture Components:

1. **Domain Layer (`lib/domain/` & `lib/models/`)**
   - Pure Dart entities (`DocumentItem`, `FolderItem`, `OCRResult`, `AIAnalysisResult`, `AppSettings`).
   - Repository interfaces (`DocumentRepository`, `AIRepository`, `SecurityRepository`).
   - Contains zero UI dependencies.

2. **Data Layer (`lib/data/`)**
   - Implements repository interfaces (`DocumentRepositoryImpl`, `AIRepositoryImpl`, `SecurityRepositoryImpl`).
   - Delegates persistence to `HiveLocalDataSource` (offline-first Hive boxes) and `FirebaseCloudDataSource` (Firestore & Firebase Storage).
   - Timestamp-based conflict resolution: local updates merge seamlessly with cloud backups.

3. **Services Layer (`lib/services/`)**
   - **AI Engine (`PluggableAIService`)**: Seamlessly switches between **Google Gemini API**, **OpenAI GPT-4o API**, and an intelligent **On-Device Heuristic Engine** for zero-configuration and offline resilience.
   - **OCR Engine (`OCRService`)**: Wraps Google ML Kit text recognition with custom regular expressions to extract structured entities (dates, email addresses, phone numbers, person names).
   - **PDF Studio (`PDFService`)**: Generates high-resolution PDFs with optional custom watermarks, page numbering, password encryption, and digital signatures.
   - **Enterprise Security (`SecurityService` & `SecureStorageService`)**: LocalAuthentication (fingerprint & facial biometrics) integrated with Flutter Secure Storage backed by **Android Keystore**.
   - **Monetization (`BillingService` & `AdService`)**: Google Play Billing for non-consumable subscriptions & lifetime unlocks, combined with AdMob (automatically disabled for Premium subscribers).

4. **Presentation Layer (`lib/features/` & `lib/shared/`)**
   - Organized by feature: `/home`, `/scanner`, `/ocr`, `/pdf`, `/ai`, `/cloud`, `/security`, `/settings`.
   - Each feature encapsulates its own `presentation/controllers/` (Riverpod `StateNotifier`), `presentation/screens/`, and `presentation/widgets/`.

---

## 2. Pluggable AI Engine Design

ScanX AI decouples UI from specific LLM providers. By changing `AppSettings.aiProvider`, the runtime `PluggableAIService` directs OCR text to:

- `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent` (Gemini API)
- `https://api.openai.com/v1/chat/completions` (OpenAI API)
- **On-Device Heuristics**: If the user is offline or has not configured an API key, ScanX AI parses document structure using regex and statistical heuristics to generate summaries, extract invoice line items, and categorize receipts.

---

## 3. Offline-First & Conflict Resolution

- All documents and folders are persisted immediately to local **Hive** boxes (`documents_box_v1`, `folders_box_v1`).
- When network connectivity is established and Firebase is authenticated, `CloudSyncService` executes bi-directional synchronization.
- **Conflict Resolution Rule**: Compares `updatedAt` timestamps. If local is newer, it pushes to Cloud Firestore; if remote is newer, it updates the local Hive record.
