import { AdminConsole } from './admin-console';
import { requireAdminSession } from '../lib/admin-session';

export default async function HomePage() {
  const viewer = await requireAdminSession();
  return <AdminConsole activeSection="overview" viewer={viewer} />;
}
