import { sb } from '../../../../lib/supabase';
export const dynamic = 'force-dynamic';
export async function POST(req) {
  const event = await req.json(); // TODO verify signature
  if (event.type === 'checkout.session.completed') {
    const userId = event.data.object.client_reference_id;
    await sb(`profiles?id=eq.${userId}`, { method: 'PATCH', body: JSON.stringify({ plan: 'pro' }) });
  }
  return Response.json({ received: true });
}
