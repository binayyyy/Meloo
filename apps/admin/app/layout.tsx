import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Meloo platforms',
  description: 'Internal operations console for the Meloo event network.',
  icons: {
    icon: '/branding/meloo-mark-v1.png',
    shortcut: '/branding/meloo-mark-v1.png',
    apple: '/branding/meloo-mark-v1.png',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
