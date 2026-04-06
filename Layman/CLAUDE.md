# CLAUDE.md — Layman iOS App

> AI context file for Antigravity / Claude Code / Cursor / Windsurf / GitHub Copilot.
> Read this before touching any file. It distills everything you need to navigate the codebase confidently.

---

## Project Summary

**Layman** is a SwiftUI iOS app that makes business, tech & startup news easy to understand.
It fetches real articles from NewsData.io, rewrites headlines with Groq AI, and lets users chat with an AI bot about any article.

**Stack**: SwiftUI · Supabase (auth + DB) · NewsData.io (news) · Groq llama3 (AI) · SFSafariViewController

---

## Architecture: MVVM

```
Views (SwiftUI)  →  ViewModels (@MainActor ObservableObject)  →  Services / Models
```

- **Views** are purely declarative — zero business logic
- **ViewModels** own all state and async work
- **Services** are singletons with async/await API calls
- **`@EnvironmentObject`** at root: `AuthViewModel`, `SavedArticlesViewModel`

---

## File Map

```
Layman/
├── LaymanApp.swift              # @main, injects environment objects, triggers StreakManager
├── AppConfig.swift              # API keys (loaded from Info.plist / xcconfig)
├── Model/
│   ├── Article.swift            # Codable article; maps NewsData.io API fields
│   ├── AppUser.swift            # Auth user; AuthState enum
│   ├── SavedArticle.swift       # Supabase row; SavedArticleInsert payload
│   ├── ChatMessage.swift        # ChatMessage + Groq API request/response models
│   ├── ContentCard.swift        # 3-part swipeable summary cards + Article extension
│   └── Supabase.swift           # Commented-out SDK version (for reference)
├── ViewModel/
│   ├── AuthViewModel.swift      # login, signup, signout, session check
│   ├── HomeViewModel.swift      # featured articles, today's picks, search, pagination
│   ├── ArticleDetailViewModel.swift  # AI content card generation, share, safari
│   ├── ChatViewModel.swift      # message history, send, suggested questions
│   └── SavedArticlesViewModel.swift  # fetch/unsave, local search filter
├── Views/
│   ├── RootView.swift           # Routes on AuthState: loading→SplashView, unauth→WelcomeView, auth→MainTabView
│   ├── SplashView.swift         # Shown while session check runs
│   ├── WelcomeView.swift        # Gradient screen + swipe-to-start slider → AuthView
│   ├── AuthView.swift           # Email/password sign-up & login (toggleable mode)
│   ├── MainTabView.swift        # ZStack-based 3-tab bar (Home | Saved | Profile)
│   ├── HomeView.swift           # Featured carousel + Today's Picks list + search
│   ├── FeaturedCarouselView.swift   # Horizontal swipeable card carousel with image overlay
│   ├── ArticleRowView.swift     # Compact row: thumbnail left, headline right
│   ├── ArticleDetailView.swift  # Full detail: top bar → headline → photo → 3 swipeable cards → Ask Layman
│   ├── ChatView.swift           # AI chatbot: message list, suggestion chips, input bar
│   ├── SavedView.swift          # Bookmarked articles list with toggle search
│   └── ProfileView.swift        # Avatar, reading streak, stats, settings, sign out
├── Services/
│   ├── NewsService.swift        # NewsData.io fetcher + concurrent AI headline simplification
│   ├── SupabaseManager.swift    # Supabase SDK wrapper (auth + saved_articles CRUD)
│   └── AIService.swift          # Groq llama3: headlines, content cards, chat, suggested questions
├── Components/
│   ├── AsyncImageView.swift     # Remote image with shimmer placeholder + error state
│   ├── EmptyStateView.swift     # Reusable icon + title + message empty state
│   └── ShimmerModifier.swift    # `.shimmering()` View modifier for skeleton loading
└── Utils/
    ├── AppColors.swift          # Design tokens: colors, gradients, fonts
    ├── LaymanError.swift        # Typed error enum with user-friendly descriptions
    └── StreakManager.swift      # Daily reading streak via UserDefaults
```

---

## Design System

All colors and fonts live in `AppColors` and `AppFonts` in `Utils/AppColors.swift`.

