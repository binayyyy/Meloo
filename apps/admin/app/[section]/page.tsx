import { notFound } from 'next/navigation';
import { AdminConsole, type AdminSection } from '../admin-console';

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
  const { section } = await params;
  if (!VALID_SECTIONS.includes(section as AdminSection)) {
    notFound();
  }

  return <AdminConsole activeSection={section as AdminSection} />;
}
