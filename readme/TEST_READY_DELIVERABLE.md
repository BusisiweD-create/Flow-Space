# How to Test a "Ready for Submission" Deliverable

## 🎯 Goal: Achieve GREEN Status (Ready for Release)

The AI Release Readiness Gate evaluates deliverables and assigns a status:
- **🟢 GREEN**: Ready for Release - All criteria met
- **🟠 AMBER**: Ready with Issues - Some items need attention  
- **🔴 RED**: Not Ready - Critical issues must be resolved

---

## ✅ Requirements for GREEN Status

### 1. **Definition of Done (DoD)**
- **Minimum**: 3 or more items
- **Examples**:
  - Code review completed
  - Unit tests passing (>80% coverage)
  - Integration tests passing
  - Documentation updated
  - Demo prepared
  - Performance benchmarks met

### 2. **Evidence Links** (All 4 types required)
The AI looks for specific keywords in your evidence links:

#### ✅ Demo Link
- Must contain: `demo` or `video`
- **Example**: `https://demo.example.com/feature` or `https://youtube.com/watch?v=xyz`

#### ✅ Repository Link
- Must contain: `repo`, `github`, or `gitlab`
- **Example**: `https://github.com/company/project` or `https://gitlab.com/repo`

#### ✅ Test Evidence
- Must contain: `test` or `coverage`
- **Example**: `https://test-results.example.com` or `https://coverage.report.com`

#### ✅ Documentation
- Must contain: `doc` or `guide`
- **Example**: `https://docs.example.com/user-guide` or `https://wiki.example.com/guide`

### 3. **Sprint Association**
- **Minimum**: At least 1 sprint linked
- Link the sprint(s) that contributed to this deliverable

### 4. **Optional (Improves Status)**
- Sprint metrics (test pass rate > 90%)
- No critical defects
- Known limitations documented (if any)

---

## 📝 Step-by-Step Testing Guide

### Step 1: Create a New Deliverable
1. Navigate to **Create Deliverable** page
2. Fill in:
   - **Title**: e.g., "User Authentication Feature"
   - **Description**: e.g., "Complete user login and registration system"

### Step 2: Add Definition of Done Items
Click **"Add Definition of Done Item"** and add at least 3 items:
```
✅ Code review completed
✅ Unit tests passing (>80% coverage)
✅ Integration tests passing
✅ Documentation updated
✅ Demo prepared
```

### Step 3: Add Evidence Links
Click **"Add Evidence Link"** and add all 4 required types:

**Demo Link:**
```
https://demo.example.com/user-auth
```

**Repository Link:**
```
https://github.com/company/project
```

**Test Evidence:**
```
https://test-results.example.com/coverage-report
```

**Documentation:**
```
https://docs.example.com/user-guide
```

### Step 4: Link a Sprint
- Select at least one sprint from the dropdown
- This shows which sprint(s) contributed to the deliverable

### Step 5: Watch the AI Analysis
- The AI widget will automatically analyze as you fill in the form
- Check the browser console for detailed logs: `🤖 AI: Analysis complete!`
- The status should change from **RED** → **AMBER** → **GREEN** as you add items

### Step 6: Verify GREEN Status
When you see:
- **Status**: 🟢 **"✅ Ready for Release - All criteria met"**
- **Issues**: 0 issues found
- **Confidence**: High (usually 85-95%)

### Step 7: Submit
- The submit button should be **enabled** (not grayed out)
- Click **"Create Deliverable"**
- You should see a success message and be redirected to the dashboard

---

## 🧪 Quick Test Scenarios

### Scenario 1: Perfect Deliverable (GREEN)
```
Title: "User Authentication Feature"
Description: "Complete login system"
DoD Items: 5 items (code review, tests, docs, demo, benchmarks)
Evidence Links:
  - https://demo.example.com/auth (demo)
  - https://github.com/company/auth (repo)
  - https://test.example.com/coverage (test)
  - https://docs.example.com/auth-guide (doc)
Sprints: 1 sprint linked
```
**Expected**: 🟢 GREEN status

