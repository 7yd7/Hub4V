export default {
  async fetch(request, env, context) {
    const url = new URL(request.url);

    const NGINX_SERVER = "http://2.56.246.128:30587";

    if (url.pathname !== "/" && url.pathname !== "") {
      return fetch(`${NGINX_SERVER}${url.pathname}${url.search}`, {
        headers: request.headers
      });
    }

    const accept = request.headers.get("Accept") || request.headers.get("accept") || "";

    if (accept.includes("text/html") && !url.searchParams.has("s") && !url.searchParams.has("raw")) {
      return fetch(`${NGINX_SERVER}/`, {
        headers: request.headers
      });
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
};
