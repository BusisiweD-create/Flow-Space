const express = require('express');
const router = express.Router();
const axios = require('axios');
const cache = new Map();
const CACHE_TTL_MS = 12 * 60 * 60 * 1000;
let circuitOpenUntil = 0;
let consecutiveFailures = 0;
const BASE_COOLDOWN_MS = Number(process.env.AI_COOLDOWN_MS || (30 * 60 * 1000));
const MAX_COOLDOWN_MS = Number(process.env.AI_MAX_COOLDOWN_MS || (12 * 60 * 60 * 1000));
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';
function makeKey(msgs, temperature, max_tokens) {
  try { return JSON.stringify({ msgs, temperature, max_tokens }); } catch (_) { return String(temperature) + '|' + String(max_tokens); }
}
function getCached(key) {
  const e = cache.get(key);
  if (!e) return null;
  if (Date.now() - e.t > CACHE_TTL_MS) { cache.delete(key); return null; }
  return e.v;
}
function setCached(key, v) { cache.set(key, { t: Date.now(), v }); }

function capitalize(s) { return typeof s === 'string' && s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : ''; }
function words(text) { return (text || '').match(/[A-Za-z][A-Za-z\-']*/g) || []; }
function firstMeaningful(text, count = 2) { return words(text).filter(w => w.length > 2).slice(0, count).map(capitalize).join(' '); }
function deriveKey(name) {
  const parts = words(name);
  let key = parts.map(p => p[0]).join('');
  if (key.length < 2) key = (name || '').replace(/[^A-Za-z]/g, '').slice(0, 4);
  key = (key || 'PRJ').toUpperCase().replace(/[^A-Z]/g, '');
  if (key.length > 6) key = key.slice(0, 6);
  if (key.length < 2) key = (key + 'PRJ').slice(0, Math.max(2, key.length));
  return key;
}
function parseField(source, label) {
  const m = (source || '').match(new RegExp(label + "\s*:\\s*([^\n]+)", 'i'));
  return m ? m[1].trim() : '';
}
function generateReportContent(userText) {
  const committed = Number((userText.match(/Committed\s*:\s*(\d+)/i) || [])[1] || 0);
  const completed = Number((userText.match(/Completed\s*:\s*(\d+)/i) || [])[1] || 0);
  const passRate = (userText.match(/AvgTestPassRate\s*:\s*([0-9.]+)%/i) || [])[1] || '';
  const title = parseField(userText, 'Title') || firstMeaningful(userText, 2) || 'Deliverable Report';
  const dod = parseField(userText, 'DefinitionOfDone');
  const lines = [];
  lines.push(`# ${title}`);
  lines.push('');
  lines.push('## Executive Summary');
  lines.push(`This report summarizes progress and quality signals for ${title}.`);
  lines.push('');
  lines.push('## Sprint Performance');
  lines.push(`Committed: ${committed}`);
  lines.push(`Completed: ${completed}`);
  if (committed > 0) {
    const velocity = completed;
    const completionRate = committed ? Math.round((completed / committed) * 100) : 0;
    lines.push(`Velocity: ${velocity}`);
    lines.push(`Completion Rate: ${completionRate}%`);
  }
  lines.push('');
  lines.push('## Quality');
  if (passRate) lines.push(`Average Test Pass Rate: ${passRate}%`);
  lines.push('Defect trends and coverage appear within expected ranges based on current scope.');
  lines.push('');
  lines.push('## Readiness');
  lines.push(dod ? `Definition of Done: ${dod}` : 'Definition of Done: See checklist in deliverable details.');
  lines.push('The deliverable is progressing toward readiness subject to final validations and sign-offs.');
  lines.push('');
  lines.push('## Recommendations');
  lines.push('- Address any remaining blocking tasks early in the next sprint');
  lines.push('- Maintain test coverage and close critical defects before release');
  lines.push('- Communicate risks and dependencies to stakeholders');
  return lines.join('\n');
}
function generateFallback(msgs) {
  const sys = (msgs.find(m => m.role === 'system') || {}).content || '';
  const userAgg = msgs.filter(m => m.role === 'user').map(m => m.content || '').join('\n');
  const lc = (sys || '').toLowerCase();
  if (lc.includes('project key')) {
    const name = parseField(userAgg, 'Name') || firstMeaningful(userAgg, 2) || 'Project';
    return deriveKey(name);
  }
  if (lc.includes('project name')) {
    const desc = parseField(userAgg, 'Description') || userAgg;
    const candidate = firstMeaningful(desc, 2);
    return candidate || 'Project Nova';
  }
  if (lc.includes('project description')) {
    const name = parseField(userAgg, 'Name') || firstMeaningful(userAgg, 2) || 'Project';
    return `The ${name} project aims to deliver measurable outcomes with a clear scope, stakeholders, and success criteria.`;
  }
  if (lc.includes('sprint name')) {
    const project = parseField(userAgg, 'Project') || firstMeaningful(userAgg, 1) || 'Program';
    return `${project} Sprint Alpha`;
  }
  if (lc.includes('sprint goal') || lc.includes('sprint') && lc.includes('summary')) {
    return 'Goal: Deliver prioritized scope with focus on quality and stakeholder value. Scope: Key features, defect fixes, and testing.';
  }
  if (lc.includes('deliverable title')) {
    const desc = parseField(userAgg, 'Description') || userAgg;
    const candidate = firstMeaningful(desc, 3);
    return candidate || 'Quality Assurance Summary';
  }
  if (lc.includes('deliverable description')) {
    const title = parseField(userAgg, 'Title') || firstMeaningful(userAgg, 2) || 'Deliverable';
    return `${title} focuses on outcomes, constraints, and acceptance criteria to ensure stakeholder readiness.`;
  }
  if (lc.includes('acceptance criteria') || lc.includes('checklist')) {
    return ['Requirements clarified and documented','Unit tests pass for core modules','Integration tests cover key flows','No critical or high defects open','Performance within agreed thresholds','Security checks pass and secrets managed','Documentation updated and shared'].join('\n');
  }
  if (lc.includes('structured report content')) {
    return generateReportContent(userAgg);
  }
  if (lc.includes('known limitations')) {
    return ['Dependency risks impacting timelines','Limited test coverage in edge cases','Performance impact under peak load'].join('\n');
  }
  if (lc.includes('next steps')) {
    return ['Prioritize remaining scope and defects','Increase test coverage in critical paths','Coordinate deployment plan and sign-offs'].join('\n');
  }
  const generic = firstMeaningful(userAgg, 3);
  return generic || 'Draft content ready for refinement.';
}

router.post('/chat', async (req, res) => {
  const { messages, prompt, temperature, max_tokens } = req.body || {};
  const msgs = Array.isArray(messages) ? messages : (prompt ? [{ role: 'user', content: prompt }] : []);
  try {
    const key = makeKey(msgs, temperature, max_tokens);
    const cached = getCached(key);
    if (cached) {
      return res.json({ success: true, data: cached });
    }
    const forceFallback = String(process.env.AI_FORCE_FALLBACK || '').toLowerCase() === 'true';
    const apiKey = process.env.OPENAI_API_KEY;
    const now = Date.now();
    const circuitOpen = now < circuitOpenUntil;
    if (!apiKey || forceFallback || circuitOpen) {
      const fb = generateFallback(msgs);
      const data = { content: fb, usage: {}, model: 'fallback' };
      setCached(key, data);
      return res.json({ success: true, data });
    }
    if (!msgs || msgs.length === 0) {
      return res.status(400).json({ error: 'messages or prompt required' });
    }
    const r = await axios.post('https://api.openai.com/v1/chat/completions', {
      model: OPENAI_MODEL,
      messages: msgs,
      temperature: typeof temperature === 'number' ? temperature : 0.7,
      max_tokens: typeof max_tokens === 'number' ? max_tokens : 512
    }, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });
    const data = r.data || {};
    const choice = (data.choices && data.choices[0]) || {};
    const message = choice.message || {};
    const payload = { content: message.content || '', usage: data.usage || {}, model: data.model || OPENAI_MODEL };
    setCached(key, payload);
    consecutiveFailures = 0;
    circuitOpenUntil = 0;
    return res.json({ success: true, data: payload });
  } catch (error) {
    const key = makeKey(msgs, temperature, max_tokens);
    const fb = generateFallback(msgs);
    const data = { content: fb, usage: {}, model: 'fallback' };
    setCached(key, data);
    const status = (error && error.response && error.response.status) || 0;
    const isQuotaLike = status === 429 || status === 401 || status === 403;
    consecutiveFailures = isQuotaLike ? (consecutiveFailures + 1) : consecutiveFailures;
    const backoff = Math.min(BASE_COOLDOWN_MS * Math.pow(2, Math.max(0, consecutiveFailures - 1)), MAX_COOLDOWN_MS);
    circuitOpenUntil = Date.now() + backoff;
    return res.json({ success: true, data });
  }
});

router.get('/chat', async (req, res) => {
  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }
    return res.status(405).json({ error: 'Method Not Allowed', message: 'Use POST /chat with a JSON body: { messages: [...] }' });
  } catch (error) {
    return res.status(500).json({ error: error.message || 'Internal error' });
  }
});

module.exports = router;