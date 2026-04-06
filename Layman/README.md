# Layman 📰

> Business, tech & startups — **made simple.**

Layman is an iOS app that fetches real news, rewrites headlines in plain English using AI, and lets users chat with an AI bot about any article. Built with SwiftUI, Supabase, and Groq.

---

## Screenshots

| Welcome | Home | Article Detail | Ask Layman | Saved |
|---|---|---|---|---|
| *(swipe-to-start)* | *(carousel + picks)* | *(3 swipeable AI cards)* | *(AI chatbot)* | *(bookmarks)* |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Auth & DB | Supabase Swift SDK v2 |
| News Feed | NewsData.io REST API |
| AI | Groq `llama3-8b-8192` (free tier) |
| Architecture | MVVM — `@MainActor ObservableObject` ViewModels |
| AI Dev Tool | **Antigravity** |

---

## AI Development Workflow

This project was built using **[Antigravity](https://antigravity.dev)** as the primary AI coding assistant — listed as an accepted tool. The workflow involved:

- Prompting Antigravity to scaffold MVVM architecture, service layers, and SwiftUI views
- Iterating on UI components to match prototype mockups pixel-by-pixel
- Using Antigravity to debug Supabase SDK migration, Groq token overflow, and content card parsing
- The `CLAUDE.md` context file guided the AI on architecture rules, design tokens, and API shapes throughout the session

---

## Project Structure

```
Layman/
├── AppConfig.swift              # Reads API keys from Info.plist (injected via xcconfig)
├── Model/                       # Article, AppUser, SavedArticle, ChatMessage, ContentCard
├── ViewModel/                   # AuthViewModel, HomeViewModel, ArticleDetailViewModel, ChatViewModel, SavedArticlesViewModel
├── Views/                       # WelcomeView, AuthView, HomeView, ArticleDetailView, ChatView, SavedView, ProfileView
├── Services/
│   ├── NewsService.swift        # NewsData.io + concurrent AI headline simplification
│   ├── SupabaseManager.swift    # Supabase SDK wrapper (auth + saved_articles CRUD)
│   └── AIService.swift          # Groq: headlines, content cards, chat, question suggestions
├── Components/                  # AsyncImageView, EmptyStateView, ShimmerModifier
└── Resources/
    ├── Config.xcconfig.template # Key template — copy and fill in your keys
    └── supabase_schema.sql      # Supabase table setup
```

---

## Setup Instructions

### 1. Clone the repo

```bash
git clone https://github.com/your-username/Layman.git
cd Layman
open Layman.xcodeproj
```

### 2. Configure API Keys

```bash
cp Layman/Resources/Config.xcconfig.template Layman/Resources/Config.xcconfig
```

Open `Config.xcconfig` and fill in the four keys:

```
SUPABASE_URL     = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJh...your_anon_key
NEWSDATA_API_KEY = pub_...your_key
GROQ_API_KEY     = gsk_...your_key
```

### 3. Set Xcode Configuration

In Xcode:
- Select the **Layman** project in the navigator
- Go to **Info → Configurations**
- Set **Debug** and **Release** to use `Config.xcconfig`

### 4. Supabase Setup

Run the SQL in `Layman/Resources/supabase_schema.sql` in your Supabase project's SQL editor:

```sql
create table public.saved_articles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  article_id  text not null,
  article_data jsonb not null,
  saved_at    timestamptz not null default now(),
  unique(user_id, article_id)
);

-- Row Level Security
alter table public.saved_articles enable row level security;

create policy "Users can manage their own saved articles"
  on public.saved_articles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

In Supabase Dashboard → **Authentication → Settings**:
- Disable email confirmation for easier testing (or enable to test full OTP flow)

### 5. Build & Run

Select an **iPhone 17 Pro** simulator (or real device), press **⌘R**.

---

## API Keys — Where to Get Them

| Service | Where |
|---|---|
| **Supabase** | [supabase.com](https://supabase.com) → New project → Settings → API |
| **NewsData.io** | [newsdata.io](https://newsdata.io) → Register → Dashboard → API Key |
| **Groq** | [console.groq.com](https://console.groq.com) → API Keys → Create |

All three services have **free tiers** sufficient to run the app.

---

## Security

- **No secrets in source code.** All API keys are injected at build time from `Config.xcconfig` via Info.plist
- `Config.xcconfig` is listed in `.gitignore` and never committed
- The `Config.xcconfig.template` with placeholder values is the only config file in the repo
- Supabase session tokens are stored in **iOS Keychain** automatically by the Supabase Swift SDK (not UserDefaults)

---

## Features

### Authentication
- Email/password sign-up and login via Supabase Auth
- Password validation (min 8 characters)
- Forgot password (email reset link)
- Resend email confirmation
- Persistent session via Keychain — stays logged in across app launches
- Auth state listener for real-time session updates

### Home Feed
- Featured article carousel (horizontal swipe, image overlay, gradient for readability)
- "Today's Picks" vertical list
- AI-simplified headlines via Groq (concurrent, with fallback to originals)
- Full-text search

### Article Detail
- Headline-first layout (as per spec)
- Full-width article photo
- **3 swipeable AI-generated content cards** — 2 sentences each (28–35 words), exactly 6 lines
- Smart fallback cards from article content when AI is unavailable
- Retry AI button when fallback is active
- Original article opens in **in-app Safari sheet** (not leaving the app)
- Bookmark to Supabase with haptic feedback

### Ask Layman (AI Chatbot)
- Real Groq API (not mocked) with article context
- 3 auto-generated question suggestions per article
- Responses limited to 1–2 sentences in simple language
- Smooth bubble animations, typing indicator
- Orange suggestion chips, bot avatar, mic placeholder

### Saved
- Bookmarked articles synced to Supabase
- Swipe-to-delete with optimistic UI
- Local search filter

### Profile
- Reading streak tracker
- Notifications permission handling
- Rate app (StoreKit)
- Support email (mailto)
- Privacy policy (Safari sheet)
- Sign out with confirmation

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Active internet connection
