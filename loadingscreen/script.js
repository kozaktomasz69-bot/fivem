/* ============================================================================
 * Modern Loading Screen - script.js
 *
 * Two integrations live here:
 *
 *   1. YouTube Iframe API  -> fullscreen, autoplay, looping background video
 *      with a hidden chrome, plus a volume control that calls setVolume().
 *
 *   2. FiveM loadscreen events -> window 'message' events posted by the game
 *      into the NUI frame. We react to `loadProgress` (to drive the bar width)
 *      and `onLogLine` (to update the status label), per the official schema:
 *        { eventName: 'loadProgress', loadFraction: 0..1 }
 *        { eventName: 'onLogLine',   message: '...' }
 * ========================================================================== */

(function () {
    'use strict';

    /* ---------- Configuration ---------------------------------------------- */

    // The exact video requested: https://www.youtube.com/watch?v=CMWI9TaWzcI
    const VIDEO_ID = 'CMWI9TaWzcI';

    // Default starting volume (requirement: 30%).
    const DEFAULT_VOLUME = 30;

    /* ---------- DOM references --------------------------------------------- */

    const progressBar    = document.getElementById('progress-bar');
    const progressLabel  = document.getElementById('progress-label');
    const progressPct    = document.getElementById('progress-percent');
    const tipEl           = document.getElementById('tip');
    const volumeSlider   = document.getElementById('volume-slider');
    const volumeIcon     = document.getElementById('volume-icon');
    const volumePath     = document.getElementById('volume-path');
    const root           = document.body;

    /* ---------- YouTube player state --------------------------------------- */

    let ytPlayer = null;
    let isMuted  = false;   // mirrors the player mute state for the icon
    let lastVolume = DEFAULT_VOLUME;

    /**
     * Called automatically by the YouTube Iframe API once it has finished
     * loading (the API script tag is in index.html). We construct the player
     * on the #yt-player div here.
     */
    window.onYouTubeIframeAPIReady = function () {
        if (typeof YT === 'undefined' || !YT.Player) {
            // API failed to load (e.g. no connectivity during load). Bail out
            // gracefully - the dark background still looks fine.
            return;
        }

        ytPlayer = new YT.Player('yt-player', {
            videoId: VIDEO_ID,
            playerVars: {
                autoplay: 1,        // start playing immediately
                controls: 0,        // hide all player controls
                disablekb: 1,       // disable keyboard shortcuts
                fs: 0,              // hide fullscreen button
                modestbranding: 1,  // minimize YouTube branding
                rel: 0,             // no related videos at the end
                iv_load_policy: 3,  // hide video annotations
                playsinline: 1,     // don't force fullscreen on mobile
                loop: 1,            // loop endlessly...
                playlist: VIDEO_ID, // ...loop requires playlist for a single video
                start: 0
            },
            events: {
                onReady: onPlayerReady,
                onStateChange: onPlayerStateChange,
                onError: onPlayerError
            }
        });
    };

    /**
     * onReady fires once the player has loaded the video element.
     * We set the default volume and ensure playback. To satisfy browser
     * autoplay policies (which block autoplay WITH sound without a user
     * gesture), we begin muted; the first interaction with the volume
     * control counts as a gesture and unmutes at 30%.
     */
    function onPlayerReady() {
        try {
            ytPlayer.setVolume(DEFAULT_VOLUME); // apply default volume value
            ytPlayer.mute();                    // start muted so autoplay is allowed
            isMuted = true;
            updateVolumeIcon();
            ytPlayer.playVideo();
        } catch (e) {
            /* setVolume may throw if the player isn't fully ready; ignore. */
        }
    }

    /**
     * If the video ever ends (loop should prevent this, but as a fallback),
     * restart it from the beginning.
     */
    function onPlayerStateChange(event) {
        if (event.data === YT.PlayerState.ENDED) {
            try { ytPlayer.seekTo(0); ytPlayer.playVideo(); } catch (e) {}
        }
    }

    function onPlayerError() {
        // Hide the background gracefully if the video is unavailable.
        const bg = document.getElementById('yt-background');
        if (bg) bg.style.display = 'none';
    }

    /* ---------- Volume control --------------------------------------------- */

    /**
     * Applies the slider's value to the YouTube player via setVolume() and
     * handles the mute/unmute toggle. This is the bridge between the custom
     * UI element and the Iframe API.
     */
    function applyVolume(value) {
        lastVolume = value;
        if (!ytPlayer) return;

        try {
            if (value <= 0) {
                ytPlayer.mute();
                ytPlayer.setVolume(0);
                isMuted = true;
            } else {
                // Unmuting here is triggered by a user gesture (slider input
                // or icon click), which satisfies autoplay audio policies.
                ytPlayer.unMute();
                ytPlayer.setVolume(value);
                isMuted = false;
            }
        } catch (e) {}

        updateVolumeIcon();
    }

    /** Swaps the speaker SVG path between muted / unmuted icons. */
    function updateVolumeIcon() {
        const v = parseInt(volumeSlider.value, 10);
        // Two simple paths: muted (speaker + X) and on (speaker + waves).
        const muted =
            'M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.17v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z';
        const on =
            'M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z';

        if (isMuted || v === 0) {
            volumePath.setAttribute('d', muted);
        } else {
            volumePath.setAttribute('d', on);
        }
    }

    // Slider input -> apply volume live.
    volumeSlider.addEventListener('input', function () {
        applyVolume(parseInt(volumeSlider.value, 10));
    });

    // Icon click toggles mute (restores the last non-zero volume).
    volumeIcon.addEventListener('click', function () {
        if (isMuted) {
            const restore = lastVolume > 0 ? lastVolume : DEFAULT_VOLUME;
            volumeSlider.value = restore;
            applyVolume(restore);
        } else {
            volumeSlider.value = 0;
            applyVolume(0);
        }
    });

    // Keyboard accessibility on the slider (arrow keys also trigger 'input').
    volumeSlider.addEventListener('keydown', function (e) {
        // Let the range input handle arrows natively; just stop propagation so
        // the game doesn't receive the keys while focused here.
        e.stopPropagation();
    });

    /* ---------- Rotating tips ---------------------------------------------- */

    const TIPS = [
        'Tip: Press F1 for help once you spawn.',
        'Tip: Use /me for character actions in chat.',
        'Tip: Read the server rules with /rules.',
        'Tip: Press M to open your phone menu.',
        'Tip: Report bugs in the community Discord.'
    ];
    let tipIndex = 0;
    setInterval(function () {
        tipEl.style.opacity = 0;
        setTimeout(function () {
            tipIndex = (tipIndex + 1) % TIPS.length;
            tipEl.textContent = TIPS[tipIndex];
            tipEl.style.opacity = 0.6;
        }, 400);
    }, 5000);

    /* ---------- FiveM loadscreen event handling ---------------------------- */

    /**
     * FiveM posts messages into the loadscreen NUI frame via window 'message'
     * events. The official event types include loadProgress, onLogLine,
     * startInitFunctionOrder, initFunctionInvoked, etc. We only need the two
     * requested by the spec:
     *
     *   loadProgress -> { eventName, loadFraction }  (fraction 0..1)
     *   onLogLine    -> { eventName, message }       (a console log line)
     *
     * loadFraction drives the bar width; onLogLine drives the status label.
     */
    let logCount = 0;
    let finished = false;

    window.addEventListener('message', function (event) {
        const data = event.data;
        if (!data || !data.eventName) return;

        switch (data.eventName) {

            case 'loadProgress': {
                // loadFraction is 0..1 -> convert to a percentage width.
                const fraction = typeof data.loadFraction === 'number'
                    ? data.loadFraction
                    : 0;
                const pct = Math.max(0, Math.min(1, fraction));
                setProgress(pct);
                break;
            }

            case 'onLogLine': {
                // Show the latest console line as the status label, and count
                // log lines as a secondary (cosmetic) progress signal so the
                // bar keeps moving even if loadProgress events lag.
                logCount++;
                if (typeof data.message === 'string' && data.message.trim()) {
                    progressLabel.textContent = data.message.trim();
                }
                break;
            }

            // The init-function phase events give nicer human-readable labels.
            // They are optional but improve UX; map the phase type to a label.
            case 'startInitFunctionOrder': {
                progressLabel.textContent = 'Loading core systems';
                break;
            }
            case 'startDataFileEntries': {
                progressLabel.textContent = 'Loading resources';
                break;
            }
            case 'performMapLoadFunction': {
                progressLabel.textContent = 'Loading map';
                break;
            }

            default:
                break;
        }
    });

    /**
     * Sets the progress bar width + percentage text and triggers the closing
     * fade-out when loading completes (loadFraction reaches 1).
     */
    function setProgress(fraction) {
        const pct = Math.round(fraction * 100);
        progressBar.style.width = pct + '%';
        progressPct.textContent = pct + '%';

        if (pct >= 100 && !finished) {
            finished = true;
            progressLabel.textContent = 'Loading complete';
            // Cosmetic fade-out. FiveM itself shuts the loadscreen down via
            // SHUTDOWN_LOADING_SCREEN (we left loadscreen_manual_shutdown off).
            setTimeout(function () {
                root.classList.add('fade-out');
            }, 300);
        }
    }

    /* ---------- Initialize volume icon on load ----------------------------- */
    updateVolumeIcon();

})();
