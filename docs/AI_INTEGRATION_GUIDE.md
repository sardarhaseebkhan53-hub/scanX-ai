# ScanX AI — Pluggable AI Integration Guide

ScanX AI features a pluggable AI Engine (`PluggableAIService` in `lib/services/ai/ai_service.dart`) that enables developers and users to switch between cloud-based LLMs (**Google Gemini API** and **OpenAI GPT-4o API**) or operate entirely offline using an intelligent **On-Device Heuristic Engine**.

---

## 1. Supported AI Providers

### A. Google Gemini API (Default)
- **Model**: `gemini-1.5-flash`
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
- **Configuration**:
  1. Generate an API Key in Google AI Studio (`https://aistudio.google.com/`).
  2. Open ScanX AI -> **Settings -> Active AI Provider -> Google Gemini API**.
  3. Tap **Configure API Key** and paste your key. The key is encrypted in **Android Keystore** via Flutter Secure Storage.

### B. OpenAI GPT-4o API
- **Model**: `gpt-4o-mini`
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Configuration**:
  1. Generate an API Key in OpenAI Dashboard (`https://platform.openai.com/api-keys`).
  2. Select **OpenAI GPT-4o API** in ScanX AI Settings and paste your secret key (`sk-...`).

### C. On-Device Heuristic Engine (Offline / Zero-Config Mode)
- When no API key is provided, or when the device is offline, ScanX AI automatically delegates analysis to `_runOnDeviceFallback()`.
- Uses regex pattern matching and line-frequency analysis to build executive summaries, extract invoice line items, and suggest relevant folders.

---

## 2. AI Prompt Templates & Structured JSON Output

### Receipt & Invoice Extraction Schema

When user invokes `promptType: 'invoice'` or `promptType: 'receipt'`, ScanX AI prompts the LLM to return valid JSON conforming to this schema:

```json
{
  "invoiceNumber": "INV-2026-08942",
  "vendorName": "Sardar Haseeb Technologies",
  "date": "2026-08-02",
  "subtotal": 1450.00,
  "tax": 116.00,
  "totalAmount": 1566.00,
  "currency": "USD",
  "items": [
    {
      "description": "Enterprise API Gateway License",
      "quantity": 1,
      "unitPrice": 1200.00,
      "totalPrice": 1200.00
    }
  ],
  "suggestedFolderName": "Invoices 2026",
  "suggestedTitle": "SardarHaseeb_Invoice_8942"
}
```

### Executive Summary Prompt
```text
Analyze this scanned document text and provide a concise, professional executive summary with bullet points highlighting key deliverables, dates, and amounts.
```

### Explain in Simple Terms Prompt
```text
Explain this document in simple, clear terms for a layperson. Highlight important legal or financial obligations.
```
