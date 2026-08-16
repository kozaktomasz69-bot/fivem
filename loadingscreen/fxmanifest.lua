-- ============================================================================
-- Modern Loading Screen Resource - Manifest
-- Plays a fullscreen YouTube video as the background, with a custom volume
-- control and a functional progress bar wired into FiveM loadscreen events.
-- ============================================================================

fx_version 'cerulean'
game 'gta5'

author 'OpenHands'
description 'Modern loading screen with fullscreen YouTube background, volume control and functional progress bar'
version '1.0.0'

-- `loadscreen` tells FiveM to render index.html as the loading screen UI
-- instead of a normal game resource. Files are served via the NUI browser.
loadscreen 'index.html'

-- loadscreen_cursor turns the mouse cursor on while loading (so the volume
-- slider is usable). 0 = off, 1 = on, 'yes' = on.
loadscreen_cursor 'yes'

-- Note on lifetime: we intentionally do NOT set `loadscreen_manual_shutdown`.
-- By default FiveM calls SHUTDOWN_LOADING_SCREEN automatically when loading
-- completes, which tears down this NUI page for us. The JS only drives the
-- progress bar / label from FiveM events and applies a cosmetic fade-out.

-- Shared/ui files. Because this is a loadscreen, scripts are not loaded as
-- normal client/server scripts; HTML/CSS/JS are referenced by index.html.
files {
    'index.html',
    'style.css',
    'script.js'
}
