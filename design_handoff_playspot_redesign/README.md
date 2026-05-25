# Handoff: PlaySpot Redesign (SwiftUI)

## Overview

**PlaySpot** is a location-based AR mission/exploration game. Players walk to real-world locations, find virtual items via AR, solve quizzes, design their own missions, and earn badges. This handoff covers the **full redesign** of the app in a Duolingo-inspired "candy" style, modernized from the iOS-native screens currently in production.

The redesign covers ~25 screens across 5 sections:
- **Missions** — Browse and play missions
- **Design** — Build and configure your own missions
- **My Info** — Profile, owned items, designed/played missions
- **Badge** — Badge collection
- **Settings** — Account, debug, about
- Plus all in-game / AR / tutorial flows

## About the Design Files

The files bundled here are **design references created in HTML/React JSX** — prototypes showing intended visuals, layout, and interactions. They are **not production code to copy directly**.

Your task: **recreate these designs in SwiftUI** using:
- SwiftUI views and view modifiers
- Your project's existing patterns (navigation stack, view models, etc.)
- The design tokens documented below

The HTML prototypes are interactive — open `PlaySpot Redesign.html` in a browser to navigate between screens via the in-app buttons, jump to any screen via the **Tweaks** panel (bottom right), or use the **Flow Map** artboard for an overview.

## Fidelity

**High-fidelity (hifi).** All colors, typography, spacing, border radii, and shadows are final. Reproduce them precisely. Layout proportions match a 320×568 base iPhone screen and should scale up cleanly to modern devices.

## Design System Foundation

The visual language is **Duolingo-inspired**:
- Chunky 2px borders on every interactive surface
- Iconic "candy button" — solid fill + flat 4px-down offset shadow (no blur)
- Heavy display font for headings and button labels (`Jalnan2` for Korean / Nunito Black fallback)
- Bright primary colors with soft tinted backgrounds for sections
- Rounded corners (10–14px standard, 16–18px for prominent cards)

## Design Tokens

### Colors (hex)

**Brand greens (primary)**
- `green-500` `#58CC02` — main brand (default theme accent)
- `green-700` `#5AA703` — button bottom shadow
- `green-800` `#43A601` — deep border
- `green-100` `#D7FFB8` — soft tint background
- `green-900` `#375B0A` — deepest text

**Accent colors**
- `macaw` `#1CB0F6` — info / links / selected (Blue theme accent)
- `macaw-deep` `#0084C2`
- `macaw-bg` `#D2EFFD`
- `cardinal` `#FF4B4B` — danger / mine / quiz
- `cardinal-deep` `#EA2B2B`
- `bee` `#FFC800` — XP / stars
- `fox` `#FF9600` — streak / "warning" (Orange theme accent)
- `fox-deep` `#E08600`
- `fox-bg` `#FFE7CE`
- `beetle` `#CE82FF` — purple (rewards, gems) (Purple theme accent)
- `beetle-deep` `#8C39C8`

**Neutrals**
- `white` `#FFFFFF`
- `snow` `#F7F7F7` — page background
- `swan` `#E5E5E5` — borders / dividers
- `swan-2` `#EBEBEB` — button container border
- `hare` `#AFAFAF` — placeholder / hint
- `wolf` `#777777`
- `wolf-2` `#4B4B4B` — body copy
- `eel` `#3C3C3C` — primary headings
- `eel-2` `#2D3339` — heaviest text

**In-game HUD (teal — fixed, not part of theme)**
- HUD background: `linear-gradient(180deg, #2A8794 0%, #1A5E69 100%)`
- HUD darker variant: `linear-gradient(180deg, #1A5E69 0%, #0E3A42 100%)`

### Typography

- **Display font (Korean)**: `Jalnan 2` (잘난체) — used for headings, button labels, numeric digits, kicker labels
- **Display font (Latin)**: Nunito Black (weight 900) — fallback when no Korean
- **Body**: Nunito (weights 400/500/600/700/800)
- **Mono**: system monospace

