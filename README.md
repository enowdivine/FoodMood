# FoodMood

A Flutter app — running on web — that asks five short questions about the meal you're
planning, then returns five AI-generated suggestions, each with a full recipe. Built for
the Mylestech Solutions engineering bootcamp challenge.

Suggestions come from Groq (`openai/gpt-oss-120b`).

## Features

**Onboarding**
- Five questions: which meal, how you eat, your mood, spice level, anything to avoid
- **Multi-select** where it matters — allergies are pick-as-many-as-apply and skippable
- **"Something else"** free-text on every question, so the presets are a shortcut, not a cage
- Pinned header and footer: the question and the Back/Next buttons never scroll away
- Progress indicator, back navigation, and Next disabled until the step is answered
- Prefilled from your last run, so a returning user edits rather than retypes

**AI suggestions**
- Five meals per run from Groq (`openai/gpt-oss-120b`), each with why it fits and a cook time
- Full recipe per meal: servings, difficulty, ingredients with quantities, numbered method
- **Allergies enforced as a hard constraint** in both the system and user messages
- **Search** — ask for something specific in your own words when the suggestions miss
- **Five more** — regenerate with the same answers, and the model is told what it already
  suggested so it returns genuinely new ideas
- Past suggestions and saved meals are fed back as context, so results improve with use
- Retries once on a rate limit or upstream blip before giving up

**Never breaks**
- Three hand-written fallback recipes cover every failure: no key, no network, a non-200,
  a timeout, malformed JSON, or an unparseable array
- The reason is shown as a calm banner, never a stack trace
- Model output is parsed defensively: markdown fences, prose-wrapped arrays, nesting
  objects, and key-name drift are all handled

**Memory**
- **Saved meals** — bookmark any recipe; kept in local storage between visits
- **History** — every run recorded with its answers, its meals, and a relative timestamp
  ("2 hours ago"), capped at twenty
- Reopen a past run exactly as it was, or re-ask with those answers for fresh ideas
- **Same as last time** on the welcome screen skips the questionnaire entirely
- A page reload loses nothing

**Design**
- Material 3 from one orange seed, in **light and dark**, with a **toggle** that is remembered
- Real photographs per dish from Openverse, with generated gradient artwork as the
  placeholder and the fallback
- Single 560px reading column, shared spacing scale, no web scrollbar
- Empty states, tooltips, and semantics on the option tiles

**Engineering**
- Layered `lib/`: models, data, services, screens, widgets — no file over ~250 lines
- Every shared dependency injected at the root through scopes; no global singletons
- Storage behind interfaces, so tests never touch platform channels
- **20 unit and widget tests**, `flutter analyze` clean

## Setup

1. **Install Flutter** if you don't have it: https://docs.flutter.dev/get-started/install
   Verify with `flutter doctor`.

2. **Add your Groq API key.** Open [`lib/config.dart`](lib/config.dart) and replace the
   placeholder. Free keys: https://console.groq.com/keys

   ```dart
   const String kGroqApiKey = 'PASTE_YOUR_GROQ_API_KEY_HERE';
   ```

3. **Run it:**

   ```bash
   flutter pub get
   flutter run -d chrome
   ```

The app is fully usable without a key — it falls back to three curated recipes and says
why — so the whole flow can be demoed before the API is wired up.

```bash
flutter test      # 20 unit and widget tests
flutter analyze   # clean
```

## What it does

**Welcome** → five questions → **five suggestions** → tap one for the **full recipe** →
bookmark it to keep it.

The questions are: which meal (breakfast, lunch, dinner, snack), how you eat, your mood,
how much heat, and anything to avoid. Every question also offers **"Something else"** with
a free-text field, so the presets are a shortcut rather than a cage. Allergies are
**multi-select and skippable** — you can be avoiding both nuts and dairy, or nothing at
all. The other four are single-select, since you can't be both breakfast and dinner.

While answering, the header and the Back/Next row stay pinned and only the answers
scroll. The results screen offers **Show me five more** (same answers, new ideas) and
**Start over** (back to question one). It deliberately has no back arrow: leaving from
there used to pop the whole flow and discard the suggestions, forcing the questionnaire
again. Should you leave anyway, the welcome screen offers a way straight back to your
last suggestions.

If the suggestions miss, the results screen has a **search box**: ask for something
specific in your own words and it re-asks the model, with your request outranking the
stated mood while diet, spice and allergies stay non-negotiable.

Every completed round is kept in **history** — what was asked, what came back, and when —
so a good set can be reopened later without answering the questions again, and a reload
never loses what you were looking at. Saved meals persist between visits too, and both
are reachable from the app bar on every screen, alongside a **light/dark toggle** that is
also remembered.

## Project structure