| Token | Value | Usage |
|-------|-------|-------|
| `accentOrange` | `#CC6130` | "made simple" text, buttons, bookmark fill |
| `backgroundCream` | `#FBF5F0` | App-wide background |
| `gradientTop/Mid/Bottom` | Peach → Orange | Welcome screen gradient |
| `textPrimary` | `#1A1A1A` | Headlines, body |
| `textSecondary` | `#6B6B6B` | Subheadlines, labels |
| `cardSurface` | `#F8F0E8` | Non-active content cards |

**Fonts**: `.system(design: .serif)` for logo/brand; `.system(design: .default)` for body.

---

## API Integrations

### NewsData.io
- Base URL: `https://newsdata.io/api/1/news`
- Key param: `?apikey=...`
- Categories: `technology,business` (featured), `technology,business,science` (picks)
- Free: 200 requests/day

### Groq (AI)
- Endpoint: `https://api.groq.com/openai/v1/chat/completions`
- Model: `llama3-8b-8192` (free tier)
- Used for:
  1. `simplifyHeadline(original)` → casual ≤52 char headline
  2. `generateContentCards(for article)` → 3 × 2-sentence cards (28–35 words each)
  3. `generateSuggestedQuestions(for article)` → 3 chat prompt chips
  4. `chatResponse(context, history, question)` → 1–2 sentence answer

### Supabase
- Official Supabase Swift SDK v2
- Auth: Handled by SDK (`client.auth.signUp`, `client.auth.signIn`, `client.auth.resetPasswordForEmail`, etc.)
- DB: PostgREST builder via SDK (`client.from("saved_articles")`)
- Sessions: Persisted automatically in **iOS Keychain** (no manual UserDefaults needed)
- Auth State: Reactive listener (`client.auth.authStateChanges`) handles token refreshes and edge cases seamlessly

---

## Key Patterns

### Article Detail Layout Order (per spec)
```
Fixed top bar (back, link, bookmark, share)
↓
Headline — bold, 2-line max
↓  
Article photo — full width
↓
"The Simple Version" label
↓
3 swipeable content cards (140pt height each, 6 lines)
↓
Fixed bottom: "Ask Layman" button
```

### Bookmark Flow
```
CircleIconButton tap →
  UIImpactFeedbackGenerator.impactOccurred() →
  savedVM.isArticleSaved(article) check →
  SupabaseManager.saveArticle / unsaveArticle →
  savedVM.fetchSavedArticles (refresh list)
```
> Optimistic UI: UI updates first, reverts on error.

### AI Content Cards
- `ArticleDetailViewModel.init()` calls `AIService.generateContentCards(for:)` immediately
- Shows `ContentCardSkeletonView` while loading (shimmer animation)
- Falls back to `article.contentCards` (computed from raw description text) if AI fails

### Headline Simplification
- `NewsService.fetchFeaturedArticles()` and `fetchTodaysPicks()` both call `simplifyHeadlines(for:)`
- Uses `AsyncSemaphore(limit: 5)` to run ≤5 concurrent Groq calls
- Falls back to `originalHeadline` silently on any AI error

### Reading Streak
- `StreakManager.shared` is initialized in `LaymanApp.init()` (triggers on every app launch)
- Stores `streak_last_open_date` and `streak_count` in `UserDefaults`
- Same-day open: no change. Next-day: +1. Gap: reset to 1.

---

## Secure Credential Management

Keys are **never hardcoded** in production. Setup:
1. Copy `Resources/Config.xcconfig.template` → `Resources/Config.xcconfig`
2. Fill in `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NEWSDATA_API_KEY`, `GROQ_API_KEY`
3. In Xcode: set Debug/Release configuration to `Config.xcconfig`
4. Keys referenced in `Info.plist` as `$(KEY_NAME)` — passed to `AppConfig` at runtime
5. `Config.xcconfig` is gitignored

---

## Development Notes

- **Minimum deployment**: iOS 17 (uses `scrollTargetBehavior`, `navigationDestination(item:)`)
- **Build system**: Xcode 15+, no SPM packages
- **Concurrency**: Swift structured concurrency (`async/await`, `TaskGroup`, `Actor`)
- **Dependencies**: Supabase Swift SDK (via SPM)
- **Linting convention**: `// MARK: -` sections throughout, alphabetical CodingKeys

---

## Supabase Schema

```sql
create table public.saved_articles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  article_id  text not null,
  article_data jsonb not null,
  saved_at    timestamptz not null default now(),
  unique(user_id, article_id)
);
-- RLS: users can only SELECT/INSERT/DELETE their own rows
```

Full schema in `Layman/Resources/supabase_schema.sql`.