**Scale**
- xs `11px` — tiny labels
- sm `13px` — captions, kicker
- base `14px` — secondary UI
- md `15px` — button labels
- lg `16px` — body
- xl `18px` — large list items
- 2xl `19px` — section headers
- 3xl `22px` — screen headers
- 4xl `28px` — display headings (large)
- 5xl `36px` — splash titles

**Treatment**
- Button labels are **UPPERCASE** with letter-spacing `0.06em`
- Kicker labels (`SECTION 1, UNIT 1`-style) are UPPERCASE 11–13px in `hare` color
- Display headings use `letter-spacing: -0.01em` (slightly tight)

### Spacing scale

`4, 8, 12, 16, 20, 24, 32, 40, 48` (px)

### Border radius

- `xs` 6px — tiny chips
- `sm` 8px — keyboard keys
- `md` 10px — small buttons / nav tiles
- `lg` 12px — standard buttons, cards
- `xl` 14px — large cards
- `2xl` 16px — stat cards, modals
- `pill` 9999px — chips, progress bars

### Shadows (signature offset, no blur)

- Primary button: `0 4px 0 0 var(--green-700)` (4px down, brand color)
- Secondary/card: `0 2px 0 0 var(--swan-2)` (2px down, gray)
- Active section: `0 4px 0 0 var(--green-750)`
- Modal/elevated: `0 8px 24px rgba(0,0,0,0.10)` (real blur for floating elements only)

In SwiftUI:
```swift
.background(Color.primary)
.offset(y: pressed ? 4 : 0)
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.shadowColor)
        .offset(y: pressed ? 0 : 4)
)
```

## Screens / Views

### 1. Mission List (`list`)
Default landing screen. Browse missions by category.

- **Header** (sticky): Fox mascot 36×36 + "PLAYING NOW" kicker + "Missions" title. Right side: Streak chip (🔥 7) and Gem chip (💎 248), both in white pill containers with 2px swan-2 border.
- **Segmented tabs**: POPULAR / NEW / NEAR ME. 44px height, 12px radius. Active tab uses theme primary color (bg + border + text), inactive uses white bg + hare gray text.
- **Mission cards** (vertical list, 12px gap):
  - 64×64 left avatar tile (colored bg per tint with 2px border + 2px shadow), centered icon
  - Level circle badge top-right of avatar (-8, -8 offset, 26px circle, deep tint, 2px white border)
  - Title (15px display 900)
  - Description (11px body)
  - Star rating + location (uppercase 9px in macaw)
  - Right column: PLAYS chip (green-100/green-800) + FAILS chip (cardinal-bg/cardinal-deep), 22px height
- **Bottom nav** (5 tabs): Missions / Design / My Info / Badge / Settings — see component spec

### 2. Map Play — In-mission map view (`map-play`)
Player navigates the real map while playing.

- **Top game HUD** (green theme gradient bar): EXIT button (red flat) + 8-digit `00:00:05` timer (flat white cards with 1.5px swan border, NOT 3D) + Locate button (white) + Info button (theme primary, white "i" icon). All buttons 36×36, no offset shadows.
- **Map area**: Procedural park-style background (cream/green gradient with roads, buildings, place name labels). Mission radius highlight (dashed circle, theme color tint). Pin items placed across the map. Player position dot at center (24px macaw circle, white border) with pulsing ring.
- **Bottom HUD** (absolute overlay, no white background): teal gradient pill bar spanning full width:
  - Segmented columns: 남은지형 / 남은필수 (yellow value) / [Camera] / Hidden / Stealth
  - Alternating segment tints (darker middle, lighter edges)
  - Camera button (62×62 circle) floating above center, radial teal gradient, 1.5px white border, 4px down shadow
  - Camera glyph: white body + viewfinder bump + teal lens with dark center + yellow flash dot

### 3. AR Searching (`ar-search`)
Camera view while searching for an item.

- **Top bar**: Theme primary gradient (green by default), 36×36 dark teal MAP button (rounded), large white timer digit cards (00:09:00 format), same height as top of Map Play
- **Camera background**: Procedural outdoor scene (sky band + tree silhouettes + ground)
- **Floating item pin**: Start pin (3D PNG), 56px size, glow halo, positioned at ~50%/40%
- **Bottom AR HUD bar**: Dark teal pill (left/right/bottom: 0, no white margin):
  - Left: blue Start flag icon + 2-line stack (label "Start" 12px + value "2m" 14px yellow)
  - Center: green radar disc (64×64) with sweep, crosshair, directional needle, glowing center hub, white blip — floats above bar (-8 offset)
  - Right: green map pin icon (with radius disc base) + 2-line stack (label "유효 반경" 12px + value "100m" 14px blue) — same alignment as left

