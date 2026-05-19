export default {
  async fetch(request, env, context) {
    const url = new URL(request.url);

    // If the URL has the "?s" parameter, serve the raw Lua script directly
    if (url.searchParams.has("s")) {
      const rawUrl = "https://raw.githubusercontent.com/7yd7/Hub4V/Menu/client.luau";
      try {
        const res = await fetch(rawUrl, { cf: { cacheTtl: 60, cacheEverything: true } });
        if (!res.ok) {
          return new Response("-- failed to load script from github", { status: 502 });
        }
        const text = await res.text();
        return new Response(text, {
          headers: { "content-type": "text/plain; charset=utf-8" }
        });
      } catch (err) {
        return new Response(`-- fetch error: ${err.message}`, { status: 500 });
      }
    }

    // Otherwise, serve the static website files from Cloudflare Pages
    return env.ASSETS.fetch(request);
  }
};
