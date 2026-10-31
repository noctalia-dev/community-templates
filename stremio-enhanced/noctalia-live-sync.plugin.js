/**
 * @name Noctalia Live Sync
 * @description Automatically reloads the Noctalia theme in real-time when wallpaper or palette changes, without restarting Stremio.
 * @version 1.0.0
 * @author augussst
 */

(function () {
    let lastCss = null;
    setInterval(async () => {
        const link = document.getElementById("activeTheme");
        if (!link || !link.href || !link.href.includes("noctalia.theme.css")) return;
        const baseHref = link.href.split("?")[0];
        try {
            const res = await fetch(baseHref + "?t=" + Date.now(), { cache: "no-store" });
            const text = await res.text();
            if (lastCss !== null && text !== lastCss) {
                link.href = baseHref + "?t=" + Date.now();
            }
            lastCss = text;
        } catch (_e) {}
    }, 2000);
})();
