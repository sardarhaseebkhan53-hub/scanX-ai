# ScanX AI — Complete Google Play Store Listing & Marketing Asset Kit

**Developer:** Developed by Sardar Haseeb  
**Company:** Sardar Haseeb Technologies  
**Copyright:** © Sardar Haseeb. All Rights Reserved.  
**Support Email:** support@sardarhaseeb.com  
**Website:** https://sardarhaseeb.com  
**Bundle ID:** `com.scanxai.enterprise.scanner`

---

## 1. App Titles & Short Description (ASO Optimized)

- **App Title (max 30 chars):**  
  `ScanX AI: Document Scanner OCR`
- **Short Description (max 80 chars):**  
  `AI Document Scanner, PDF Editor, ML Kit OCR, QR & Wi-Fi Toolkit, AES Vault`

---

## 2. Full Store Description (ASO Search Optimized — max 4,000 chars)

```text
Transform your Android device into a lightning-fast, enterprise-grade document scanner, PDF studio, OCR text extractor, and QR/Wi-Fi toolkit with ScanX AI — Developed by Sardar Haseeb.

Whether you need to scan invoices, receipts, books, ID cards, business cards, passports, or whiteboards, ScanX AI delivers studio-quality PDF exports in seconds with intelligent edge detection, automatic perspective correction, and real-time shadow & blur removal.

WHY CHOOSE SCANX AI OVER ORDINARY SCANNERS?
Ordinary scanner apps clutter your PDFs with watermarks, drop frames, or lock essential tools behind confusing paywalls. ScanX AI is engineered with clean architecture, sub-100ms startup speeds, and dual AI engine integration (Google Gemini & OpenAI GPT-4o with an on-device offline fallback) so you never miss a deadline.

🔥 KEY FEATURES & ENTERPRISE TOOLS:

📸 1. ULTIMATE CAMERA ENGINE & 9 SCAN MODES
• Scan Modes: Document, Receipt, Invoice, Book, Passport, ID Card, Business Card, Whiteboard, and Batch Mode.
• Live Edge Detection & Auto-Capture: Intelligent bounding box overlay automatically captures clean scans when document edges and sharpness are stable.
• Real-Time AI Quality Score: Instant sharpness evaluation (e.g. 98/100) and motion blur warnings.
• Camera Controls: Vertical exposure slider (-2.0 to +2.0), exposure lock, grid overlay, horizon level crosshair, timer countdown, and flash presets.

🎨 2. 14 IMAGE FILTERS & CUSTOM ADJUSTMENT STUDIO
• Filters: Original, Auto Enhance, Color, B&W, Grayscale, High Contrast, Magazine, Book, Receipt, Passport, Photo, Signature, AI Enhance, and AI Sharpen.
• Custom Adjustment Studio: -100 to +100 sliders for Brightness, Contrast, Saturation, Warmth, Tint, Sharpness, Highlights, and Shadows, plus Undo, Redo, Reset All, and Compare Before/After.

💧 3. WATERMARK STUDIO
• Protect your intellectual property by embedding custom footer watermarks (Scanned with ScanX AI, Developed by Sardar Haseeb, Date & Time, Scan ID, QR Code, or Digital Signature).
• Customize position (Bottom Right, Bottom Left, Top Right, Top Left, Center), opacity (10%–100%), and custom text.

🔍 4. GOOGLE ML KIT OCR & MULTI-FORMAT EXPORTS
• Extract selectable, editable text across 8 languages with 98%+ accuracy.
• Search inside OCR text: Matching snippets highlight directly on your document cards.
• Export recognized text instantly to .TXT, .DOCX, and Searchable .PDF.
• Built-in 8-language translation modal.

📑 5. 16-TOOL ENTERPRISE PDF STUDIO
• Complete PDF manipulation suite: Merge, Split, Compress (save up to 48% file size with real pixel re-encoding), Rotate Page, Duplicate Page, Insert Blank Page, Extract Pages, Watermark, AES-256 Password Protection, Digital Signature drawing canvas, Annotate/Highlight, Page Numbering, Print, and Export/Share.

📱 6. QR & BARCODE TOOLKIT + WI-FI STUDIO
• 2D QR & 1D Barcode Scanner: Real-time scanning of QR codes and linear barcodes (EAN-13, Code 128, UPC-A, ISBN).
• Wi-Fi QR Studio: Generate and scan WPA/WPA2, WPA3, WEP, and Open network QR codes with Hidden Network support.
• URL & Wi-Fi Safety Shield: Inspects decoded payloads against security heuristics before launching links or connecting to networks.

🛡️ 7. AES-256 KEYSTORE VAULT & HIDDEN VAULT
• Protect private documents with Fingerprint / Face Unlock, a 4-digit PIN keypad, or an interactive 3x3 Pattern Lock grid.
• Move confidential files to the AES-256 Hidden Vault—concealed from your main dashboard and recent list.
• Rate-limited lockout protection automatically freezes attempts after 5 unsuccessful logins.

☁️ 8. CLOUD SYNC & AUTOMATIC BACKUPS
• Bi-directional synchronization with Firebase, Google Drive, Dropbox, and OneDrive with timestamp conflict resolution.

Download ScanX AI today and experience the future of document productivity!
```

