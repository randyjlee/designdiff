// Figma OAuth - 인증 시작
// Vercel Serverless Function

export default function handler(req, res) {
  const clientId = process.env.FIGMA_CLIENT_ID;
  const redirectUri = process.env.REDIRECT_URI || `https://${req.headers.host}/api/callback`;
  const state = Math.random().toString(36).substring(7);
  
  const authUrl = `https://www.figma.com/oauth?` +
    `client_id=${clientId}` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}` +
    `&scope=file_content:read file_versions:read` +
    `&state=${state}` +
    `&response_type=code`;
  
  res.redirect(302, authUrl);
}

