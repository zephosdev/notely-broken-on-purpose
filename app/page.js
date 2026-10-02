'use client';
import { useEffect, useState } from 'react';
import { sb } from '../lib/supabase';
import _ from 'lodash';
export default function Home() {
  const [people, setPeople] = useState([]);
  useEffect(() => { sb('profile_directory?select=full_name,plan').then((r) => setPeople(_.sortBy(r, 'full_name'))); }, []);
  return (<main><h1>Notely</h1><p>Notes for busy people.</p><ul>{people.map((p) => <li key={p.full_name}>{p.full_name} ({p.plan})</li>)}</ul></main>);
}
