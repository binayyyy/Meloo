import { notFound } from 'next/navigation';
import { AdminConsole, type AdminSection } from '../admin-console';
import { requireAdminSession } from '../../lib/admin-session';

const VALID_SECTIONS: AdminSection[] = [
  'overview',
  'users',
  'verification',
  'support',
  'moderation',
  'system',
  'activity',
];

export default async function AdminSectionPage({
  params,
}: {
  params: Promise<{ section: string }>;
}) {
  const viewer = await requireAdminSession();
  const { section } = await params;
  if (!VALID_SECTIONS.includes(section as AdminSection)) {
    notFound();
  }

  return <AdminConsole activeSection={section as AdminSection} viewer={viewer} />;
}
