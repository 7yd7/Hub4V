export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname !== "/" && url.pathname !== "") {
      return fetch(`https://7yd7.pages.dev${url.pathname}${url.search}`, {
        headers: request.headers
      });
    }

    const accept = request.headers.get("Accept") || request.headers.get("accept") || "";

    if (accept.includes("text/html")) {
      return fetch("https://7yd7.pages.dev/", {
        headers: {
          "User-Agent": request.headers.get("User-Agent") || request.headers.get("user-agent") || "",
        }
      });
    }

    const rawUrl = "https://raw.githubusercontent.com/7yd7/Hub4V/Menu/client.luau";

    try {
      const res = await fetch(rawUrl, { cf: { cacheTtl: 120, cacheEverything: true } });

      if (!res.ok) {
        return new Response(`-- failed to fetch script source: ${res.status}`, {
          status: 502,
          headers: {
            "content-type": "text/plain; charset=utf-8",
            "cache-control": "no-store",
          },
        });
      }

      const text = await res.text();
      return new Response(text, {
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store",
          "x-content-type-options": "nosniff",
        },
      });
    } catch (err) {
      return new Response(`-- fetch error: ${err.message}`, {
        status: 500,
        headers: {
          "content-type": "text/plain; charset=utf-8",
        },
      });
    }
  }
};
