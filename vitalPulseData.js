import { supabase } from '@/lib/supabase';

// All rows are scoped to the authenticated user. Enable the matching RLS policies
// from the SQL migration before using these helpers in production.
async function requireUserId() {
  const { data, error } = await supabase.auth.getUser();
  if (error) throw error;
  if (!data.user) throw new Error('Please sign in first.');
  return data.user.id;
}

export async function getLatestHealthProfile() {
  const user_id = await requireUserId();
  const { data, error } = await supabase
    .from('health_profiles')
    .select('*')
    .eq('user_id', user_id)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function saveHealthProfile(profile) {
  const user_id = await requireUserId();
  const payload = {
    user_id,
    height_cm: profile.height_cm ?? null,
    weight_kg: profile.weight_kg ?? null,
    age: profile.age ?? null,
    gender: profile.gender ?? null,
    resting_hr: profile.resting_hr ?? null,
    activity_level: profile.activity_level ?? 'moderate',
    health_conditions: profile.health_conditions ?? [],
    cycle_phase: profile.cycle_phase ?? null,
    pregnancy_status: profile.pregnancy_status ?? null,
    waist_cm: profile.waist_cm ?? null,
    hip_cm: profile.hip_cm ?? null,
    updated_at: new Date().toISOString(),
  };
  if (profile.id) {
    const { data, error } = await supabase.from('health_profiles').update(payload)
      .eq('id', profile.id).select().single();
    if (error) throw error;
    return data;
  }
  const { data, error } = await supabase.from('health_profiles').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function listActivitySessions(limit = 50) {
  const user_id = await requireUserId();
  const { data, error } = await supabase.from('activity_sessions').select('*')
    .eq('user_id', user_id).order('session_date', { ascending: false }).limit(limit);
  if (error) throw error;
  return data ?? [];
}

export async function createActivitySession(session) {
  const user_id = await requireUserId();
  const { data, error } = await supabase.from('activity_sessions').insert({
    user_id,
    steps: session.steps ?? 0,
    duration_seconds: session.duration_seconds ?? 0,
    calories_burned: session.calories_burned ?? 0,
    avg_heart_rate: session.avg_heart_rate ?? null,
    max_heart_rate: session.max_heart_rate ?? null,
    bmi_at_time: session.bmi_at_time ?? null,
    session_date: session.session_date ?? new Date().toISOString().slice(0, 10),
    device_type: session.device_type ?? 'phone',
  }).select().single();
  if (error) throw error;
  return data;
}

export async function hasCompletedPayment() {
  const user_id = await requireUserId();
  const { data, error } = await supabase.from('payments').select('id')
    .eq('user_id', user_id).eq('status', 'completed').limit(1);
  if (error) throw error;
  return (data?.length ?? 0) > 0;
}

// Do not let the client create its own completed payment record. A trusted
// Stripe webhook / Edge Function must update payment status after verification.
