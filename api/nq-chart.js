// api/nq-chart.js  –  drop this file into your project's /api folder
// Vercel will automatically serve it at /api/nq-chart
// It proxies Yahoo Finance on the server (no CORS issues) and
// returns clean OHLC + label data for the dashboard canvas chart.

export default async function handler(req, res) {
  // Allow your dashboard origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate=120');

  const interval = req.query.interval || '1d';
  const range    = req.query.range    || '6mo';

  const url = `https://query1.finance.yahoo.com/v8/finance/chart/NQ%3DF?interval=${interval}&range=${range}&includePrePost=false`;

  try {
    const yRes = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36',
        'Accept': 'application/json',
        'Referer': 'https://finance.yahoo.com',
      }
    });

    if (!yRes.ok) {
      return res.status(502).json({ error: `Yahoo returned ${yRes.status}` });
    }

    const raw = await yRes.json();
    const result = raw?.chart?.result?.[0];
    if (!result) return res.status(502).json({ error: 'No data in response' });

    const meta       = result.meta || {};
    const timestamps = result.timestamp || [];
    const q          = result.indicators?.quote?.[0] || {};
    const opens      = q.open  || [];
    const highs      = q.high  || [];
    const lows       = q.low   || [];
    const closes     = q.close || [];

    // Format x-axis label depending on interval
    function fmt(ts) {
      const d = new Date(ts * 1000);
      if (interval.includes('m') || interval === '1h') {
        return d.toLocaleString('en-US', { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit', hour12:false });
      }
      return d.toLocaleDateString('en-US', { month:'short', day:'numeric' });
    }

    const bars = timestamps
      .map((ts, i) => ({
        t: ts,
        o: opens[i]  != null ? +opens[i].toFixed(2)  : null,
        h: highs[i]  != null ? +highs[i].toFixed(2)  : null,
        l: lows[i]   != null ? +lows[i].toFixed(2)   : null,
        c: closes[i] != null ? +closes[i].toFixed(2) : null,
        label: fmt(ts),
      }))
      .filter(b => b.c != null);

    return res.status(200).json({
      symbol: 'NQ=F',
      currency: meta.currency || 'USD',
      regularMarketPrice: meta.regularMarketPrice,
      previousClose: meta.chartPreviousClose,
      bars,
    });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}