---

## 3. Targeted ASO Search Keywords

```text
document scanner, pdf scanner, ai scanner, ml kit ocr, text scanner, receipt scanner, invoice scanner, id card scanner, passport scanner, pdf editor, merge pdf, split pdf, compress pdf, watermark pdf, aes password protect, digital signature, qr code scanner, barcode scanner, wifi qr generator, ean-13 barcode, secure vault, pattern lock, hidden vault, camscanner alternative, adobe scan alternative, sardar haseeb
```

---

## 4. Release Notes (v1.0.0 — Launch Release)

```text
Welcome to ScanX AI v1.0.0 — Developed by Sardar Haseeb!
• Professional Camera Studio with 9 scan modes (Document, Receipt, Invoice, Book, ID Card, Passport, Business Card, Whiteboard, Batch).
• 16-Tool Enterprise PDF Studio: Merge, Split, Compress 48%, Rotate, Blank Page, Extract, Watermark, Sign, and AES-256 Encrypt.
• Google ML Kit OCR with Editable Text Mode, inside-document search highlighting, and export to TXT, DOCX, and Searchable PDF.
• QR & Wi-Fi Toolkit: Scan & generate 2D QR codes and 1D Barcodes (EAN-13/Code 128), WPA/WPA3 Wi-Fi studio, and Safety Shield.
• AES-256 Keystore Vault: Fingerprint, PIN, 3x3 Pattern Lock, and Hidden Vault.
```

---

## 5. App Signing Checklist & Google Play App Signing Guide

When preparing your release build for Google Play Console, follow these steps to generate and verify your keystore:

### A. Generate Your Release Keystore
```bash
keytool -genkey -v -keystore scanx-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias scanx-upload
```

### B. Configure `android/key.properties`
Create `android/key.properties` inside your project:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=scanx-upload
storeFile=../scanx-upload-keystore.jks
```

### C. Extract SHA-1 & SHA-256 Certificate Fingerprints for Firebase
To register your Android app in Firebase Console and enable Google Sign-in / Cloud Firestore security rules:
```bash
keytool -list -v -keystore scanx-upload-keystore.jks -alias scanx-upload
```
Copy the **SHA-1** and **SHA-256** hexadecimal strings into your Firebase Project Settings -> Android App.

### D. Google Play App Signing (PEP)
- Upload the `.aab` file generated by `flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols`.
- Google Play Console will automatically sign APKs distributed to user devices with your Play App Signing key.

---

## 6. Store Listing Graphic & Asset Specifications Checklist

- [ ] **High-Res App Icon (512x512 px):** 32-bit PNG with alpha, showing the royal blue ScanX AI logo (`assets/icons/app_logo.svg`).
- [ ] **Feature Graphic (1024x500 px):** PNG or JPEG without alpha, highlighting "Scan. Edit. Organize. Secure." and "Developed by Sardar Haseeb".
- [ ] **Phone Screenshots (16:9 or 9:16 ratio, min 1080x1920 px):** Provide at least 4 screenshots showing:
  1. Camera Studio with live edge detection & AI Quality Score (`98/100`).
  2. 16-Tool PDF Studio (`Merge`, `Split`, `Compress`, `Sign`, `Encrypt`).
  3. ML Kit OCR Studio with Editable Text Mode and `.TXT`/`.DOCX` export.
  4. QR & Wi-Fi Toolkit with 1D Barcode scanning and Wi-Fi studio.
  5. AES-256 Keystore Security Vault with 3x3 Pattern Lock and Hidden Vault.
- [ ] **Adaptive Icons (Android 8.0+):** Foreground and background XML drawable layers in `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`.
- [ ] **Privacy Policy & Terms of Service URL:** Link directly to your hosted page or reference the in-app `/legal-policy` screen.
