const WEATHERAPI_BASE = 'https://api.weatherapi.com/v1';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/forecast') {
      return handleForecast(url, env);
    }

    if (url.pathname === '/search') {
      return handleSearch(url, env);
    }

    return new Response('Not found', { status: 404 });
  },
};

async function handleForecast(url, env) {
  const q = (url.searchParams.get('q') ?? '').trim();
  const days = url.searchParams.get('days') ?? '3';

  if (q.length < 2 || q.length > 64) {
    return new Response('Bad request', { status: 400 });
  }
  if (!/^\d+$/.test(days) || Number(days) < 1 || Number(days) > 14) {
    return new Response('Bad request', { status: 400 });
  }

  const upstream = new URL(`${WEATHERAPI_BASE}/forecast.json`);
  upstream.searchParams.set('key', env.WEATHER_API_KEY);
  upstream.searchParams.set('q', q);
  upstream.searchParams.set('days', days);
  upstream.searchParams.set('aqi', 'yes');
  upstream.searchParams.set('alerts', 'no');

  const res = await fetch(upstream, { cf: { cacheTtl: 600 } });
  const body = await res.text();

  return new Response(body, {
    status: res.status,
    headers: {
      'content-type': 'application/json',
      'cache-control': 'public, max-age=600',
      'access-control-allow-origin': '*',
    },
  });
}

async function handleSearch(url, env) {
  const q = (url.searchParams.get('q') ?? '').trim();

  if (q.length < 2 || q.length > 64) {
    return new Response('Bad request', { status: 400 });
  }

  const upstream = new URL(`${WEATHERAPI_BASE}/search.json`);
  upstream.searchParams.set('key', env.WEATHER_API_KEY);
  upstream.searchParams.set('q', q);

  const res = await fetch(upstream, { cf: { cacheTtl: 600 } });
  const body = await res.text();

  return new Response(body, {
    status: res.status,
    headers: {
      'content-type': 'application/json',
      'cache-control': 'public, max-age=600',
      'access-control-allow-origin': '*',
    },
  });
}