### 4. AR Mini-game (`ar-touch` / `ar-party`)
When player is close enough, shake/touch mini-game to acquire item.

- **Top bar**: Same theme primary bar with progress counter (e.g., `00:00:36`) in time slot
- **Background**: Outlined PLAY SPOT wordmark (use `assets/minigame/playspot_logo.png`). As `progress / target` increases (0→1), the logo's `brightness` rises from 0.55→1.05 and `saturate` from 0.4→1.8, with drop-shadow glow appearing past 50%.
- **Foreground**: Hand+phone illustration (alternates between `shake_0/shake_1.png` or `touch_0/touch_1.png` based on `pose` state). Toggles every 0.7s automatically; user taps to bump progress 4-8 and trigger a sparkle burst.
- **Sparkle burst on tap**: 14 colored particles (yellow/orange/teal/white) fly outward 80-140px from center over 0.7s, rotating + scaling down to 0.4 + fading. CSS keyframes `ps-sparkle-fly` and `ps-sparkle-twinkle` for idle ambient.
- **Glow halo**: Behind phone when active, 300px radial gradient `rgba(255,200,0,0.35)`, animates `scale(0.5)→scale(1.3)` over 0.35s with opacity 0→1→0.
- **Phone idle animation**: `shake` variant rotates -6° to 6° with translate jitter (0.45s); `touch` variant gentle bob (translate -2px, scale 1.04, 1.4s).
- **Bottom strip**: "흔드세요!" / "터치하세요!" instruction + N/100 progress (current value in yellow).

### 5. Hint Acquired Popup (`hint`)
Modal over AR background.

- **Backdrop**: Blurred AR scene + 35% black overlay
- **Modal card**: White, 18px radius, 2px swan-2 border, 4px swan-2 offset shadow + 20px 40% black drop shadow for depth. Hint pin (58px) overlaps top-left corner.
- **Content**: Kicker "ITEM ACQUIRED · 아이템 획득" (10px macaw uppercase), display "Hint!" (30px), 2-line Korean description body, reward chips strip (+15 XP, +1 Gem in white pill containers), primary green "확인 · OK" button full width.
- **Bottom strip**: Dark eel-2 bar with small radar (40px) + red "미션 종료!" button.

### 6. Map Edit — Item Placement (`map-edit`)
Build/edit your mission map.

- **Top bar**: Flat. Cancel (ghost) + "EDITING / 미션 설계 · Design" centered + Save (primary green). 
- **Map area** (large): Park-style map with paths, mission radius (dashed teal), mine "blast" red translucent circles, scattered item pins (32px), target reticle + checkered start flag
- **Helper toast** (bottom of map): Dark eel-2 with fox mascot (think pose) + "꾹 눌러서 아이템 이동 · 탭으로 설정" hint
- **Bottom item palette**: Horizontal scroll of 28px item pins inside 44px white tiles with 2px swan-2 border

### 7. Map Edit + Picker (`map-edit-picker`)
Variant with bottom-sheet 3-column drum picker.

- **Top half**: Smaller map preview + active item with effective radius preview (dashed teal circle)
- **Picker toolbar**: Dark `#3D3D3D` strip — labels ITEM · DISPLAY · VISIBLE RANGE on left, CANCEL/DONE buttons on right
- **3-column drum**: iOS-style picker with central highlighted band, items fade by distance from center. Columns: item kind / display mode (Normal/Hidden/Stealth/...) / range (10–100m)

### 8. Item Detail v2 — Clean form (`item-detail-v2`)
Configure a single item (Mine variant shown).

