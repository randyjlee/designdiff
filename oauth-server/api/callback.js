// Figma OAuth - 콜백 처리
// Vercel Serverless Function

export default async function handler(req, res) {
  const { code, error } = req.query;
  
  if (error) {
    return res.status(400).send(errorPage(error));
  }
  
  if (!code) {
    return res.status(400).send(errorPage('No authorization code received'));
  }
  
  try {
    const clientId = process.env.FIGMA_CLIENT_ID;
    const clientSecret = process.env.FIGMA_CLIENT_SECRET;
    const redirectUri = process.env.REDIRECT_URI || `https://${req.headers.host}/api/callback`;
    
    // Debug log
    console.log('OAuth Debug:', {
      clientId: clientId ? clientId.substring(0, 5) + '...' : 'MISSING',
      clientSecretLength: clientSecret ? clientSecret.length : 0,
      redirectUri,
      code: code ? code.substring(0, 10) + '...' : 'MISSING'
    });
    
    // Exchange code for token
    const tokenResponse = await fetch('https://www.figma.com/api/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        code: code,
        grant_type: 'authorization_code',
      }),
    });
    
    const tokenData = await tokenResponse.json();
    
    console.log('Token response status:', tokenResponse.status);
    console.log('Token response:', JSON.stringify(tokenData));
    
    if (!tokenResponse.ok) {
      const errorMsg = tokenData.message || tokenData.error_description || tokenData.error || 'Failed to exchange code for token';
      throw new Error(errorMsg);
    }
    
    // Return success page with token
    res.status(200).send(successPage(tokenData.access_token));
    
  } catch (err) {
    console.error('OAuth error:', err);
    res.status(500).send(errorPage(`${err.message} | Client ID: ${process.env.FIGMA_CLIENT_ID ? 'SET' : 'MISSING'} | Secret: ${process.env.FIGMA_CLIENT_SECRET ? process.env.FIGMA_CLIENT_SECRET.length + ' chars' : 'MISSING'}`));
  }
}

function successPage(token) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Design Diff - Connected!</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap');
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    body {
      font-family: 'JetBrains Mono', monospace;
      background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    
    .card {
      background: #21262d;
      border: 1px solid #30363d;
      border-radius: 16px;
      padding: 40px;
      max-width: 500px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.5);
    }
    
    .icon {
      width: 80px;
      height: 80px;
      background: linear-gradient(135deg, #3fb950, #58a6ff);
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      font-size: 40px;
    }
    
    h1 {
      color: #e6edf3;
      font-size: 24px;
      margin-bottom: 12px;
    }
    
    p {
      color: #8b949e;
      font-size: 14px;
      margin-bottom: 24px;
      line-height: 1.6;
    }
    
    .token-box {
      background: #0d1117;
      border: 1px solid #30363d;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 20px;
      position: relative;
    }
    
    .token-label {
      color: #8b949e;
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 8px;
    }
    
    .token-value {
      color: #58a6ff;
      font-size: 12px;
      word-break: break-all;
      user-select: all;
      line-height: 1.5;
    }
    
    .btn {
      background: #238636;
      color: #fff;
      border: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-family: inherit;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: background 0.2s;
    }
    
    .btn:hover {
      background: #2ea043;
    }
    
    .btn:active {
      transform: scale(0.98);
    }
    
    .copied {
      background: #3fb950 !important;
    }
    
    .instructions {
      margin-top: 24px;
      padding-top: 24px;
      border-top: 1px solid #30363d;
      text-align: left;
    }
    
    .instructions h3 {
      color: #e6edf3;
      font-size: 14px;
      margin-bottom: 12px;
    }
    
    .instructions ol {
      color: #8b949e;
      font-size: 13px;
      padding-left: 20px;
      line-height: 1.8;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✓</div>
    <h1>Connected to Figma!</h1>
    <p>Copy this token and paste it in the Design Diff plugin</p>
    
    <div class="token-box">
      <div class="token-label">Access Token</div>
      <div class="token-value" id="token">${token}</div>
    </div>
    
    <button class="btn" id="copyBtn" onclick="copyToken()">
      📋 Copy Token
    </button>
    
    <div class="instructions">
      <h3>Next Steps:</h3>
      <ol>
        <li>Click "Copy Token" above</li>
        <li>Go back to Figma</li>
        <li>Paste the token in the Design Diff plugin</li>
        <li>Start comparing versions!</li>
      </ol>
    </div>
  </div>
  
  <script>
    function copyToken() {
      const token = document.getElementById('token').textContent;
      navigator.clipboard.writeText(token).then(() => {
        const btn = document.getElementById('copyBtn');
        btn.textContent = '✓ Copied!';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = '📋 Copy Token';
          btn.classList.remove('copied');
        }, 2000);
      });
    }
  </script>
</body>
</html>
  `;
}

function errorPage(error) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Design Diff - Error</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap');
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    body {
      font-family: 'JetBrains Mono', monospace;
      background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    
    .card {
      background: #21262d;
      border: 1px solid #f85149;
      border-radius: 16px;
      padding: 40px;
      max-width: 400px;
      width: 100%;
      text-align: center;
    }
    
    .icon {
      width: 80px;
      height: 80px;
      background: rgba(248, 81, 73, 0.2);
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      font-size: 40px;
    }
    
    h1 {
      color: #f85149;
      font-size: 24px;
      margin-bottom: 12px;
    }
    
    p {
      color: #8b949e;
      font-size: 14px;
      line-height: 1.6;
    }
    
    .error-detail {
      background: #0d1117;
      border-radius: 8px;
      padding: 12px;
      margin-top: 16px;
      color: #f85149;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✕</div>
    <h1>Connection Failed</h1>
    <p>Something went wrong while connecting to Figma.</p>
    <div class="error-detail">${error}</div>
  </div>
</body>
</html>
  `;
}

