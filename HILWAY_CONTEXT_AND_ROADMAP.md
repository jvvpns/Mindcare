# HILWAY: Master Context & AI Handover Document

> [!IMPORTANT]
> **ATTENTION AI ASSISTANTS:**
> If you are reading this document, you are taking over the HILWAY project. Read this entire file carefully. It contains the exact technical state, non-negotiable architectural rules, and the roadmap for this application. **Do not hallucinate architectural patterns.**

## 1. Project Overview & Aesthetic
**HILWAY** (Holistic Inner Life Well-being and AI for You) is a premium mental health companion app tailored specifically for **Filipino nursing students in Roxas City**.

- **Aesthetic standard ("Soft Premium")**: The UI relies on glassmorphism (blurred overlays via `BackdropFilter`), high border radii (`20px` to `24px`), soft shadows, and muted pastel colors.
- **Living Background System**: The application uses a reactive `HilwayBackground` widget featuring drift-animated gradients and touch-reactive orbs to maintain a "meditative" brand identity.
- **Privacy Core**: All personal health data and AI context (moods, assessments, journal summaries) reside **locally** in encrypted Hive boxes.
- **Cloud Synchronization**: Uses a senior-grade `SyncService` for offline-first synchronization with **Supabase**. Data is queued locally and synced with exponential backoff.
- **Rule**: NEVER hardcode colors or fonts. ALWAYS use `AppColors` and `AppTextStyles` from `lib/core/constants/`.

---

## 2. Technical Stack & Architecture

- **State Management**: `flutter_riverpod`. We use `StateNotifierProvider` for logic and `StateProvider` for UI-local states.
- **Storage**: `hive_flutter`.
  - 🚨 **CRITICAL RULE**: We **DO NOT USE `build_runner`**. All Hive TypeAdapters (`.g.dart` files) must be maintained **MANUALLY**.
- **Backend & Sync**: `supabase_flutter`. Managed via `SyncService` for reliable offline-to-online transitions.
- **AI / ML**: 
  - `google_generative_ai` (Gemini 1.5 Flash) powers Kelly.
  - `IntelligenceService`: Gateway to backend-hosted ML models (Render) for advanced burnout prediction.
- **Integrations**: 
  - `health` package for Apple Health/Health Connect (Sleep & Mindfulness).
  - `flutter_local_notifications` for offline clinical reminders.
- **Routing**: `go_router`.

---

## 3. Core Features Status

### ✅ Completed & Analyzed
- **Kelly Chatbot**: Multi-session support, sentiment detection, and premium Hero-animated glassmorphic UI.
- **Burnout Engine**: Integrated with backend ML and local feature extraction (Sleep, Mood, Meal skips).
- **Academic Planner**: Hybrid Weekly/Monthly calendar with dot activity indicators and 100% offline persistence.
- **Clinical Bento Dashboard**: Vitally-focused layout with "Refuel" (Meal) tracking, "Sleep" pulse, and "Mood" journey logs.
- **Shift Buddy (Phase 8)**: Nursing-specific clinical duty checklist with category templates (Meds, Handover, Routine).
- **Sync Engine**: State-machine based sync with idempotency and background recovery.
- **Health Integration**: Automated sleep duration fetching and mindfulness session logging.
- **Crisis Intervention**: Dedicated UI with localized Roxas City hotlines (KaEstorya) and institutional branding.
- **Mindful Breathing**: Animated gradients and 4-4-4 rhythm tool integrated with HealthKit.

### 🚧 Current Sprint: Mascots & Memory
- **Rive Mascot**: Replacing CustomPaint `KellyOrbMascot` with fluid Rive animations to heighten empathy.
- **Long-term Memory**: Implementing a local retrieval-augmented generation (RAG) light pattern for Kelly.

---

## 4. Localized Support (Roxas City Schools)
The app specifically supports the following institutions, storing affiliated hospital and contact data for each:
1.  **Filamer Christian University, Inc.** (Partner: Capiz Emmanuel Hospital)
2.  **University of Perpetual Help System Pueblo de Panay Campus** (Partner: UPH Clinical Partners)
3.  **St. Anthony College of Roxas City, Inc.** (Partner: St. Anthony College Hospital)
4.  **College of St. John - Roxas** (Partner: CSJ Clinical Partners)

---

## 5. Future Roadmap (Phase 9+)
- **Referral Directory**: Functional directory for local mental health professionals and clinics.
- **Peer Support (Optional)**: Anonymous local peer venting forum with high moderation.
- **Haptic Integration**: Professional-grade vibration feedback for clinical interactions.
- **AI Resilience Pulse**: Real-time TFLite-powered gauge using `CustomPainter` (Local inference fallback).

---

## 6. Technical Stability Rules
1. **Navigation**: ALWAYS use `context.go()` for switching between main app modules to prevent GoRouter duplicate key crashes.
2. **Readability**: Ensure high contrast over the animated mesh background.
3. **Durable Sync**: When modifying a model, ensure its `toMap()` and `fromMap()` are updated for Supabase compatibility.

---

## 7. Next Steps for Developer
1. **Referral Directory**: Implement the UI and data source for the local professional directory.
2. **Rive Mascot**: Finalize Rive state machine integration in `lib/chatbot/widgets/`.
