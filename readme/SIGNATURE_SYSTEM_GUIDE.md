# 🔏 Hybrid E-Signature System Guide

## Overview

Flow-Space now features a **Hybrid E-Signature System** that supports both:
1. **Custom Manual Signatures** - Free, instant signatures using mouse/touch
2. **DocuSign Integration** - Certified, legally binding e-signatures with audit trails

## 🚀 Features Implemented

### ✅ Phase 1: Custom Signature Implementation (COMPLETE)

- **Delivery Lead Signature Enforcement**
  - Mandatory signature before report submission
  - Signature capture dialog with validation
  - Signature stored in `digital_signatures` table
  - Backend validation prevents submission without signature

- **Client Signature Enforcement**
  - Mandatory signature before report approval
  - Signature capture in approval workflow
  - Signature validation and error handling
  - Both signatures stored separately in database

- **Signature Display Component**
  - Full signature display with verification badge
  - Compact signature indicator for lists
  - Shows signer name, role, date, and signature image
  - Verification status indicator

### ✅ Phase 2: DocuSign Integration (COMPLETE)

- **DocuSign Service**
  - Full DocuSign eSignature API integration
  - JWT authentication support
  - Envelope creation and management
  - Status tracking and webhook handling

- **Backend Endpoints**
  - `/api/v1/docusign/config` - Get configuration status
  - `/api/v1/docusign/envelopes/create` - Create signing envelope
  - `/api/v1/docusign/envelopes/:reportId/status` - Get envelope status
  - `/api/v1/docusign/envelopes/:reportId` - List all envelopes
  - `/api/v1/docusign/envelopes/:envelopeId/resend` - Resend notification
  - `/api/v1/docusign/envelopes/:envelopeId/void` - Cancel envelope
  - `/api/v1/docusign/webhook` - Process DocuSign webhooks

### ✅ Phase 3: Hybrid Selector (COMPLETE)

- **Signature Method Selector Widget**
  - User-friendly selection between Manual and DocuSign
  - Visual comparison of features and costs
  - Automatic fallback if DocuSign unavailable
  - Clear indication of method availability

---

## 📋 Database Tables

### `digital_signatures`
Stores all digital signatures (both manual and DocuSign)

```sql
CREATE TABLE digital_signatures (
    id UUID PRIMARY KEY,
    report_id UUID REFERENCES sign_off_reports(id),
    signer_id UUID REFERENCES users(id),
    signer_role VARCHAR(50), -- 'deliveryLead', 'clientReviewer'
    signature_type VARCHAR(50), -- 'manual', 'docusign'
    signature_data TEXT, -- Base64 signature image or DocuSign data
    signature_hash VARCHAR(255), -- SHA-256 hash for verification
    ip_address VARCHAR(45),
    user_agent TEXT,
    signed_at TIMESTAMP,
    is_valid BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    UNIQUE(report_id, signer_id, signer_role)
);
```

### `docusign_envelopes`
Tracks DocuSign envelope status