```
lib/
  main.dart                        entry point; builds the store, loads it, runs the app
  app.dart                         MaterialApp, light + dark themes, scope wiring
  config.dart                      Groq key, endpoint, model
  theme/app_theme.dart             seed colour, spacing scale, radii, artwork palettes
  models/                          Meal, Question, UserPreferences, SuggestionResult
  data/                            onboarding questions, fallback meals
  services/
    meal_suggestion_service.dart   Groq HTTP client, with retry on transient failures
    meal_response_parser.dart      fence stripping + tolerant JSON decode
    favourites_store.dart          saved meals + the storage interface behind them
    favourites_scope.dart          InheritedNotifier providing the store to the tree
    history_store.dart             past suggestion runs, persisted
    history_scope.dart             InheritedNotifier providing the history store
    photo_service.dart             Openverse image lookup, cached per session
    photo_scope.dart               InheritedWidget providing the photo service
    theme_controller.dart          light/dark choice, persisted
    theme_scope.dart               InheritedNotifier providing the controller
  screens/
    welcome_screen.dart            landing: what the app does, one way in
    questionnaire_screen.dart      owns the flow: onboarding, loading, results
    onboarding_view.dart           one question, pinned header, scrolling answers
    loading_view.dart              waiting state
    results_view.dart              five suggestions, regenerate
    meal_detail_screen.dart        full recipe: ingredients, method, save
    favourites_screen.dart         saved meals, restored between visits
    history_screen.dart            past searches with timestamps, reopenable
  widgets/                         Wordmark, OptionTile, MealCard, MealPhoto,
                                   MealArtwork, NoticeBanner, ThemeToggleButton
  utils/relative_time.dart         "2 hours ago" formatting for history
test/
  meal_response_parser_test.dart   parsing the model's untrusted output
  meal_suggestion_service_test.dart  fallback behaviour, mocked transport
  widget_flow_test.dart            onboarding gating, results, saving, empty states
```

## Architecture

The app is layered so each concern has one home: `models` holds immutable value objects,
`data` holds content (questions, fallback recipes), `services` owns everything touching
the network, storage, or untrusted text, and `screens`/`widgets` stay presentational.

`QuestionnaireScreen` is the only stateful widget driving the flow — a stage enum, a step
index, and one `Set<String>` of answers per question, handed down to child views as typed
data. That is deliberately a plain `StatefulWidget`: the state is small, local, and dies
with the screen, so a state management package would add indirection without buying
anything. Answers are sets rather than nullable strings, which is what makes multi-select
questions fall out for free instead of needing comma-string parsing.

The pieces of state that outlive a screen are explicit. `FavouritesStore` is a
`ChangeNotifier` over a `FavouritesStorage` interface — `SharedPreferencesStorage` in
production, an in-memory fake in tests — created in `main` and passed down through
`FavouritesScope`, an `InheritedNotifier`. Widgets call `FavouritesScope.of(context)` and
rebuild when saved meals change, with no global singleton and no listener bookkeeping.
Swapping local storage for an account-backed API later is one class, not a rewrite.
`HistoryStore` keeps every completed run, newest first and capped at twenty, each entry
carrying its preferences, its meals, its query and its timestamp. Its `latest` entry is
what "back to your last suggestions" reopens, so leaving the results screen or reloading
the page discards nothing, and there is exactly one place this data lives rather than a
separate session cache duplicating it. Fallback results are deliberately not recorded —
history would otherwise fill with the same three offline recipes.

The AI boundary gets the most care, because model output is untrusted text rather than a
stable contract. `MealSuggestionService` posts once to Groq's OpenAI-compatible endpoint
and asks for a raw JSON array, retrying once with a short backoff on the failures worth
retrying — 408, 429, 5xx, and transport errors — while failing fast on a 401 or 404 that
would fail identically the second time. `MealResponseParser` then strips markdown fences,
recovers the array if the model wrapped it in a sentence, unwraps a nesting object,
tolerates key-name drift (`cook_time` / `cookTime` / `time`), and caps the result at the
render limit. The service's public method never throws: a missing key, a non-200, a
timeout, a malformed body, and an unparseable array all resolve to the same
`SuggestionResult` carrying the fallback recipes plus a short human-readable notice, which
the UI shows as a banner. The results screen therefore has one shape to render regardless
of what the network did, and the user never meets a stack trace.

Stated allergies are treated as a hard constraint in both the system and user messages,
naming the allergen and its derivatives explicitly.

Each request also carries context the app already has: the dish names recently suggested,
so a regenerate returns new ideas rather than reshuffling the same ones, and the names of
saved meals, as a signal of what this person actually cooks. Both are capped and passed
as plain text. This is context injection, not retrieval — with twenty history entries,
embeddings and a vector store would be machinery around a list short enough to read
whole. The constraints above it are unaffected: allergies still outrank everything.

## Design

Material 3 from a single orange seed, in **light and dark**. The theme follows the
viewer's system setting until they use the toggle, after which their choice is persisted
and wins. A shared spacing scale in `AppTheme` keeps padding from being
invented per call site, and content sits in one 560px column so the web build reads as an
app rather than a page. The scrollbar Flutter web paints over scrollables is suppressed;
scrolling itself is untouched.

Dishes carry **real photographs**, from loremflickr — keyword-matched Flickr images
served over CORS with no API key, which is what makes them usable from a web build. The
search terms come from the dish name and the `lock` parameter is derived from it too, so
a given meal always resolves to the same photo instead of reshuffling on every rebuild.
The detail screen uses a hero image plus a three-panel strip.

Behind every photo sits **generated artwork** — a gradient picked deterministically from
the dish name, with an icon inferred from keywords in it. It renders while the photo
loads and stays if the request fails, so a dead network degrades to something designed
rather than to a grey box.

## Known limits

- The API key is compiled into the client bundle. Fine for a demo; production would proxy
  the call through a backend so the secret never reaches the browser.
- Allergen exclusion is prompt-enforced and demo-grade — not a substitute for reading
  labels.
- Preferences aren't prefilled from last time; saved meals, history and the theme choice
  do persist.
- Photos are keyword-matched stock, not images of the specific recipe — occasionally
  they'll be loosely related.
