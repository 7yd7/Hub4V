export default {
  async fetch(request, env, context) {
    const url = new URL(request.url);
    const accept = request.headers.get("Accept") || request.headers.get("accept") || "";
    const userAgent = request.headers.get("User-Agent") || request.headers.get("user-agent") || "";

    if (url.pathname === "/" || url.pathname === "" || url.pathname.toLowerCase() === "/client.luau") {
      
      const wantsScript = url.searchParams.has("s") || url.searchParams.has("raw") || url.searchParams.has("script");
      const isRealBrowser = accept.includes("text/html") && !userAgent.toLowerCase().includes("roblox");

      if (isRealBrowser && !wantsScript) {
        return env.ASSETS.fetch(request);
      }

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

    return env.ASSETS.fetch(request);
  }
};