### Scenario 2: Missing Evidence (AMBER)
```
Title: "User Authentication Feature"
Description: "Complete login system"
DoD Items: 3 items
Evidence Links:
  - https://demo.example.com/auth (demo)
  - https://github.com/company/auth (repo)
  - Missing: test evidence
  - Missing: documentation
Sprints: 1 sprint linked
```
**Expected**: 🟠 AMBER status (2 issues: missing test, missing docs)

### Scenario 3: Minimal Deliverable (RED)
```
Title: "User Authentication Feature"
Description: "Complete login system"
DoD Items: 1 item (too few)
Evidence Links: None
Sprints: None
```
**Expected**: 🔴 RED status (multiple issues)

---

## 🔍 Debugging Tips

### If Status Stays RED:
1. **Check Console Logs**: Look for `🤖 AI: Analysis complete!` messages
2. **Verify Evidence Links**: Make sure they contain the required keywords
3. **Count DoD Items**: Need at least 3
4. **Check Sprint Link**: At least 1 sprint must be linked

### If Status is AMBER:
- You can still submit, but it's recommended to address the issues
- Check the "Issues" section in the AI widget
- Add the missing evidence links or DoD items

### If Status is GREEN:
- ✅ All criteria met!
- Submit button should be enabled
- Ready for client review

---

## 📊 Status Breakdown

| Status | Issues Count | Can Submit? | Internal Approval Needed? |
|--------|--------------|-------------|---------------------------|
| 🟢 GREEN | 0 issues | ✅ Yes | ❌ No |
| 🟠 AMBER | 1-2 issues | ✅ Yes | ❌ No (but recommended to fix) |
| 🔴 RED | 3+ issues | ❌ No | ✅ Yes (or fix issues) |

---

## 🎬 Example: Complete Test Flow

1. **Start**: Open Create Deliverable page
2. **Add Title**: "Payment Processing Module"
3. **Add Description**: "Secure payment gateway integration"
4. **Add DoD** (5 items):
   - Code review completed
   - Unit tests passing
   - Security audit passed
   - Documentation complete
   - Demo video recorded
5. **Add Evidence** (4 links):
   - `https://demo.company.com/payment` (demo)
   - `https://github.com/company/payment-repo` (repo)
   - `https://tests.company.com/payment-coverage` (test)
   - `https://docs.company.com/payment-guide` (doc)
6. **Link Sprint**: Select "Sprint 1" from dropdown
7. **Watch AI**: Status should show 🟢 GREEN
8. **Submit**: Click "Create Deliverable"
9. **Success**: Redirected to dashboard

---

## 💡 Pro Tips

1. **Use Keywords**: The AI searches for keywords in evidence links, so include words like "demo", "github", "test", "doc" in your URLs
2. **Real URLs Work Best**: Even if URLs are fake, use realistic formats
3. **Check Console**: The browser console shows detailed AI analysis logs
4. **Refresh Analysis**: Click the refresh button (🔄) in the AI widget to re-analyze
5. **Internal Approval**: If status is RED, you can request internal approval to bypass the gate

---

## 🐛 Troubleshooting

**Q: AI widget not showing?**
- Make sure you're on `/deliverable-setup` route (not the old screen)
- Check browser console for errors

**Q: Status not updating?**
- The widget re-analyzes when you add DoD items, evidence links, or sprints
- Try clicking the refresh button in the AI widget

**Q: Can't submit even with GREEN status?**
- Check if there's an internal approval requirement
- Verify the form validation passes (title and description required)

---

## ✅ Success Checklist

Before submitting, verify:
- [ ] Title is filled
- [ ] Description is filled
- [ ] At least 3 DoD items added
- [ ] 4 evidence links added (demo, repo, test, doc)
- [ ] At least 1 sprint linked
- [ ] AI status shows 🟢 GREEN (or 🟠 AMBER with approval)
- [ ] Submit button is enabled
- [ ] No console errors

---

**Ready to test?** Follow the steps above and watch the AI analyze your deliverable in real-time! 🚀

