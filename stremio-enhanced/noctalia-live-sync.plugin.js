/**
 * @name Noctalia Live Sync
 * @description Reloads the Noctalia theme when Noctalia rewrites it, without restarting Stremio.
 * @version 1.1.0
 * @author augussst
 */

(function () {
    // Only ever reads the local theme file that Stremio Enhanced loaded itself:
    // a file: URL ending in /stremio-enhanced/themes/noctalia.theme.css.
    // Any other URL (including web addresses) is ignored: no network requests.
    const THEME_SUFFIX = "/stremio-enhanced/themes/noctalia.theme.css";
    let lastCss = null;

    function localThemeUrl() {
        const link = document.getElementById("activeTheme");
        if (!link || !link.href) return null;
        let url;
        try {
            url = new URL(link.href);
        } catch (_e) {
            return null;
        }
        if (url.protocol !== "file:") return null;
        if (!decodeURIComponent(url.pathname).endsWith(THEME_SUFFIX)) return null;
        url.search = "";
        url.hash = "";
        return url.href;
    }

    setInterval(async () => {
        const base = localThemeUrl();
        if (!base) return;
        try {
            const res = await fetch(base + "?t=" + Date.now(), { cache: "no-store" });
            const text = await res.text();
            if (lastCss !== null && text !== lastCss) {
                document.getElementById("activeTheme").href = base + "?t=" + Date.now();
            }
            lastCss = text;
        } catch (_e) {}
    }, 2000);
})();
