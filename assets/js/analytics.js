// Record explicit navigation categories only; never send link URLs or free text.
(() => {
    "use strict";
    const types = new Set(["topic", "related", "product", "consultation"]);

    document.addEventListener("click", (event) => {
        if (!(event.target instanceof Element)) return;
        const link = event.target.closest("a[data-analytics]");
        if (!link || typeof window.gtag !== "function") return;
        const type = link.dataset.analytics;
        if (!types.has(type)) return;

        window.gtag("event", "navigation_click", {
            link_type: type,
            ...(new Set(["sidebar", "article_start", "article_middle", "article_end"]).has(link.dataset.linkPosition)
                ? { link_position: link.dataset.linkPosition } : {}),
            transport_type: "beacon"
        });
    });
})();
