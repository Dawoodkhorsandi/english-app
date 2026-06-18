# Engram — UI/UX Design Brief

## What is Engram?

Engram is a mobile app for learning English vocabulary through AI-generated content and spaced repetition. The name comes from neuroscience — an engram is the physical trace a memory leaves in the brain. The app pairs with a Telegram bot that pushes daily lessons (words, idioms, collocations, mini-stories, grammar tips) and uses SRS (Spaced Repetition System) to surface cards at the moment you're about to forget them.

The target audience is Persian-speaking learners (Iran-based), ranging from beginner to advanced. Many users first encounter the system through the Telegram bot and later install the app for a richer, self-paced experience.

---

## Brand Identity

- **Name**: Engram
- **Concept**: Memory trace / neural pathway formation
- **Seed color**: `#2563EB` (modern blue) — generates the full Material 3 palette
- **Personality**: Smart but not academic. Calm but motivating. The feeling of a personal tutor who knows exactly what you need to practice next.
- **Deep link scheme**: `engram://`

---

## Current Information Architecture (4 tabs)

```
[Home]          [Learn]         [Library]       [Profile]
   |               |               |               |
   |               |               |               |
   ├─ Greeting     ├─ Decks        ├─ Words        ├─ Stats summary
   │  (name+streak)│  └─ Detail    │  └─ Detail    │  (streak/words/mastered)
   │               │     └─ Study  │     sheet     │
   ├─ Review Hero  │        swipe  │               ├─ Quiz accuracy
   │  card (count) │               ├─ Bookmarks    │
   │  └─ Swipe     ├─ Grammar     │  └─ Detail    ├─ Activity heatmap
   │     session   │  └─ Lessons   │     sheet     │
   │               │     └─ Detail │               ├─ Leaderboard
   ├─ Quick        │        +quiz  ├─ Dictionary   │  preview (top 3)
   │  practice     │               │  search       │  └─ Full leaderboard
   │  (Quiz/Word/  ├─ Content      │               │     └─ Profile detail
   │   Random)     │  ├─ Idioms    │               │        (versus compare)
   │               │  ├─ Collocations               │
   ├─ Deck         │  ├─ Stories   │               ├─ Achievements
   │  progress     │  └─ Tips      │               │
   │  rows         │               │               ├─ [Settings]
   │               │               │               │  (pushed route)
   └─ Weekly       │               │               │
      stats        │               │               │
                   │               │               │
                [Settings gear on Home + Profile AppBar]
```

### Pushed Full-Screen Routes
- **Review Session** (from Home hero card) — swipe-card flashcard engine
- **Quiz** (from Home quick practice) — multiple choice with HMAC token
- **Practice** (from Home quick practice) — random word/idiom/collocation/story/tip
- **Deck Detail** (from Learn/Home) — box distribution, study button
- **Deck Study** (from Deck Detail) — swipe-card session for one deck
- **Grammar Lesson** (from Grammar list) — pattern + explanation + interactive MCQ
- **Content Detail** (from Learn content grid) — draggable bottom sheet
- **Word Detail** (from Library word tap) — bottom sheet with "Open in Dictionary"
- **Leaderboard** (from Profile) — full ranking with metric switching
- **Profile Detail** (from Leaderboard) — head-to-head stat comparison + kudos
- **Settings** (from AppBar gear) — level, display name, toggles, intervals, logout
- **Login** — Telegram short code or email/password

---

## Data Available Per Screen

### Home Screen
| Data | Source | Fields |
|------|--------|--------|
| User name | Auth state | `name` (from JWT session) |
| Current streak | `/api/stats` | `current_streak` (days) |
| Review due count | `/api/review/count` | `count` (integer) |
| Deck progress | `/api/decks` | `id, name, total, mastered, due, progressPct` per deck |
| Stats summary | `/api/stats` | `words, mastered, quiz_answered, quiz_correct, quiz_pct` |

### Learn Screen
| Data | Source | Fields |
|------|--------|--------|
| Decks | `/api/decks` | `id, name, description, total, mastered, due, progressPct` |
| Deck detail | `/api/decks/detail?deck=` | `+ newCount, nextReview, boxes[{box,label,count}]` |
| Deck study cards | `/api/decks/study?deck=&limit=30` | `term, definition, example, persian, pronunciation, mnemonic, box` |
| Grammar lessons | `/api/grammar` | `id, order, level, title` |
| Grammar lesson | `/api/grammar/lesson?id=` | `+ pattern, explanation, examples[], tip, practice[{q,options,answer}]` |
| Content (idiom/collocation/story/tip) | `/api/content?kind=` | `term, meaning, text, sent_at` |
| Practice (random) | `/api/practice?kind=` | `term, text, available` |