- **Top nav**: 취소 / 아이템 상세 / 완료 (all-text iOS-like links, blue macaw color)
- **아이템 정보 card**: 56px item pin + name (18px display 900) + 2-line description (12px body)
- **Tip card** (yellow): 💡 emoji + tip text in bee-bg with darker yellow border + 2px offset shadow
- **MINE (지뢰) section**: 
  - 필수 여부 row: label + "자동 — 꺼짐" right-aligned + sublabel
  - 발견 거리 row: "발견 거리: 45 m" + ±stepper (rounded snow background, separator line)
  - 폭발 반경 row: in orange `fox` color
- **삭제 button**: White card with trash icon + "아이템 삭제" in cardinal red

### 9. Design List v2 (`design-list-v2`)
Browse the user's designed missions.

- **Top**: + button (green primary 36×36 with offset shadow) right-aligned
- **Large title**: "내 디자인" (28px display)
- **비공개 section**: Grouped card with 2 rows, each: title + 비공개 chip (fox-bg/a55e00) + description, right-side ▶ "테스트" green play button + chevron
- **공개 section**: 1 row with 공개 chip (green-100/green-800)
- **Helper text**: Below 공개 section explaining you must unpublish before deleting

### 10. Mission Edit v2 (`mission-edit-v2`)
Edit mission metadata.

- **Top nav**: `< 내 디자인 취소` (left chevron + blue text) + 저장 (right, blue bold)
- **Title**: "미션 편집" (28px display)
- **기본 정보 group**: Title input + place input + "좌표로 장소 자동 채우기" action row (with search-arrow icon, blue text)
- **설명 group**: Multi-line textarea (100px min height)
- **플레이 제한 시간 group**: "시간 제한" toggle + footer note
- **플레이 설정 group**: "Virtual 모드 허용" toggle (green when on) + "언어" row with up/down chevron picker

### 11. Badge List v2 (`badges-v2`)
Browse earned and locked badges.

- **Header**: "Badge List" centered title (no large display)
- **Mission Badge group**: Teal `#1C8A9F` header with white title, 3-column grid of 60×60 circular badges:
  - Unlocked: solid color bg (e.g., yellow with bolt icon), 2.5px dark border, 3px down shadow
  - Locked: grayscale "?" with 0.65 opacity, no shadow
- **Play Badge group**: Same structure. "play 1" unlocked example: green-300 bg with white "play 1" text, dark border, deep green text shadow

### 12. My Info (`my-info`)
Profile + activity summary.

- **Title**: "My Info" (28px display)
- **Profile card**: 50×50 macaw avatar circle (User icon, 2px deep-blue shadow) + email + "Member" sublabel
- **ITEMS group**: Solutions / Time Add rows with right-aligned count
- **DESIGNED (3) group**: 3 mission rows, link-styled (blue display 900)
- **PLAYED (2) group**: 2 mission rows

### 13. Settings (`settings`)
- **Title**: "Settings" (28px display)
- **ACCOUNT group**: User ID row + Login link
- **API BACKEND group**: Segmented Legacy/REST control + footer note about re-login
- **DEBUG group**: 401 simulation action row + console hint footer
- **TUTORIAL group**: How to Play link → opens help-howto
- **ABOUT group**: Version / Build rows with right-aligned values

### 14. Help · Items (`help-items`)
Visual glossary of all 19+ game items.

- **Top bar**: Back button + "HELP · 도움말" kicker + "Item Glossary" title
- **Tab strip**: ITEMS / HOW TO PLAY / DESIGN segmented tabs
- **Property legend card**: 4 rows explaining Normal / Hidden / Stealth / 필수 ★ with mini badge swatches
- **5 grouped sections**: 
  - Mission · 핵심 (green) — start, end, hint, mine, defence, gambling
  - Quiz · 퀴즈 (red) — quiz, solution, oxO, oxX
  - Radar · 레이더 (purple) — mapRadar, mineRadar, stealthRadar, allRadar
  - Time · 시간 (blue) — runStart, runEnd
  - Special · 특수 (orange) — dark, store, coupon, hospital
- Each item row: 42px pin + English name (display 900) + Korean name + 필수 chip (if essential) + 11.5px description

### 15. Help · How to Play (`help-howto`)
Marketing-style explainer.

