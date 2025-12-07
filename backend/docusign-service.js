/**
 * DocuSign E-Signature Integration Service
 * Handles DocuSign API authentication, envelope creation, and webhook processing
 * 
 * Setup Instructions:
 * 1. Install DocuSign SDK: npm install docusign-esign
 * 2. Create a DocuSign Developer Account: https://developers.docusign.com/
 * 3. Create an Integration Key (Client ID) in DocuSign Admin
 * 4. Generate RSA Key Pair for JWT authentication
 * 5. Add credentials to .env file
 */

const fetch = require('node-fetch');
const crypto = require('crypto');

// DocuSign Configuration
const DOCUSIGN_CONFIG = {
  integrationKey: process.env.DOCUSIGN_INTEGRATION_KEY || '',
  secretKey: process.env.DOCUSIGN_SECRET_KEY || '',
  accountId: process.env.DOCUSIGN_ACCOUNT_ID || '',
  userId: process.env.DOCUSIGN_USER_ID || '',
  baseUrl: process.env.DOCUSIGN_BASE_URL || 'https://demo.docusign.net/restapi',
  authServerUrl: process.env.DOCUSIGN_AUTH_SERVER || 'https://account-d.docusign.com',
  isProduction: process.env.DOCUSIGN_PRODUCTION === 'true',
};

// In-memory token cache (use Redis in production)
let accessToken = null;
let tokenExpiry = null;

/**
 * Get DocuSign access token using JWT authentication
 */
async function getAccessToken() {
  // Check if token is still valid
  if (accessToken && tokenExpiry && Date.now() < tokenExpiry) {
    return accessToken;
  }

  try {
    // Request access token using password grant (simpler for demo)
    // In production, use JWT grant with RSA keys
    const authUrl = `${DOCUSIGN_CONFIG.authServerUrl}/oauth/token`;
    
    const response = await fetch(authUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: DOCUSIGN_CONFIG.integrationKey,
        client_secret: DOCUSIGN_CONFIG.secretKey,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`DocuSign authentication failed: ${error}`);
    }

    const data = await response.json();
    accessToken = data.access_token;
    tokenExpiry = Date.now() + (data.expires_in * 1000) - 60000; // Refresh 1 min before expiry
    
    console.log('✅ DocuSign access token obtained');
    return accessToken;
  } catch (error) {
    console.error('❌ DocuSign authentication error:', error);
    throw error;
  }
}

/**
 * Create a DocuSign envelope for report signing
 */
