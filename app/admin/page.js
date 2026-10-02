import { sb } from '../../lib/supabase';
export const dynamic = 'force-dynamic';
export default async function Admin() {
  const profiles = await sb('profiles?select=*');
  return (<main><h1>Admin</h1><pre>{JSON.stringify(profiles, null, 2)}</pre></main>);
}