- **Hero card**: Orange gradient bg with "WHAT IS · 플레이스팟이란?" kicker + "PlaySpot?" display heading + description + fox mascot top-right
- **Mode comparison**: 2-card grid (Real LIVE green / Virtual HOME purple)
- **4 PlayStep cards**: Numbered orange circle + title + body + custom mini visual (mini map / walking fox / AR shake / trophy clear)
- **Rewards strip**: Dark eel-2 bg with 4 PerkChips (XP/Gems/Streak/Badge in their respective brand colors)
- **Bottom**: Fox mascot + green speech bubble "준비됐어요?"

### 16. Help · Mission Design (`help-design`)
5-step guide to building a mission.

- **Hero card**: Purple gradient bg + thinking-fox mascot + intro
- **5 DesignSteps**: Each = colored numbered circle + title + body + 80×80 mini-visual on right
  1. Drag items onto map (green)
  2. Tap to configure (blue) 
  3. Mission info (orange)
  4. Test yourself (purple)
  5. Upload — once only! (red, warning tone)
- **CTA**: Full-width purple "미션 만들기 시작!" button with pencil icon

### 17. Onboarding/Tutorial (`tutorial`)
3-step onboarding with fox bubble.

- **Top**: SKIP button + 3-dot progress (active = 22px wide bar in macaw) + X close
- **Step header**: Orange kicker + display title
- **Faux demo device**: Light green map background with target pin (pulsing ring + glow + active star) + pointing hand emoji + tap ripple + yellow tip bubble
- **Bottom**: Fox mascot + speech bubble (white, swan-2 border) with pose-specific copy
- **Nav buttons**: BACK / NEXT or "LET'S PLAY!" depending on step

## Components

### Candy Button (`ps-btn`)
Solid color body + flat 4px offset shadow in deep color. Press = translate(y: 4px) and remove shadow.

```swift
// SwiftUI sketch
struct CandyButton: View {
    let title: String
    var tint: Color = .duoGreen500
    var shadow: Color = .duoGreen700
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.duoDisplay(size: 15))
                .kerning(1.0)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(tint))
                .offset(y: pressed ? 4 : 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(shadow)
                .offset(y: pressed ? 0 : 4)
        )
        .buttonStyle(.plain)
    }
}
```

Variants:
- `primary` — green-500 / green-700 shadow
- `blue` — macaw / #1899D6 shadow
- `red` — cardinal / #D33 shadow
- `orange` — fox / fox-deep shadow
- `purple` — beetle / beetle-deep shadow
- `ghost` — white bg, wolf text, swan-2 border, swan-2 shadow

Sizes:
- default: 48px height, 18px horizontal pad, 14px font
- `sm`: 36px, 14px pad, 12px font
- `xs`: 28px, 10px pad, 11px font
- `icon`: square 44/36/28, no padding

### Card (`ps-card` / `DuoCard`)
White bg, 2px swan-2 border, 12-14px radius, 2px swan-2 offset shadow.

### Chip (`ps-chip`)
26px height, pill radius, uppercase display font 11px, padding 0 10px. Color variants by background+text pair.

### Item Pin (3D PNG)
- Source: `assets/items/i_<name>.png`, supplied as 162×162 (3x).
- Render at 28-56px depending on context.
- Use `Image(...).resizable().aspectRatio(contentMode: .fit)` in SwiftUI.
- Star overlay (for essential items): yellow circle 46% size, top-right -5% offset, white star path inside.
- 19 distinct items defined in `GAME_ITEMS` (see `src/pins.jsx`).

### Bottom Nav (5-tab)
Fixed bottom, 2px swan border-top, 8px/6px/10px padding. Each tile is flex 1, vertical layout: icon + 10px UPPERCASE label. Active tile: theme-primary-bg background, theme-primary border (2px), theme-primary-deep text.

### Section Group (form card)
- Title kicker (10px hare uppercase) above
- White card with 2px swan-2 border, 14px radius, 2px swan-2 shadow
- Internal rows separated by 1px swan dividers
- Optional footer hint text below

### Toggle (`PSToggle`)
56×32 pill. ON: green-500 bg + green-700 shadow. OFF: gray. White knob 26×26 with subtle drop shadow. Label inside knob ("ON"/"OFF") in 9px display 900.