async function createEnvelope({
  reportId,
  signerEmail,
  signerName,
  reportTitle,
  reportContent,
  documentName = 'Sign-Off Report',
}) {
  try {
    const token = await getAccessToken();
    const apiUrl = `${DOCUSIGN_CONFIG.baseUrl}/v2.1/accounts/${DOCUSIGN_CONFIG.accountId}/envelopes`;

    // Create HTML document for signing
    const documentContent = createReportDocument(reportTitle, reportContent);
    const base64Doc = Buffer.from(documentContent).toString('base64');

    // Envelope definition
    const envelopeDefinition = {
      emailSubject: `Please sign: ${reportTitle}`,
      documents: [
        {
          documentBase64: base64Doc,
          name: documentName,
          fileExtension: 'html',
          documentId: '1',
        },
      ],
      recipients: {
        signers: [
          {
            email: signerEmail,
            name: signerName,
            recipientId: '1',
            routingOrder: '1',
            tabs: {
              signHereTabs: [
                {
                  anchorString: '/sig1/',
                  anchorUnits: 'pixels',
                  anchorXOffset: '20',
                  anchorYOffset: '10',
                },
              ],
              dateSignedTabs: [
                {
                  anchorString: '/date/',
                  anchorUnits: 'pixels',
                  anchorXOffset: '20',
                  anchorYOffset: '10',
                },
              ],
            },
          },
        ],
      },
      status: 'sent', // Send immediately
    };

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(envelopeDefinition),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Failed to create envelope: ${error}`);
    }

    const result = await response.json();
    console.log('✅ DocuSign envelope created:', result.envelopeId);
    
    return {
      envelopeId: result.envelopeId,
      status: result.status,
      statusDateTime: result.statusDateTime,
    };
  } catch (error) {
    console.error('❌ Error creating DocuSign envelope:', error);
    throw error;
  }
}

/**
 * Get envelope status
 */
async function getEnvelopeStatus(envelopeId) {
  try {
    const token = await getAccessToken();
    const apiUrl = `${DOCUSIGN_CONFIG.baseUrl}/v2.1/accounts/${DOCUSIGN_CONFIG.accountId}/envelopes/${envelopeId}`;

    const response = await fetch(apiUrl, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error('Failed to get envelope status');
    }

    const data = await response.json();
    return {
      envelopeId: data.envelopeId,
      status: data.status,
      sentDateTime: data.sentDateTime,
      deliveredDateTime: data.deliveredDateTime,
      signedDateTime: data.signedDateTime,
      completedDateTime: data.completedDateTime,
      declinedReason: data.voidedReason,
    };
  } catch (error) {
    console.error('Error getting envelope status:', error);
    throw error;
  }
}

/**
 * Get signed document from envelope
 */
async function getSignedDocument(envelopeId, documentId = '1') {
  try {
    const token = await getAccessToken();
    const apiUrl = `${DOCUSIGN_CONFIG.baseUrl}/v2.1/accounts/${DOCUSIGN_CONFIG.accountId}/envelopes/${envelopeId}/documents/${documentId}`;

    const response = await fetch(apiUrl, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error('Failed to get signed document');
    }

    return await response.buffer();
  } catch (error) {
    console.error('Error getting signed document:', error);
    throw error;
  }
}

/**
 * Void (cancel) an envelope
 */
async function voidEnvelope(envelopeId, reason) {
  try {
    const token = await getAccessToken();
    const apiUrl = `${DOCUSIGN_CONFIG.baseUrl}/v2.1/accounts/${DOCUSIGN_CONFIG.accountId}/envelopes/${envelopeId}`;

    const response = await fetch(apiUrl, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        status: 'voided',
        voidedReason: reason,
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to void envelope');
    }

    return await response.json();
  } catch (error) {
    console.error('Error voiding envelope:', error);
    throw error;
  }
}

/**
 * Resend envelope notification
 */
async function resendEnvelope(envelopeId) {
  try {
    const token = await getAccessToken();
    const apiUrl = `${DOCUSIGN_CONFIG.baseUrl}/v2.1/accounts/${DOCUSIGN_CONFIG.accountId}/envelopes/${envelopeId}/views/recipient`;

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        resendEnvelope: true,
      }),
    });

    return response.ok;
  } catch (error) {
    console.error('Error resending envelope:', error);
    return false;
  }
}

/**
 * Create HTML document for the report
 */
function createReportDocument(title, content) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 40px auto;
      padding: 20px;
      line-height: 1.6;
    }
    h1 {
      color: #333;
      border-bottom: 2px solid #4A90E2;
      padding-bottom: 10px;
    }
    .content {
      margin: 20px 0;
      white-space: pre-wrap;
    }
    .signature-section {
      margin-top: 60px;
      border-top: 2px solid #ccc;
      padding-top: 20px;
    }
    .signature-line {
      margin: 30px 0;
      padding: 20px;
      border: 2px dashed #ccc;
      background-color: #f9f9f9;
    }
  </style>
</head>
<body>
  <h1>${title}</h1>
  
  <div class="content">
${content}
  </div>
  
  <div class="signature-section">
    <h2>Signature</h2>
    <p>By signing below, you acknowledge that you have reviewed and approve this report.</p>
    
    <div class="signature-line">
      <p><strong>Signature:</strong> /sig1/</p>
      <p><strong>Date:</strong> /date/</p>
    </div>
  </div>
</body>
</html>
  `;
}

/**
 * Verify DocuSign webhook signature
 */
function verifyWebhookSignature(body, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(body);
  const calculatedSignature = hmac.digest('base64');
  return calculatedSignature === signature;
}

/**
 * Check if DocuSign is configured
 */
function isConfigured() {
  return !!(
    DOCUSIGN_CONFIG.integrationKey &&
    DOCUSIGN_CONFIG.secretKey &&
    DOCUSIGN_CONFIG.accountId &&
    DOCUSIGN_CONFIG.userId
  );
}

module.exports = {
  createEnvelope,
  getEnvelopeStatus,
  getSignedDocument,
  voidEnvelope,
  resendEnvelope,
  verifyWebhookSignature,
  isConfigured,
  DOCUSIGN_CONFIG,
};

