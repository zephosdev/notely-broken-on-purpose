// Generates a local JWT secret plus anon and service_role JWTs (HS256), Supabase legacy-key style.
import crypto from 'node:crypto';
import fs from 'node:fs';
const secret = crypto.randomBytes(32).toString('hex');
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const sign = (payload) => {
  const h = b64({ alg: 'HS256', typ: 'JWT' }); const p = b64(payload);
  const s = crypto.createHmac('sha256', secret).update(`${h}.${p}`).digest('base64url');
  return `${h}.${p}.${s}`;
};
const iat = 1756684800, exp = 2072217600;
const keys = {
  JWT_SECRET: secret,
  ANON_KEY: sign({ iss: 'supabase-local', role: 'anon', iat, exp }),
  SERVICE_ROLE_KEY: sign({ iss: 'supabase-local', role: 'service_role', iat, exp }),
  USER_A_JWT: sign({ iss: 'supabase-local', role: 'authenticated', sub: '11111111-1111-1111-1111-111111111111', iat, exp }),
  USER_B_JWT: sign({ iss: 'supabase-local', role: 'authenticated', sub: '22222222-2222-2222-2222-222222222222', iat, exp }),
};
fs.writeFileSync(new URL('./keys.env', import.meta.url), Object.entries(keys).map(([k, v]) => `${k}=${v}`).join('\n') + '\n');
console.log('wrote keys.env');