### Library Screen
| Data | Source | Fields |
|------|--------|--------|
| Vocabulary list | `/api/vocab?offset=&limit=&q=&bookmarks=` | `term, meaning, mastery(new/learning/mastered), bookmarked` |
| Word detail | `/api/vocab/card?term=` | `term, text (full card), meaning` |
| Dictionary | `/api/dictionary?q=` | `word, pos, pronunciation, persian, definition, example` per result |
| Bookmark toggle | `POST /api/bookmark` | `{term, action: "add"/"remove"}` |

### Profile Screen
| Data | Source | Fields |
|------|--------|--------|
| Stats | `/api/stats` | `current_streak, longest_streak, words, mastered, verbs, quiz_answered, quiz_correct, quiz_pct, idioms, collocations, stories, tips, active_days, activity_days[], activity_counts{date:count}, level, paused, member_since` |
| Achievements | `/api/stats` | `achievements[{id,name,icon,description,category,unlocked,progress,target}], ach_unlocked, ach_total` |
| Leaderboard | `/api/leaderboard?metric=` | `metric, rows[{id,name,rank,value,isMe,hasName}], me{same}` |
| Profile detail | `/api/profile?id=` | `name, isMe, kudos{count,gaveByMe}, heatmap{date:count}, metrics[{key,label,me,them,better}], achievements{my_total,my_unlocked,their_total,unlocked}` |
| Kudos toggle | `POST /api/kudos` | `{id}` → `{count, gaveByMe}` |

### Analytics (EXISTS but not wired to any screen yet)
| Data | Source | Fields |
|------|--------|--------|
| Word breakdown | `/api/analytics` | `word_breakdown[{label,count}]` (new/learning/mastered/bookmarked) |
| Quiz accuracy trend | `/api/analytics` | `quiz_accuracy_trend[{date,correct,total,pct}]` |
| Activity by hour | `/api/analytics` | `activity_by_hour[{hour,count}]` (0-23) |
| Weekly velocity | `/api/analytics` | `weekly_velocity[{week,count}]` |
| Content diversity | `/api/analytics` | `content_diversity[{label,count}]` (word/idiom/collocation/story/tip) |

### Review Summary (EXISTS but not wired)
| Data | Source | Fields |
|------|--------|--------|
| Level suggestion | `/api/review/summary` | `suggest(bool), currentLevel, currentLabel, direction(up/down), accuracy(%), targetLevel, targetLabel, message` |

### Settings
| Data | Source | Fields |
|------|--------|--------|
| Settings | `GET /api/settings` | `level, name(display), paused, interval(minutes), toggles{tts,tips,quiz,idiom,collocation,story,review,daily_review,digest}, levels[], levelLabels{}` |

---

## Available Content Types

| Kind | Description | Count tracked in stats |
|------|-------------|----------------------|
| `word` | English vocabulary with definition, example, Persian translation, pronunciation | `words`, `mastered` |
| `idiom` | English expressions/idioms with meaning and context | `idioms` |
| `collocation` | Word pairs that naturally go together | `collocations` |
| `story` | Short reading comprehension passages | `stories` |
| `tip` | Quick grammar/usage tips | `tips` |

---

## SRS (Spaced Repetition) System

The review engine uses a modified Leitner box system:
- **5 boxes** with intervals: Box 1 (0d), Box 2 (1d), Box 3 (3d), Box 4 (7d), Box 5 (21d)
- **Known** → move to next box (longer interval)
- **Forgot** → back to Box 1 (immediate review)
- **Mastered** = in Box 5 for 21+ days
- Cards carry: `term, meaning/definition, pronunciation, persian, example, mnemonic`
- The swipe interaction: left = forgot, right = knew it, tap = flip card

---

## Achievement System

Achievements have categories and progress tracking:
- Each has: `id, name, icon(emoji), description, category, unlocked(bool), progress, target`
- Examples: streak milestones, word count milestones, quiz accuracy, mastery goals
- Progress bar = `progress / target`

---

## Leaderboard System

- **4 metrics**: All-time words, This week, Today, Mastered
- Privacy-first: no profile photos, users identified by display name or auto-generated "Adjective Animal" combo
- Versus comparison: tap any user to see head-to-head metric bars
- Kudos: clap for other users (notifies them via Telegram)

---

## Deck System

Available vocabulary decks:
- **504 Absolutely Essential Words** — classic vocabulary list
- **Barron's GRE 333** — GRE preparation
- **Phrasal Verbs** — common phrasal verbs
- **Business English** — professional vocabulary
- **Academic Word List** — academic register
- **IELTS/TOEFL** — test preparation

Each deck has Leitner box tracking per word.

---

## Design Challenge

Design a complete, production-ready mobile app for Engram. You have full creative freedom — the current implementation is functional but visually basic (Material 3 defaults with minimal customization). The goal is to create something that feels as polished and distinctive as Duolingo, Anki, or Memrise, but with its own identity.