### Stepper
30px height rounded pill (1.5px swan border, snow bg). 36px wide buttons with `−` / `+` glyphs, single 1px divider between them.

### Radar (AR HUD)
- 64×64 circular gradient (radial: light green → dark green)
- 3px white border + inner 2px dark stroke
- 2 concentric inner rings (white 35% opacity)
- White crosshair (40% opacity, 1px)
- Conic-gradient sweep (rotates 6s linear, light green 0-70deg fade to transparent)
- Directional needle: 2px wide yellow shaft + arrow head, rotate `angle` deg
- Center hub: 8px yellow circle, dark border, glow
- Blip dot: 5px white at ~18%/68% with 5px white glow

### Fox Mascot
SVG-based placeholder character. 4 poses: `wave` / `sit` / `think` / `cheer`. Used at 28-80px sizes throughout.

If you have a real mascot illustration, swap the SVG for `Image("MascotWave")` etc.

## Interactions & Behavior

### Navigation flow (suggested)
- Mission List → tap mission → Mission Info → PLAY → Map Play
- Map Play → camera button → AR Search → close to target → AR Mini-game → tap/shake completes → Hint Popup → OK → next AR target
- Design tab → My Designs → tap row → Action Sheet (Modify/Test/Upload)
- Design tab → + button → Map Edit → Save → Mission Settings → Save → My Designs
- Map Edit → tap item pin → Item Detail screen for that item type
- Settings → How to Play → Help Items / How to Play / Design 3-tab flow

### Animation specs
- Button press: 80ms transform + box-shadow
- Tab/nav highlight: 120ms ease
- Modal entry: opacity 0→1 + scale 0.95→1, 220ms `cubic-bezier(.34,1.56,.64,1)` (pop)
- Bob (mascot bounce): 2.2s pop ease, translate y ±6px
- Spin (radar sweep): 6s linear infinite
- Pulse ring (player position): 1.8s ease-out infinite, scale 0.6→2.4 + opacity 0.55→0
- Sparkle fly (mini-game): 0.7s ease-out, fly + rotate + fade
- Shake (mini-game phone): 0.45s ease-in-out infinite, ±8° rotate

### State per screen

**ScreenARFound**
- `progress`: Int (0–100), increments 4–8 per tap
- `burst`: Int (key counter to retrigger sparkle anim)
- `glow`: Bool (transient 350ms)
- `autoFrame`: 0/1 (toggles every 700ms for idle sparkle frame)
- On `progress >= target`, schedule onTap callback after 400ms

**ScreenMapPlay**, **ScreenARSearch**: stateless (timer/counter are visual only in prototype)

**ScreenMissionSettings**, **ScreenMissionEditV2**: 
- `virtual`: Bool toggle
- `timeLimit`: Bool toggle
- Form inputs (title/description/place/quiz/answer) — basic text fields

**ScreenItemDetailV2**:
- `mandatory`: Bool
- `range`: Int (10–100, step 5)

## Assets

### `assets/items/` — 19 item pin PNGs (3x, 162×162 PNG with alpha)
- `i_start.png`, `i_end.png`, `i_simple.png` (hint), `i_mine.png`, `i_mine_nobomb.png` (defence), `i_random_box.png` (gambling), `i_quiz.png`, `i_genius.png` (solution), `i_radar_map.png`, `i_radar_mine.png`, `i_radar_ar.png` (stealth), `i_radar_all.png`, `i_time_start.png`, `i_time_end.png`, `i_black.png` (dark), `i_store.png`, `i_coupon.png`

### `assets/minigame/`
- `playspot_logo.png` — black wordmark used in mini-game background
- `playspot_logo_color.png` — colored variant for popups
- `shake_0.png`, `shake_1.png` — hand-phone illustrations (shake variant, idle + sparkle frame)
- `touch_0.png`, `touch_1.png` — hand-phone illustrations (touch variant)

### Fonts
- `Jalnan2.ttf` — Korean display font (place in `Fonts/`, register in `Info.plist` under `UIAppFonts`)
- Nunito — use Google Fonts CDN or bundle weights 400/500/600/700/800/900

## Tweaks & Theming

