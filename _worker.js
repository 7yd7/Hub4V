export default {
  async fetch(request, env, context) {
    const url = new URL(request.url);

    // Forward all static assets (CSS, JS, Images, etc.) directly to the static assets provider
    if (url.pathname !== "/" && url.pathname !== "") {
      return env.ASSETS.fetch(request);
    }

    const accept = request.headers.get("Accept") || request.headers.get("accept") || "";

    // Exact Novoline-style check:
    // If it's a browser requesting HTML (and not explicitly asking for the script via ?s or ?raw)
    if (accept.includes("text/html") && !url.searchParams.has("s") && !url.searchParams.has("raw")) {
      return env.ASSETS.fetch(request);
    }

    // Roblox executor (game:HttpGet), curl, or explicitly requested raw Lua script
    const rawUrl = "https://raw.githubusercontent.com/7yd7/Hub4V/Menu/client.luau";
    try {
      const res = await fetch(rawUrl, { cf: { cacheTtl: 60, cacheEverything: true } });
      if (!res.ok) {
        return new Response("-- failed to load script from github", { status: 502 });
      }
      const text = await res.text();
      return new Response(text, {
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store",
          "x-content-type-options": "nosniff"
        }
      });
    } catch (err) {
      return new Response(`-- fetch error: ${err.message}`, { status: 500 });
    }
  }
};
