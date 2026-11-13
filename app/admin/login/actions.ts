'use server';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '../../../lib/supabase/server';
export async function login(form:FormData){const client=createSupabaseServerClient();if(!client)redirect('/admin/login?setup=1');const email=String(form.get('email')||'');const password=String(form.get('password')||'');const {error}=await client.auth.signInWithPassword({email,password});if(error)redirect('/admin/login?error=1');redirect('/admin/dashboard');}