### What to Design

1. **Onboarding flow** (new concept — doesn't exist yet)
   - First launch experience
   - Language level selection (beginner/intermediate/upper-intermediate/advanced)
   - Interest selection (which content types they want)
   - Telegram connection prompt (or skip)
   - Goal setting (how many words per day? streak target?)

2. **Home tab** — the "what should I do now?" command center
   - Greeting with streak visualization (not just a number — make it feel alive)
   - Review hero section (due count, urgency indicators, one-tap to start)
   - Daily goal progress (words learned today vs target)
   - Quick practice entry points
   - Deck progress at a glance
   - Weekly/daily rhythm visualization

3. **Learn tab** — structured learning paths
   - Deck cards with visual progress (not just a progress bar — think about rings, meters, paths)
   - Grammar lesson cards with difficulty indicators
   - Content type browsing (idioms/collocations/stories/tips)
   - Consider: could this be a "learning path" or "skill tree" instead of a flat list?

4. **Review/Swipe session** — the core learning interaction
   - Flashcard with flip animation
   - Swipe gestures with visual feedback (color shift, rotation, overlay labels)
   - Progress indicator (cards remaining, known/forgot ratio)
   - Completion screen with stats and celebration
   - Consider: what if the card showed more than just text? Pronunciation button? Word family? Usage frequency?

5. **Library tab** — personal vocabulary reference
   - Word list with mastery indicators
   - Word detail view (definition, example, pronunciation, Persian, mnemonic)
   - Bookmarks collection
   - Dictionary lookup with rich results
   - Consider: word relationships? Similar words? Words learned on the same day?

6. **Profile tab** — personal progress dashboard
   - Stats visualization (not just numbers — charts, graphs, visual metaphors)
   - Activity heatmap (GitHub-style contribution graph)
   - Achievement showcase (locked/unlocked states, progress toward next)
   - Leaderboard preview with social elements
   - Level and streak celebration

7. **Analytics dashboard** (new screen — data exists, no UI yet)
   - Word mastery breakdown (pie/donut chart)
   - Quiz accuracy trend over time (line chart)
   - Activity by hour of day (bar chart — when do you learn best?)
   - Weekly learning velocity (words per week trend)
   - Content diversity radar (balance across word/idiom/collocation/story/tip)

8. **Quiz experience** — interactive knowledge testing
   - Multiple choice with satisfying feedback animations
   - Correct/incorrect states with explanation
   - Streak within quiz session
   - Consider: timed mode? Difficulty progression?

9. **Grammar lessons** — structured grammar learning
   - Lesson card with pattern, explanation, examples
   - Interactive practice questions inline
   - Progress through the grammar curriculum
   - Consider: lesson completion state? Spaced review of grammar too?

10. **Settings** — user preferences
    - Clean settings layout
    - Level selection with descriptions
    - Content type toggles with previews
    - Self-paced mode explanation
    - Account management

11. **Leaderboard + Social** — competition and community
    - Full leaderboard with rank visualization
    - Profile comparison (versus mode)
    - Kudos interaction
    - Consider: weekly challenges? Friends list? Learning groups?

12. **Level suggestion modal** (data exists, no UI yet)
    - After sustained review performance, the system suggests level change
    - Show accuracy data, current vs suggested level
    - Celebrate improvement or offer encouragement

13. **Empty states and error states**
    - What does the app look like on day 1 with no data?
    - Connection errors
    - Loading states (skeleton screens)

14. **Dark mode** — full dark theme treatment

### Design Principles to Consider

- **Goal-Gradient Effect**: The closer you are to a goal, the harder you work. Show progress everywhere.
- **Zeigarnik Effect**: Incomplete tasks are remembered better than complete ones. Surface pending work.
- **Flow State**: Remove friction between "wanting to learn" and "learning". One tap from Home to review.
- **Variable Reward**: Make completion screens and achievements feel different each time.
- **Social Proof**: Leaderboard position and community activity validate the learner's effort.
- **Loss Aversion**: Streak protection, "don't lose your progress" nudges.
- **Hick's Law**: Don't overwhelm with choices. The Home screen should answer ONE question: "what should I do next?"

### Visual Direction (Suggestions, not constraints)

Feel free to go in any direction, but here are some starting thoughts:
- The seed blue (#2563EB) is the anchor, but the palette should feel warm and approachable, not corporate
- Consider illustration or iconography that connects to the "engram" / neural pathway concept
- Microinteractions matter — the swipe cards, the streak counter, achievement unlocks
- Typography should support both English (learning target) and Persian (native language) — this is an RTL-aware app
- Cards and containers should feel tactile, not flat
- Progress visualization is a design opportunity — circles, paths, trees, rivers, constellations — anything that makes "30% complete" feel more meaningful than a bar
- Consider how to make the app feel alive even when the user hasn't opened it in a while (welcome back state, catch-up mode)

### What NOT to Do

- Don't make it look like a Telegram web app (it's not — it's a native mobile experience)
- Don't use generic Material 3 defaults everywhere
- Don't make it feel like a todo app or a spreadsheet
- Don't over-gamify to the point of being childish — the audience is adult learners

### Deliverables

Design screens for every state of every screen listed above, including:
- Default/loaded states
- Empty states (no data yet)
- Loading states
- Error states
- Dark mode variants
- Transitions and micro-interactions (describe or annotate)
- Component library (buttons, cards, badges, chips, progress indicators)

### Technical Constraints

- Platform: Flutter (iOS + Android)
- Design system: Material 3 with `ColorScheme.fromSeed(seedColor: Color(0xFF2563EB))`
- Must support both light and dark themes
- Persian text support (RTL) for word meanings
- Bottom navigation: 4 tabs (Home, Learn, Library, Profile)
- Content is fetched from a REST API — design for async loading states

---

## Appendix: Complete API Endpoint Reference

```
Auth:
  POST /api/auth/register        — {email, password, name} → {token, user}
  POST /api/auth/login           — {email, password} → {token, user{id,email,name}}
  POST /api/auth/refresh         — {token} → {token}
  GET  /api/auth/me              — → {id, email, name, created_at, telegram_chat_id?}
  POST /api/auth/telegram/code   — → {code, expires_at}
  POST /api/auth/telegram/verify — {code} → {token, user{id,email,name,chat_id}}

Stats & Analytics:
  GET /api/stats                 — → full stats object (see Data section)
  GET /api/analytics             — → 5 chart datasets (see Analytics section)
  GET /api/config                — → {bot_username, web_app_url}

Vocabulary:
  GET  /api/vocab                — ?offset&limit&q&bookmarks → {items[], total}
  GET  /api/vocab/card           — ?term → {term, text, meaning}
  POST /api/bookmark             — {term, action} → {bookmarked}
  GET  /api/dictionary           — ?q&prefix → {results[], seeding, total}

Review (SRS):
  GET  /api/review/next          — ?limit → {items[ReviewCard]}
  GET  /api/review/count         — → {count}
  POST /api/review/answer        — {term, known} → {box, next_review}
  GET  /api/review/summary       — → LevelSuggestion object

Decks (Leitner):
  GET  /api/decks                — → {decks[DeckProgress]}
  GET  /api/decks/detail         — ?deck → DeckDetail
  GET  /api/decks/study          — ?deck&limit → {items[DeckStudyCard]}
  POST /api/decks/swipe          — {deck, term, known} → ok

Learning:
  GET  /api/practice             — ?kind → {term, text, available}
  GET  /api/grammar              — → {lessons[GrammarLesson]}
  GET  /api/grammar/lesson       — ?id → GrammarLesson (full)
  GET  /api/content              — ?kind&offset&limit → {items[ContentItem]}
  GET  /api/quiz/next            — → QuizQuestion
  POST /api/quiz/answer          — {word,correct,exp,token,answer} → {correct}
  GET  /api/quizzes              — ?offset&limit → {items[QuizHistoryItem]}

Social:
  GET  /api/leaderboard          — ?metric → LeaderboardResponse
  POST /api/leaderboard/name     — {name} → ok
  GET  /api/profile              — ?id → ProfileResponse
  POST /api/kudos                — {id} → {count, gaveByMe}

Settings:
  GET  /api/settings             — → {level, name, paused, interval, toggles, levels, levelLabels}
  POST /api/settings             — {key, value} → ok
```

---

## Appendix: Feature Wishlist (Future Improvements)

These don't exist yet but the data model could support them:

1. **Onboarding flow** — guided first-launch experience with level assessment
2. **Analytics dashboard** — 5 charts from existing `/api/analytics` endpoint
3. **Level suggestion modal** — after review sessions, suggest level change
4. **Learning streaks visualization** — make streaks more visual (fire animation, calendar view)
5. **Word relationships** — show synonyms, antonyms, word families
6. **Pronunciation playback** — TTS integration for word pronunciation (backend has `tts_enabled` pref)
7. **Spaced repetition insights** — show users WHEN their next reviews are due (today, tomorrow, this week)
8. **Content recommendations** — "Based on your level, try these idioms"
9. **Progress milestones** — celebrate 100 words, 500 words, etc. with special animations
10. **Daily goal system** — set a target (5 words/day) and track completion
11. **Grammar spaced review** — review grammar patterns using SRS too
12. **Social challenges** — weekly challenges between friends on the leaderboard
13. **Offline mode** — cache cards for review without internet
14. **Widget** — home screen widget showing streak and due cards
15. **Notifications** — smart reminders based on activity_by_hour data (learn when you usually learn)
