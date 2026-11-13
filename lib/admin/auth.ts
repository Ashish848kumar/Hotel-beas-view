import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '../supabase/server';

export type StaffRole = 'OWNER' | 'FRONT_DESK' | 'HOUSEKEEPING';
export async function requireRole(allowed: StaffRole[]) {
  const supabase = createSupabaseServerClient();
  if (!supabase) redirect('/admin/login?setup=1');
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/admin/login');
  const { data: profile } = await supabase.from('profiles').select('role, active, full_name').eq('id', user.id).single();
  if (!profile || !profile.active || !allowed.includes(profile.role)) redirect('/admin/forbidden');
  return { supabase, user, profile };
}
