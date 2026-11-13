'use client';
import { useRouter } from 'next/navigation';
export function SignOutButton(){const router=useRouter();return <button className="signout" onClick={async()=>{await fetch('/admin/logout',{method:'POST'});router.push('/admin/login');router.refresh();}}>Sign out</button>}
