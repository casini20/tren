// api/ai-analysis.js  –  drop this file into your project's /api folder
// Vercel will automatically serve it at /api/ai-analysis
// It proxies Groq (Llama 3.3 70B) on the server (no CORS issues) and
// returns AI market analysis text for the dashboard.

export const config = {
  api: { bodyParser: true }
};

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const apiKey = process.env.GROQ_API_KEY;
if (!apiKey) {
  return res.status(200).json({ text: 'NO KEY FOUND' });
}

  let systemPrompt, messages;
  try {
    ({ systemPrompt, messages } = req.body);
  } catch (e) {
    return res.status(400).json({ error: 'Could not parse request body: ' + e.message });
  }

  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'Invalid request body — messages missing' });
  }

  const groqMessages = [
    { role: 'system', content: systemPrompt || 'You are a professional NQ Futures market analyst.' },
    ...messages.map(m => ({ role: m.role === 'assistant' ? 'assistant' : 'user', content: m.content }))
  ];

  try {
    const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: groqMessages,
        max_tokens: 1024,
        temperature: 0.4
      })
    });

    if (!groqRes.ok) {
      const errData = await groqRes.json().catch(() => ({}));
      return res.status(502).json({ error: `Groq returned ${groqRes.status}: ${errData?.error?.message || ''}` });
    }

    const data = await groqRes.json();
    const text = data?.choices?.[0]?.message?.content || '';
    return res.status(200).json({ text });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}