The prototype includes a **Tweaks panel** (bottom-right toggle) that lets you preview:
- **Accent color**: Green / Blue / Orange / Purple — swaps theme-primary throughout
- **Dark mode**: Light/dark backgrounds (currently affects ps-screen, bottom nav, tabs)
- **Font**: Jalnan vs Nunito Black for headings
- **Mascot on/off**: Show/hide fox mascot
- **Animation speed**: 0×–2× multiplier
- **Jump to screen**: Navigate the prototype to any screen instantly

These are tweaks for prototype review — you can choose which (if any) to expose in the production app.

## Files in this Handoff

- `PlaySpot Redesign.html` — Entry point. Open in browser.
- `src/` — React JSX implementation
  - `app.jsx` — Main app + Design Canvas + Flow Map + Tweaks Panel
  - `phone.jsx` — iPhone device frame
  - `icons.jsx` — Custom icon set (PSIcons)
  - `pins.jsx` — Item pin component using PNG assets
  - `screens-game.jsx` — Map Play, AR Search, AR Mini-game, Hint Popup
  - `screens-meta.jsx` — Mission List, Map Edit, Badges, Tutorial
  - `screens-design.jsx` — Design List, Action Sheet, Mission Info, Mission Settings, Item Detail, Map Edit Picker
  - `screens-tutorial.jsx` — Item Glossary, How to Play, Design Guide
  - `screens-v2.jsx` — Settings, My Info, Badge List v2, Item Detail v2, Design List v2, Mission Edit v2, Item Acquired Popup
- `styles/`
  - `tokens.css` — All color, typography, spacing, radius, shadow tokens
  - `app.css` — Component classes + theme tokens
  - `fonts/Jalnan2.ttf` — Display font
- `assets/items/` — 17 item pin PNGs (3x resolution)
- `assets/minigame/` — Mini-game assets + PlaySpot logo

## Notes for SwiftUI Implementation

1. **Don't blindly port React state** — use SwiftUI's `@State`, `@Binding`, `@ObservedObject` properly. For navigation between screens, use `NavigationStack`/`NavigationPath` instead of the prototype's manual `setScreen()` switch.

2. **Color extension first** — define `Color.duo*` extensions for every token before building views. Reference these everywhere.

3. **Custom fonts** — register Jalnan2 in Info.plist, then create a `Font.duoDisplay(size:)` helper:
   ```swift
   extension Font {
       static func duoDisplay(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
           .custom("Jalnan2", size: size).weight(weight)
       }
   }
   ```

4. **Candy button shadow trick** — SwiftUI doesn't have a direct "offset solid shadow" modifier. Use a `ZStack` with the button face shifted up by 4px relative to a same-shaped shadow rect, then animate `offset` on press.

5. **Item pins** — bundle the 17 PNGs in `Assets.xcassets` at 3x. Render with `Image(...).resizable().aspectRatio(contentMode: .fit).frame(width: size, height: size * 1.2)`.

6. **Map** — for real production, integrate `MapKit` for the map screens. The HTML's procedural roads/buildings are placeholder. You'll want real coordinates + custom annotation views for item pins.

7. **AR** — use `ARKit` / `RealityKit` for actual AR; the HTML's "AR view" is just a gradient + 2D pin overlay for demonstrating UI layout.

8. **Animations** — `withAnimation(.spring(response: 0.22, dampingFraction: 0.6))` approximates the prototype's pop easing. For continuous spin/bob/pulse, use `.repeatForever(autoreverses: ...)` on a `withAnimation` block triggered in `.onAppear`.

9. **Mini-game sparkle** — implement particles as a `Canvas` view or array of `@State` particle structs animated independently. Or use SpriteKit overlay for performance.

10. **Don't ship the Tweaks panel** — it's prototype-only.

## Open Questions for Product

- Are Korean and English shown together always (e.g., "확인 · OK"), or one based on locale?
- Real backend exists per Settings screen ("Legacy" vs "REST" segmented). Pick one for the production app.
- Animation budget — some prototypes have heavy CSS keyframes; want to dial back for battery/perf in production?
- Fox mascot — keep the placeholder SVG or commission a final illustration?
