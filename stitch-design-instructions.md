# Google Stitch — Design Brief: Minimal Prayer Times App

## App name
"Waqt" (placeholder — replace if needed)

## One-line purpose
A private, single-family prayer time reminder app. NOT a full Islamic super-app.

## Design direction
- Style: minimal, modern, calm — closer to a weather/clock app than a "Muslim app"
- Aesthetic references: Google Clock, Things 3, Apple Weather
- Material 3 (M3) expressive but restrained — no clutter, no gradients-for-decoration
- Typography: one clean sans-serif (Inter, Manrope, or Google Sans), large numerals for time
- Color: neutral base (off-white / near-black dark mode), single accent color tied to "next prayer" state
- Dark mode and light mode both required, auto-switch by system

## Explicitly avoid
- No Quran/Hadith quote widgets
- No "Islamic community," donation, or social feed sections
- No Qibla compass, no Ramadan calendar, no multi-madhhab settings screens
- No dense settings menus — settings screen must fit one scroll, no sub-sub-menus
- No icons/illustrations of mosques, crescents as decoration-heavy elements

## Screens to generate

### 1. Home Screen
- Top: current date (Gregorian + Hijri, small, secondary text)
- Center: large countdown to next prayer ("Asr in 1h 24m")
- Below: today's 5 prayer times as a simple vertical list (Fajr, Dhuhr, Asr, Maghrib, Isha), current/next one highlighted with accent color
- No app bar clutter — just a settings gear icon top-right

### 2. Notification (system tray mock)
- Prayer name + time, minimal icon, one-line body ("Maghrib in 10 minutes")

### 3. Settings Screen
- Location (auto/manual)
- Calculation method (dropdown: MWL, ISNA, Umm al-Qura, etc.)
- Notification lead time (5/10/15 min before)
- Adhan sound on/off + sound picker
- Theme (system/light/dark)
- That's it — nothing else

## Interaction notes for Stitch
- Prioritize whitespace and a single focal element per screen
- Prefer soft rounded cards for the prayer list rows
- Motion: subtle countdown tick, no heavy transitions
- Generate both light and dark variants of Home Screen