```sql
CREATE TABLE docusign_envelopes (
    id UUID PRIMARY KEY,
    report_id UUID REFERENCES sign_off_reports(id),
    envelope_id VARCHAR(255) UNIQUE, -- DocuSign envelope ID
    signer_email VARCHAR(255),
    signer_name VARCHAR(255),
    status VARCHAR(50), -- 'created', 'sent', 'delivered', 'signed', 'completed'
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    signed_at TIMESTAMP,
    completed_at TIMESTAMP,
    decline_reason TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

---

## 🔧 Setup Instructions

### Option 1: Use Custom Signatures Only (FREE)

**No setup required!** Custom signatures work out of the box.

1. When submitting a report, users will see a signature dialog
2. Users draw their signature with mouse/touch
3. Signature is captured and stored immediately
4. Backend validates signature exists before submission

### Option 2: Enable DocuSign Integration (PREMIUM)

#### Step 1: Create DocuSign Developer Account

1. Go to [DocuSign Developer Center](https://developers.docusign.com/)
2. Sign up for a free Developer Account
3. This gives you a **Demo environment** for testing

#### Step 2: Create Integration Key

1. Log into DocuSign Admin Console
2. Go to **Settings > Integrations > Apps and Keys**
3. Click **Add App and Integration Key**
4. Note your **Integration Key (Client ID)**
5. Generate a **Secret Key**
6. Save both securely

#### Step 3: Get Account and User IDs

1. In DocuSign Admin, go to **Settings > API and Keys**
2. Find your **Account ID** (Account GUID)
3. Find your **User ID** (User GUID)

#### Step 4: Configure Environment Variables

Add to your `backend/.env` file:

```env
# DocuSign Configuration
DOCUSIGN_INTEGRATION_KEY=your-integration-key-here
DOCUSIGN_SECRET_KEY=your-secret-key-here
DOCUSIGN_ACCOUNT_ID=your-account-id-here
DOCUSIGN_USER_ID=your-user-id-here
DOCUSIGN_BASE_URL=https://demo.docusign.net/restapi
DOCUSIGN_AUTH_SERVER=https://account-d.docusign.com
DOCUSIGN_PRODUCTION=false
DOCUSIGN_WEBHOOK_SECRET=your-webhook-secret-here
```

#### Step 5: Install DocuSign SDK (Optional - for advanced features)

```bash
cd backend
npm install docusign-esign
```

#### Step 6: Test Configuration

1. Restart your backend server
2. Check server logs for "DocuSign configuration loaded"
3. In the app, DocuSign option will appear in signature method selector

---

## 💡 How to Use

### For Delivery Leads (Report Submission)

1. Create and fill out your sign-off report
2. Click **"Save & Submit"**
3. Choose signature method:
   - **Manual Signature**: Draw signature immediately → Submit
   - **DocuSign**: Enter signer email → DocuSign envelope sent via email
4. Report submitted (manual) or awaiting signature (DocuSign)

### For Client Reviewers (Report Approval)

1. Open submitted report for review
2. Select **"Approve"** action
3. Choose signature method:
   - **Manual Signature**: Draw signature → Approve immediately
   - **DocuSign**: Receive email from DocuSign → Sign in email → Auto-approved
4. Report marked as approved with signature

### Viewing Signatures

- Approved reports show signature display component
- Shows: Signer name, role, date, signature image
- Verification badge indicates valid signature
- Signature method badge (Manual/DocuSign)

---

## 🔒 Security Features

### Custom Signatures
- ✅ SHA-256 hash of signature for integrity verification
- ✅ IP address and user agent logging
- ✅ Timestamp with server-side validation
- ✅ Unique constraint prevents duplicate signatures
- ✅ Database-level validation before state changes

### DocuSign Signatures
- ✅ Industry-standard e-signature with legal validity
- ✅ Multi-factor authentication options
- ✅ Complete audit trail
- ✅ Tamper-evident certificates
- ✅ Webhook signature verification
- ✅ Compliance with ESIGN, UETA, eIDAS regulations

---

## 💰 Cost Comparison

### Manual Signatures
- **Cost**: FREE
- **Speed**: Instant
- **Legal Validity**: Basic (sufficient for internal approvals)
- **Audit Trail**: Basic (timestamp, IP, user agent)
- **Best For**: Internal workflows, quick approvals

### DocuSign Signatures
- **Cost**: ~$10-40/user/month OR ~$0.50-1 per envelope
- **Speed**: Depends on signer response (email-based)
- **Legal Validity**: Legally binding (court-admissible)
- **Audit Trail**: Comprehensive (DocuSign certificate)
- **Best For**: Client-facing documents, regulatory compliance, legal contracts

---

## 🎯 Workflow Comparison

### Custom Signature Flow
```
1. User clicks "Submit/Approve"
2. Signature dialog appears immediately
3. User draws signature with mouse/touch
4. Signature captured and validated
5. Action completes instantly
```

### DocuSign Flow
```
1. User clicks "Submit/Approve"
2. User enters signer email
3. DocuSign envelope created
4. Email sent to signer
5. Signer receives email from DocuSign
6. Signer clicks link and signs online
7. Webhook updates status in Flow-Space
8. Action completes when signed
```

---

## 🧪 Testing

### Test Manual Signatures
1. Create a test report
2. Submit with manual signature
3. Verify signature appears in approval workflow
4. Check database: `SELECT * FROM digital_signatures WHERE signature_type = 'manual';`

### Test DocuSign (Demo Environment)
1. Configure DocuSign with demo credentials
2. Create a test report
3. Choose DocuSign signature method
4. Use your own email as signer
5. Check email for DocuSign signing link
6. Complete signing in DocuSign
7. Verify status updates in Flow-Space

---

## 📊 Monitoring & Troubleshooting

### Check Signature Records
```sql
-- View all signatures
SELECT 
  ds.*, 
  u.name as signer_name,
  r.title as report_title
FROM digital_signatures ds
JOIN users u ON ds.signer_id = u.id
LEFT JOIN sign_off_reports r ON ds.report_id = r.id
ORDER BY ds.signed_at DESC;
```

### Check DocuSign Envelopes
```sql
-- View DocuSign envelope status
SELECT * FROM docusign_envelopes 
ORDER BY created_at DESC;
```

### Common Issues

**Issue**: "Digital signature required" error even after signing
- **Solution**: Check if signature was stored in `digital_signatures` table
- **Debug**: Look for "✅ Signature stored in database" in server logs

**Issue**: DocuSign option not appearing
- **Solution**: Verify `.env` has all required DocuSign credentials
- **Check**: Server logs for "DocuSign configuration loaded"

**Issue**: DocuSign envelope not sending
- **Solution**: Check Integration Key and Secret Key are correct
- **Debug**: Check server logs for DocuSign API errors
- **Verify**: Account is activated in DocuSign

---

## 🚀 Future Enhancements

Potential future additions:
- [ ] Biometric signature capture (fingerprint/face ID)
- [ ] Bulk signing for multiple reports
- [ ] Custom signature templates
- [ ] Integration with other e-signature providers (Adobe Sign, HelloSign)
- [ ] Signature validation with certificate authorities
- [ ] Automatic signature expiration and renewal
- [ ] Embedded DocuSign signing (iframe instead of email)

---

## 📞 Support

For issues or questions:
1. Check server logs for error messages
2. Verify database tables exist and have correct schema
3. Check `.env` file for configuration
4. Review this guide for setup steps

**DocuSign Support**: [https://support.docusign.com/](https://support.docusign.com/)
**DocuSign API Docs**: [https://developers.docusign.com/docs/](https://developers.docusign.com/docs/)

---

## 📄 License & Compliance

- Custom signatures: Internal use, not certified
- DocuSign: Compliant with ESIGN Act, UETA, eIDAS
- Always consult legal counsel for compliance requirements in your jurisdiction

---

**Last Updated**: November 2025
**Version**: 1.0.0

