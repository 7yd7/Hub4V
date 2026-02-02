export default {
    async fetch(request) {
        return new Response('loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub4V/Menu/client.luau"))()', {
            headers: { "content-type": "text/plain" },
        });
    },
};
