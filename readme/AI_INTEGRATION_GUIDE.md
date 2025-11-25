# AI Integration Guide for Release Readiness Gate

## Quick Start: OpenAI Integration

### Step 1: Install Dependencies
```bash
cd backend
npm install openai
```

### Step 2: Add Environment Variable
Add to `backend/.env`:
```
OPENAI_API_KEY=your-api-key-here
```

### Step 3: Update Backend Endpoint

Replace the rule-based analysis in `backend/server.js` with OpenAI integration:

```javascript
const OpenAI = require('openai');
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// In the /api/v1/release-readiness/analyze endpoint:
app.post('/api/v1/release-readiness/analyze', authenticateToken, async (req, res) => {
  try {
    const {
      deliverableId,
      deliverableTitle,
      deliverableDescription,
      definitionOfDone = [],
      evidenceLinks = [],
      sprintIds = [],
      sprintMetrics = {},
      knownLimitations,
    } = req.body;

    // Prepare prompt for AI analysis
    const prompt = `Analyze the release readiness of this deliverable:

Title: ${deliverableTitle}
Description: ${deliverableDescription}

Definition of Done Items (${definitionOfDone.length}):
${definitionOfDone.map((item, i) => `${i + 1}. ${item}`).join('\n')}

Evidence Links (${evidenceLinks.length}):
${evidenceLinks.map((link, i) => `${i + 1}. ${link}`).join('\n')}

Sprints Linked: ${sprintIds.length}
Sprint Metrics: ${JSON.stringify(sprintMetrics, null, 2)}
Known Limitations: ${knownLimitations || 'None'}

Analyze and provide:
1. Overall readiness status (green/amber/red)
2. List of issues found
3. Specific recommendations
4. Risk factors
5. Missing items
6. Priority actions (top 3)
7. AI insights summary

Return JSON format:
{
  "status": "green|amber|red",
  "confidence": 0.0-1.0,
  "issues": ["issue1", "issue2"],
  "recommendations": ["rec1", "rec2"],
  "risks": ["risk1"],
  "missingItems": ["item1"],
  "priorityActions": ["action1", "action2", "action3"],
  "aiInsights": "summary text"
}`;

    // Call OpenAI
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are an expert software delivery analyst. Analyze deliverable readiness and provide structured, actionable feedback."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.3,
      response_format: { type: "json_object" }
    });

    // Parse AI response
    const aiResponse = JSON.parse(completion.choices[0].message.content);
    
    // Return structured response
    res.json({
      success: true,
      data: {
        status: aiResponse.status,
        confidence: aiResponse.confidence || 0.8,
        issues: aiResponse.issues || [],
        recommendations: aiResponse.recommendations || [],
        risks: aiResponse.risks || [],
        missingItems: aiResponse.missingItems || [],
        priorityActions: aiResponse.priorityActions || [],
        aiInsights: aiResponse.aiInsights || '',
      },
    });

  } catch (error) {
    console.error('Error in AI readiness analysis:', error);
    
    // Fallback to rule-based analysis
    // ... existing rule-based code ...
  }
});
```

### Step 4: Test Integration
1. Start backend server
2. Create a deliverable in the app
3. Check console for AI analysis logs
4. Verify AI insights appear in UI

---

## Alternative: Anthropic Claude

### Installation
```bash
npm install @anthropic-ai/sdk
```

### Integration
```javascript
const Anthropic = require('@anthropic-ai/sdk');
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const message = await anthropic.messages.create({
  model: "claude-3-opus-20240229",
  max_tokens: 1024,
  messages: [{
    role: "user",
    content: prompt
  }]
});
```

---

## Cost Optimization Tips

1. **Use GPT-3.5-turbo** for faster/cheaper analysis (if GPT-4 not needed)
2. **Cache results** for similar deliverables
3. **Batch analysis** when possible
4. **Set token limits** to control costs
5. **Use streaming** for better UX

---

## Error Handling

Always include fallback to rule-based analysis:
```javascript
try {
  // AI analysis
} catch (error) {
  console.error('AI service error:', error);
  // Fallback to existing rule-based analysis
  return ruleBasedAnalysis(data);
}
```

