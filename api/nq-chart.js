// api/nq-chart.js
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  // No CDN cache — always fresh
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');

  const interval = req.query.interval || '1d';
  const range    = req.query.range    || '6mo';

  const HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36',
    'Accept': 'application/json',
    'Referer': 'https://finance.yahoo.com',
  };

  const chartUrl = `https://query1.finance.yahoo.com/v8/finance/chart/NQ%3DF?interval=${interval}&range=${range}&includePrePost=false`;
  const quoteUrl = `https://query1.finance.yahoo.com/v7/finance/quote?symbols=NQ%3DF&fields=regularMarketPrice,regularMarketChange,regularMarketChangePercent,regularMarketPreviousClose`;

  try {
    // Fetch chart data and live quote in parallel
    const [chartRes, quoteRes] = await Promise.all([
      fetch(chartUrl, { headers: HEADERS }),
      fetch(quoteUrl, { headers: HEADERS }),
    ]);

    if (!chartRes.ok) return res.status(502).json({ error: `Yahoo chart returned ${chartRes.status}` });

    const raw = await chartRes.json();
    const result = raw?.chart?.result?.[0];
    if (!result) return res.status(502).json({ error: 'No chart data in response' });

    const meta       = result.meta || {};
    const timestamps = result.timestamp || [];
    const q          = result.indicators?.quote?.[0] || {};
    const opens      = q.open   || [];
    const highs      = q.high   || [];
    const lows       = q.low    || [];
    const closes     = q.close  || [];
    const volumes    = q.volume || [];

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
        o: opens[i]   != null ? +opens[i].toFixed(2)   : null,
        h: highs[i]   != null ? +highs[i].toFixed(2)   : null,
        l: lows[i]    != null ? +lows[i].toFixed(2)    : null,
        c: closes[i]  != null ? +closes[i].toFixed(2)  : null,
        v: volumes[i] != null ? volumes[i]              : 0,
        label: fmt(ts),
      }))
      .filter(b => b.c != null);

    // Extract live quote fields — fall back to chart meta if quote fetch failed
    let regularMarketPrice         = meta.regularMarketPrice;
    let regularMarketChange        = null;
    let regularMarketChangePercent = null;
    let previousClose              = meta.chartPreviousClose;

    if (quoteRes.ok) {
      try {
        const quoteData = await quoteRes.json();
        const qt = quoteData?.quoteResponse?.result?.[0];
        if (qt) {
          regularMarketPrice         = qt.regularMarketPrice         ?? regularMarketPrice;
          regularMarketChange        = qt.regularMarketChange        ?? null;
          regularMarketChangePercent = qt.regularMarketChangePercent ?? null;
          previousClose              = qt.regularMarketPreviousClose ?? previousClose;
        }
      } catch (_) { /* fall through to chart meta values */ }
    }

    return res.status(200).json({
      symbol: 'NQ=F',
      currency: meta.currency || 'USD',
      regularMarketPrice,
      regularMarketChange,
      regularMarketChangePercent,
      previousClose,
      bars,
    });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}