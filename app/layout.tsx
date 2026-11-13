import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Hotel Beas View | Jawalamukhi, Himachal Pradesh', description: 'Discover Hotel Beas View in Jawalamukhi, Himachal Pradesh. Explore rooms, local attractions and get in touch to plan your stay.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
