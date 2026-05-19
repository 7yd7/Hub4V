export default {
  async fetch(request, env, context) {
    const url = new URL(request.url);

    // Get the backend Nginx server URL strictly from Cloudflare Environment Variables
    const NGINX_SERVER = env.NGINX_SERVER;

    if (!NGINX_SERVER) {
      return new Response("Configuration Error: NGINX_SERVER environment variable is missing.", { status: 500 });
    }

    // Clean headers to bypass Cloudflare Error 1003 (Direct IP access forbidden)
    // We filter out Cloudflare's own internal proxy headers and Host headers
    const cleanHeaders = new Headers();
    const headersToForward = ["accept", "user-agent", "accept-language", "accept-encoding", "content-type"];
    for (const header of headersToForward) {
      const value = request.headers.get(header);
      if (value) {
        cleanHeaders.set(header, value);
      }
    }

    // 1. Forward all static assets (CSS, JS, Images, etc.) directly to the Nginx server on Orihost
    if (url.pathname !== "/" && url.pathname !== "") {
      return fetch(`${NGINX_SERVER}${url.pathname}${url.search}`, {
        headers: cleanHeaders
      });
    }

    const accept = request.headers.get("Accept") || request.headers.get("accept") || "";

    // 2. If it's a browser requesting the home page HTML, serve it from Nginx on Orihost
    if (accept.includes("text/html") && !url.searchParams.has("s") && !url.searchParams.has("raw")) {
      return fetch(`${NGINX_SERVER}/`, {
        headers: cleanHeaders
      });
    }

    // 3. Otherwise (Roblox executor, game:HttpGet, curl, etc.), serve the raw Lua script from GitHub
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
