import Link from 'next/link';
import { requireRole } from '../../lib/admin/auth';
import { SignOutButton } from './sign-out-button';
import './admin.css';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const { profile } = await requireRole(['OWNER', 'FRONT_DESK', 'HOUSEKEEPING']);
  const links = [['Dashboard','/admin/dashboard'],['Rooms','/admin/rooms'],['Reservations','/admin/reservations'],['Guests','/admin/guests'],['Housekeeping','/admin/housekeeping'],['Staff','/admin/staff'],['Settings','/admin/settings']];
  return <div className="admin-shell"><aside className="admin-side"><Link href="/admin/dashboard" className="admin-brand">BEAS <span>VIEW</span><small>HOTEL MANAGEMENT</small></Link><nav>{links.filter(([label])=>label!=='Staff'&&label!=='Settings'||profile.role==='OWNER').map(([label,url])=><Link href={url} key={url}>{label}</Link>)}</nav><div className="admin-user"><span>{profile.full_name || 'Staff member'}</span><small>{profile.role.replace('_',' ')}</small><SignOutButton/></div></aside><main className="admin-main">{children}</main></div>;
}
