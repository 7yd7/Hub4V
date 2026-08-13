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

      const versionUrl = "https://raw.githubusercontent.com/7yd7/Hub4V/Menu/Script/Version.json";
      try {
        const res = await fetch(versionUrl, {
          headers: { "User-Agent": "Hub4V-Worker" }
        });

        if (!res.ok) {
          return new Response("-- failed to load version file", { status: 502 });
        }

        const version = await res.json();
        const releaseUrl = version && version.latest_release;
        if (!releaseUrl || typeof releaseUrl !== "string") {
          return new Response("-- latest_release missing in Version.json", { status: 502 });
        }

        return Response.redirect(releaseUrl, 302);
      } catch (err) {
        return new Response(`-- fetch error: ${err.message}`, { status: 500 });
      }
    }

    return env.ASSETS.fetch(request);
  }
};
