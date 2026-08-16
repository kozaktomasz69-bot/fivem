# Modern Loading Screen (FiveM)

A modern, fullscreen loading screen with a YouTube video background, custom
volume control, and a functional progress bar wired into FiveM's loadscreen
events.

## Files

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | Resource manifest; registers `index.html` as the loadscreen |
| `index.html` | Markup: YouTube player container, overlay, branding, progress bar, volume control |
| `style.css` | Modern aesthetic: dark overlays, backdrop blur, gradient bar |
| `script.js` | YouTube Iframe API init + FiveM `message` event handling |

## Features

1. **Fullscreen YouTube background** — embeds `https://www.youtube.com/watch?v=CMWI9TaWzcI`
   via the YouTube Iframe API (`iframe_api`). Autoplays + loops endlessly.
   All YouTube chrome (controls, title, branding) is hidden via player vars
   (`controls:0, modestbranding:1, rel:0, iv_load_policy:3, disablekb:1, fs:0`)
   plus CSS that scales the iframe to `object-fit: cover`-style and crops any
   residual UI off-screen, with `pointer-events: none`.

2. **Custom volume control** — a speaker icon + range slider in the bottom-right
   corner. Calls `player.setVolume()` / `unMute()` / `mute()` from the Iframe
   API. Default volume is **30%**. Begins muted to satisfy browser autoplay
   policies; the first interaction (a user gesture) unmutes at 30%.

3. **Functional progress bar** — listens to FiveM `window 'message'` events:
   - `loadProgress` (`{ eventName, loadFraction }`) sets the bar width (0–100%).
   - `onLogLine` (`{ eventName, message }`) updates the status label.
   - Phase events (`startInitFunctionOrder`, `startDataFileEntries`,
     `performMapLoadFunction`) provide friendlier labels.

## Install

1. Copy the `loadingscreen` folder into `resources/[ui]/` (or anywhere).
2. Add `ensure loadingscreen` to your `server.cfg`.
3. Restart the server / reconnect to see it.

## Notes

- The YouTube video requires internet access on the client during loading.
- If the video is unavailable, the background is hidden gracefully and the dark
  overlay still renders.
- `loadscreen_cursor 'yes'` is set so the mouse can interact with the volume
  slider. `loadscreen_manual_shutdown` is intentionally **not** set, so FiveM
  auto-closes the loadscreen when loading finishes.
