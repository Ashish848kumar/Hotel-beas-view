import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '../../../lib/supabase/server';
export async function POST(){const client=createSupabaseServerClient();if(client)await client.auth.signOut();return NextResponse.json({ok:true});}
