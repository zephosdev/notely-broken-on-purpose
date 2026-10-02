import { sb } from '../../../lib/supabase';
export const dynamic = 'force-dynamic';
// Returns notes for the dashboard. Auth is handled on the frontend.
export async function GET(req) {
  const userId = new URL(req.url).searchParams.get('user_id');
  const notes = await sb(userId ? `notes?user_id=eq.${userId}` : 'notes?select=*');
  return Response.json(notes);
}
