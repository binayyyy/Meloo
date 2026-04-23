'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

type EventCategory = {
  id: string;
  name: string;
  slug: string;
};

type EventItem = {
  id: string;
  title: string;
  city: string;
  venue: string;
  status: string;
  visibility: string;
  startAt: string;
  category: EventCategory;
};

type VendorItem = {
  id: string;
  businessName: string;
  category: string;
  serviceArea: string;
  portfolioImageUrl: string | null;
  verificationDocumentUrl: string | null;
  verified: boolean;
  services: Array<{ id: string }>;
  packages: Array<{ id: string }>;
};

type SponsorItem = {
  id: string;
  userId: string;
  companyName: string;
  description: string;
  industries: string;
  logoUrl: string | null;
  websiteUrl: string | null;
  verificationDocumentUrl: string | null;
  verified: boolean;
};

type SponsorshipOpportunity = {
  id: string;
  title: string;
  status: string;
  requiredAmount: string;
  targetAudience: string;
  event: {
    id: string;
    title: string;
    city: string;
    venue: string;
    startAt: string;
  };
};

type SupportTicket = {
  id: string;
  category: string;
  subject: string;
  description: string;
  status: string;
  priority: string;
  requester: {
    userId: string;
    email: string;
    role: string;
    fullName: string | null;
  };
  assignedAdminId: string | null;
  assistantSuggestion: string | null;
  aiConfidence: string | null;
  escalation: {
    id: string;
    reason: string;
    status: string;
    aiConfidence: string;
  } | null;
  createdAt: string;
  updatedAt: string;
};

type EscalationItem = {
  id: string;
  sourceType: string;
  sourceId: string;
  reason: string;
  aiConfidence: string;
  status: string;
  assignedTo: string | null;
  createdAt: string;
  updatedAt: string;
};

type AdminOverview = {
  totalUserCount: number;
  activeUserCount: number;
  suspendedUserCount: number;
  activeSessionCount: number;
  totalEventCount: number;
  publishedEventCount: number;
  draftEventCount: number;
  cancelledEventCount: number;
  pendingVendorVerificationCount: number;
  pendingSponsorVerificationCount: number;
  openSupportTicketCount: number;
  openEscalationCount: number;
};

type AdminUser = {
  id: string;
  email: string;
  role: string;
  status: string;
  fullName: string | null;
  avatarUrl: string | null;
  phone: string | null;
  createdAt: string;
  updatedAt: string;
  activeSessionCount: number;
  lastSessionAt: string | null;
  vendorProfileId: string | null;
  sponsorProfileId: string | null;
  vendorVerified: boolean;
  sponsorVerified: boolean;
};

type AdminSystemHealth = {
  nodeEnv: string;
  apiPrefix: string;
  corsOrigin: string;
  uptimeSeconds: number;
  databaseConnected: boolean;
  memory: {
    rssMb: number;
    heapUsedMb: number;
    heapTotalMb: number;
  };
  ai: {
    configured: boolean;
    detail: string;
    enabled: boolean;
    provider: string;
    model: string;
    baseUrl: string;
  };
  payments: {
    configured: boolean;
    detail: string;
    currency: string;
    webhookConfigured: boolean;
  };
  totals: {
    users: number;
    activeSessions: number;
    publishedEvents: number;
    openSupportTickets: number;
    openEscalations: number;
  };
};

type AdminActivityItem = {
  id: string;
  type: string;
  title: string;
  detail: string;
  status: string | null;
  actorLabel: string | null;
  createdAt: string;
  resourceType: string;
  resourceId: string;
};

type UploadedAsset = {
  kind: 'image' | 'document';
  url: string;
  path: string;
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
};

type PublicDashboardState = {
  categories: EventCategory[];
  publicEvents: EventItem[];
  vendors: VendorItem[];
  opportunities: SponsorshipOpportunity[];
};

type AdminDashboardState = {
  overview: AdminOverview | null;
  pendingVendors: VendorItem[];
  pendingSponsors: SponsorItem[];
  moderationEvents: EventItem[];
  supportTickets: SupportTicket[];
  escalations: EscalationItem[];
  users: AdminUser[];
  systemHealth: AdminSystemHealth | null;
  activity: AdminActivityItem[];
};

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/api';
const TOKEN_STORAGE_KEY = 'melo-admin-token';

const NAV_ITEMS = [
  { id: 'overview', label: 'Overview' },
  { id: 'users', label: 'Users' },
  { id: 'verification', label: 'Verification' },
  { id: 'support', label: 'Support' },
  { id: 'moderation', label: 'Moderation' },
  { id: 'system', label: 'System' },
  { id: 'activity', label: 'Logs' },
];

export type AdminSection = (typeof NAV_ITEMS)[number]['id'];

export function AdminConsole({
  activeSection = 'overview',
}: {
  activeSection?: AdminSection;
}) {
  const [publicState, setPublicState] = useState<PublicDashboardState>({
    categories: [],
    publicEvents: [],
    vendors: [],
    opportunities: [],
  });
  const [adminState, setAdminState] = useState<AdminDashboardState>({
    overview: null,
    pendingVendors: [],
    pendingSponsors: [],
    moderationEvents: [],
    supportTickets: [],
    escalations: [],
    users: [],
    systemHealth: null,
    activity: [],
  });
  const [isPublicLoading, setIsPublicLoading] = useState(true);
  const [isAdminLoading, setIsAdminLoading] = useState(false);
  const [publicError, setPublicError] = useState<string | null>(null);
  const [adminError, setAdminError] = useState<string | null>(null);
  const [adminEmailInput, setAdminEmailInput] = useState(
    'admin@meloo.local',
  );
  const [adminPasswordInput, setAdminPasswordInput] = useState('Password123!');
  const [adminTokenInput, setAdminTokenInput] = useState('');
  const [adminToken, setAdminToken] = useState('');
  const [isMutating, setIsMutating] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategorySlug, setNewCategorySlug] = useState('');
  const [assetKind, setAssetKind] = useState<'image' | 'document'>('image');
  const [assetFile, setAssetFile] = useState<File | null>(null);
  const [isUploadingAsset, setIsUploadingAsset] = useState(false);
  const [uploadedAsset, setUploadedAsset] = useState<UploadedAsset | null>(null);

  useEffect(() => {
    const storedToken = window.localStorage.getItem(TOKEN_STORAGE_KEY) ?? '';
    setAdminToken(storedToken);
    setAdminTokenInput(storedToken);
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadPublic() {
      setIsPublicLoading(true);
      setPublicError(null);

      try {
        const state = await loadPublicState();
        if (!cancelled) {
          setPublicState(state);
        }
      } catch (error) {
        if (!cancelled) {
          setPublicError(
            error instanceof Error ? error.message : 'Failed to load public data.',
          );
        }
      } finally {
        if (!cancelled) {
          setIsPublicLoading(false);
        }
      }
    }

    loadPublic();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadAdmin() {
      if (!adminToken) {
        setAdminState({
          overview: null,
          pendingVendors: [],
          pendingSponsors: [],
          moderationEvents: [],
          supportTickets: [],
          escalations: [],
          users: [],
          systemHealth: null,
          activity: [],
        });
        setAdminError(null);
        return;
      }

      setIsAdminLoading(true);
      setAdminError(null);

      try {
        const state = await loadAdminState(adminToken);
        if (!cancelled) {
          setAdminState(state);
        }
      } catch (error) {
        if (!cancelled) {
          setAdminError(
            error instanceof Error ? error.message : 'Failed to load admin data.',
          );
        }
      } finally {
        if (!cancelled) {
          setIsAdminLoading(false);
        }
      }
    }

    loadAdmin();
    return () => {
      cancelled = true;
    };
  }, [adminToken]);

  async function refreshPublicState() {
    setPublicState(await loadPublicState());
  }

  async function refreshAdminState() {
    if (!adminToken) {
      return;
    }
    setAdminState(await loadAdminState(adminToken));
  }

  async function runAdminMutation(callback: () => Promise<void>) {
    setIsMutating(true);
    setAdminError(null);
    try {
      await callback();
      await Promise.all([refreshAdminState(), refreshPublicState()]);
    } catch (error) {
      setAdminError(
        error instanceof Error ? error.message : 'Admin action failed.',
      );
    } finally {
      setIsMutating(false);
    }
  }

  function saveToken() {
    const nextToken = adminTokenInput.trim();
    window.localStorage.setItem(TOKEN_STORAGE_KEY, nextToken);
    setAdminToken(nextToken);
  }

  function clearToken() {
    window.localStorage.removeItem(TOKEN_STORAGE_KEY);
    setAdminToken('');
    setAdminTokenInput('');
  }

  async function loginAdmin() {
    if (!adminEmailInput.trim() || !adminPasswordInput) {
      setAdminError('Admin email and password are required.');
      return;
    }

    setIsMutating(true);
    setAdminError(null);
    try {
      const response = await postPublicJson<{
        user: { role: string };
        tokens: { accessToken: string };
      }>('/auth/login', {
        email: adminEmailInput.trim(),
        password: adminPasswordInput,
      });

      if (response.user.role !== 'admin') {
        throw new Error('This account is not an admin account.');
      }

      window.localStorage.setItem(
        TOKEN_STORAGE_KEY,
        response.tokens.accessToken,
      );
      setAdminToken(response.tokens.accessToken);
      setAdminTokenInput(response.tokens.accessToken);
    } catch (error) {
      setAdminError(
        error instanceof Error ? error.message : 'Admin login failed.',
      );
    } finally {
      setIsMutating(false);
    }
  }

  async function uploadAsset() {
    if (!adminToken) {
      setAdminError('Add an admin token before uploading assets.');
      return;
    }

    if (!assetFile) {
      setAdminError('Choose a file before uploading.');
      return;
    }

    setIsUploadingAsset(true);
    setAdminError(null);
    try {
      const uploaded = await postAdminUpload(
        assetKind === 'image' ? '/uploads/images' : '/uploads/documents',
        adminToken,
        assetFile,
      );
      setUploadedAsset(uploaded);
    } catch (error) {
      setAdminError(
        error instanceof Error ? error.message : 'Asset upload failed.',
      );
    } finally {
      setIsUploadingAsset(false);
    }
  }

  async function copyUploadedAssetUrl() {
    if (!uploadedAsset) {
      return;
    }

    await navigator.clipboard.writeText(uploadedAsset.url);
  }

  async function createCategory() {
    if (!adminToken) {
      setAdminError('Add an admin token before creating categories.');
      return;
    }
    if (!newCategoryName.trim() || !newCategorySlug.trim()) {
      setAdminError('Category name and slug are required.');
      return;
    }

    setIsMutating(true);
    setAdminError(null);
    try {
      await postAdminJson('/admin/event-categories', adminToken, {
        name: newCategoryName.trim(),
        slug: newCategorySlug.trim(),
      });
      await refreshPublicState();
      setNewCategoryName('');
      setNewCategorySlug('');
    } catch (error) {
      setAdminError(
        error instanceof Error ? error.message : 'Category creation failed.',
      );
    } finally {
      setIsMutating(false);
    }
  }

  const overviewCards = useMemo(() => {
    if (!adminState.overview) {
      return [];
    }
    return [
      {
        label: 'Users',
        value: adminState.overview.totalUserCount,
        meta: `${adminState.overview.activeUserCount} active`,
      },
      {
        label: 'Sessions',
        value: adminState.overview.activeSessionCount,
        meta: 'Live refresh sessions',
      },
      {
        label: 'Events',
        value: adminState.overview.totalEventCount,
        meta: `${adminState.overview.publishedEventCount} published`,
      },
      {
        label: 'Support',
        value: adminState.overview.openSupportTicketCount,
        meta: `${adminState.overview.openEscalationCount} escalations`,
      },
    ];
  }, [adminState.overview]);

  const publicSnapshot = useMemo(
    () => [
      {
        label: 'Public events',
        value: publicState.publicEvents.length,
      },
      {
        label: 'Verified vendors',
        value: publicState.vendors.filter((vendor) => vendor.verified).length,
      },
      {
        label: 'Sponsor opportunities',
        value: publicState.opportunities.length,
      },
      {
        label: 'Categories',
        value: publicState.categories.length,
      },
    ],
    [publicState],
  );

  const currentNavItem =
    NAV_ITEMS.find((item) => item.id === activeSection) ?? NAV_ITEMS[0];

  function isSectionVisible(section: AdminSection) {
    return activeSection === section;
  }

  return (
    <main className="admin-shell">
      <aside className="admin-sidebar">
        <div className="sidebar-brand">
          <BrandLockup />
          <p className="sidebar-copy">
            Internal operations, trust, users, support, moderation, and platform health.
          </p>
        </div>

        <nav className="sidebar-nav">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.id}
              href={item.id === 'overview' ? '/' : `/${item.id}`}
              className={`nav-item ${activeSection === item.id ? 'is-active' : ''}`}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <section className="sidebar-panel">
          <PanelHeader
            eyebrow="Access"
            title="Admin session"
            detail="Use a real internal admin login, or paste a bearer token if you already have one."
          />
          <div className="panel-stack">
            <input
              className="field-input"
              type="email"
              value={adminEmailInput}
              placeholder="admin@meloo.local"
              onChange={(event) => setAdminEmailInput(event.target.value)}
            />
            <input
              className="field-input"
              type="password"
              value={adminPasswordInput}
              placeholder="Admin password"
              onChange={(event) => setAdminPasswordInput(event.target.value)}
            />
            <div className="button-row">
              <button className="button button-primary" onClick={loginAdmin}>
                {isMutating ? 'Working...' : 'Admin login'}
              </button>
            </div>
            <div className="field-divider" />
            <input
              className="field-input"
              type="password"
              value={adminTokenInput}
              placeholder="Paste Meloo admin bearer token"
              onChange={(event) => setAdminTokenInput(event.target.value)}
            />
            <div className="button-row">
              <button className="button button-primary" onClick={saveToken}>
                Save token
              </button>
              <button className="button button-secondary" onClick={clearToken}>
                Clear
              </button>
            </div>
          </div>
        </section>

        <section className="sidebar-panel">
          <PanelHeader
            eyebrow="Asset studio"
            title="Real file uploads"
            detail="Upload live images and documents, then reuse the returned URLs in profiles, events, and verification flows."
          />
          {!adminToken ? (
            <EmptyState text="Add an admin token to upload assets." />
          ) : (
            <div className="panel-stack">
              <label className="field-label" htmlFor="asset-kind">
                Upload lane
              </label>
              <select
                id="asset-kind"
                className="field-input"
                value={assetKind}
                onChange={(event) =>
                  setAssetKind(event.target.value as 'image' | 'document')
                }
              >
                <option value="image">Image</option>
                <option value="document">Document</option>
              </select>
              <input
                className="field-input field-input-file"
                type="file"
                accept={
                  assetKind === 'image'
                    ? 'image/*'
                    : '.pdf,.doc,.docx,.txt,image/*'
                }
                onChange={(event) =>
                  setAssetFile(event.target.files?.[0] ?? null)
                }
              />
              <button
                className="button button-primary"
                onClick={uploadAsset}
                disabled={isUploadingAsset || assetFile == null}
              >
                {isUploadingAsset ? 'Uploading...' : 'Upload asset'}
              </button>
              {uploadedAsset ? (
                <div className="asset-preview">
                  {uploadedAsset.kind === 'image' ? (
                    <img
                      src={uploadedAsset.url}
                      alt={uploadedAsset.originalName}
                      className="asset-preview-image"
                    />
                  ) : null}
                  <div className="asset-preview-copy">
                    <strong>{uploadedAsset.originalName}</strong>
                    <span>
                      {uploadedAsset.mimeType} • {formatFileSize(uploadedAsset.size)}
                    </span>
                    <code>{uploadedAsset.url}</code>
                  </div>
                  <div className="button-row">
                    <button
                      className="button button-secondary"
                      onClick={copyUploadedAssetUrl}
                    >
                      Copy URL
                    </button>
                    <a
                      className="button button-secondary"
                      href={uploadedAsset.url}
                      target="_blank"
                      rel="noreferrer"
                    >
                      Open asset
                    </a>
                  </div>
                </div>
              ) : null}
            </div>
          )}
        </section>

        <section className="sidebar-panel">
          <PanelHeader
            eyebrow="Marketplace"
            title="Live snapshot"
            detail="Public supply visible right now."
          />
          <div className="mini-stat-stack">
            {publicSnapshot.map((item) => (
              <div key={item.label} className="mini-stat">
                <span>{item.label}</span>
                <strong>{item.value}</strong>
              </div>
            ))}
          </div>
        </section>

        <section className="sidebar-panel">
          <PanelHeader
            eyebrow="Taxonomy"
            title="Category desk"
            detail="Control event classification from one place."
          />
          {!adminToken ? (
            <EmptyState text="Add an admin token to create categories." />
          ) : (
            <div className="panel-stack">
              <input
                className="field-input"
                type="text"
                value={newCategoryName}
                placeholder="Category name"
                onChange={(event) => setNewCategoryName(event.target.value)}
              />
              <input
                className="field-input"
                type="text"
                value={newCategorySlug}
                placeholder="category-slug"
                onChange={(event) => setNewCategorySlug(event.target.value)}
              />
              <button className="button button-primary" onClick={createCategory}>
                {isMutating ? 'Working...' : 'Create category'}
              </button>
              <div className="compact-list">
                {publicState.categories.map((category) => (
                  <div key={category.id} className="list-row">
                    <span>{category.name}</span>
                    <code>{category.slug}</code>
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>
      </aside>

      <section className="admin-content">
        <header className="topbar">
          <div>
            <p className="eyebrow">Meloo platforms / {currentNavItem.label}</p>
            <h1>{currentNavItem.label}</h1>
            <p className="topbar-copy">
              A premium operations layer for marketplace trust, support, moderation, asset flow, and live platform readiness.
            </p>
          </div>
          <div className="topbar-actions">
            <span className={`status-dot ${adminToken ? 'online' : 'offline'}`}>
              {adminToken ? 'Admin unlocked' : 'Read-only snapshot'}
            </span>
            <span className="status-chip">API {API_BASE_URL}</span>
          </div>
        </header>

        {(publicError || adminError) && (
          <section className="alert-banner">
            <strong>Attention</strong>
            <span>{publicError ?? adminError}</span>
          </section>
        )}

        {isSectionVisible('overview') ? (
        <section id="overview" className="content-section">
          <SectionHeader
            eyebrow="Overview"
            title="Executive operating view"
            detail="High-signal counts across users, sessions, events, support, and live marketplace supply."
          />
          <div className="overview-grid">
            {overviewCards.length === 0 ? (
              <LockedPanel text="Add an admin token to load internal metrics." />
            ) : (
              overviewCards.map((card) => (
                <article key={card.label} className="metric-card">
                  <p className="metric-label">{card.label}</p>
                  <p className="metric-value">{card.value}</p>
                  <p className="metric-meta">{card.meta}</p>
                </article>
              ))
            )}
          </div>

          <div className="split-grid">
            <Panel
              eyebrow="Release state"
              title="Event release mix"
              detail="Live moderation and publication footprint."
            >
              {adminState.overview ? (
                <div className="mini-stat-stack">
                  <div className="mini-stat">
                    <span>Published</span>
                    <strong>{adminState.overview.publishedEventCount}</strong>
                  </div>
                  <div className="mini-stat">
                    <span>Draft</span>
                    <strong>{adminState.overview.draftEventCount}</strong>
                  </div>
                  <div className="mini-stat">
                    <span>Cancelled</span>
                    <strong>{adminState.overview.cancelledEventCount}</strong>
                  </div>
                </div>
              ) : (
                <EmptyState text="No internal release data loaded." />
              )}
            </Panel>

            <Panel
              eyebrow="Public surface"
              title="Marketplace snapshot"
              detail="What users can see without admin credentials."
            >
              {isPublicLoading ? (
                <EmptyState text="Loading public marketplace data..." />
              ) : (
                <div className="compact-list">
                  {publicState.publicEvents.slice(0, 4).map((event) => (
                    <div key={event.id} className="list-row multi-line">
                      <div>
                        <strong>{event.title}</strong>
                        <span>
                          {event.venue}, {event.city}
                        </span>
                      </div>
                      <span className={`table-badge ${statusToneClass(event.status)}`}>
                        {event.status}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </Panel>
          </div>
        </section>
        ) : null}

        {isSectionVisible('users') ? (
        <section id="users" className="content-section">
          <SectionHeader
            eyebrow="Users"
            title="User directory and account controls"
            detail="Activate, suspend, deactivate, revoke sessions, and inspect profile trust state."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to manage users and sessions." />
          ) : (
            <Panel
              eyebrow="Accounts"
              title="User directory"
              detail="All public and internal users, with live session and trust state."
            >
              <DataTable
                headers={[
                  'User',
                  'Role',
                  'Status',
                  'Sessions',
                  'Trust',
                  'Updated',
                  'Actions',
                ]}
              >
                {adminState.users.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div className="table-user">
                        <strong>{user.fullName || user.email}</strong>
                        <span>{user.email}</span>
                      </div>
                    </td>
                    <td>{user.role}</td>
                    <td>
                      <span className={`table-badge ${statusToneClass(user.status)}`}>
                        {user.status}
                      </span>
                    </td>
                    <td>
                      <div className="table-user">
                        <strong>{user.activeSessionCount}</strong>
                        <span>
                          {user.lastSessionAt
                            ? `Last ${formatDateTime(user.lastSessionAt)}`
                            : 'No recent session'}
                        </span>
                      </div>
                    </td>
                    <td>
                      <div className="table-user">
                        <strong>
                          {user.vendorVerified
                            ? 'Vendor verified'
                            : user.sponsorVerified
                              ? 'Sponsor verified'
                              : 'Unverified'}
                        </strong>
                        <span>
                          {user.vendorProfileId ? 'Vendor profile' : ''}
                          {user.vendorProfileId && user.sponsorProfileId ? ' • ' : ''}
                          {user.sponsorProfileId ? 'Sponsor profile' : ''}
                          {!user.vendorProfileId && !user.sponsorProfileId ? 'No trust profile' : ''}
                        </span>
                      </div>
                    </td>
                    <td>{formatDateTime(user.updatedAt)}</td>
                    <td>
                      <div className="table-actions">
                        {user.status === 'suspended' ? (
                          <button
                            className="button button-primary"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/users/${user.id}/status`,
                                  adminToken,
                                  { status: 'active' },
                                ),
                              )
                            }
                          >
                            Remove suspension
                          </button>
                        ) : user.status === 'deactivated' ? (
                          <button
                            className="button button-primary"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/users/${user.id}/status`,
                                  adminToken,
                                  { status: 'active' },
                                ),
                              )
                            }
                          >
                            Reactivate
                          </button>
                        ) : (
                          <button
                            className="button button-secondary"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/users/${user.id}/status`,
                                  adminToken,
                                  { status: 'suspended' },
                                ),
                              )
                            }
                          >
                            Suspend
                          </button>
                        )}
                        {user.status !== 'deactivated' ? (
                          <button
                            className="button button-danger"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/users/${user.id}/status`,
                                  adminToken,
                                  { status: 'deactivated' },
                                ),
                              )
                            }
                          >
                            Deactivate
                          </button>
                        ) : null}
                        <button
                          className="button button-secondary"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(
                                `/admin/users/${user.id}/revoke-sessions`,
                                adminToken,
                              ),
                            )
                          }
                        >
                          Revoke sessions
                        </button>
                        {user.vendorProfileId && user.vendorVerified ? (
                          <button
                            className="button button-danger"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/vendors/${user.vendorProfileId}/unverify`,
                                  adminToken,
                                ),
                              )
                            }
                          >
                            Remove vendor trust
                          </button>
                        ) : null}
                        {user.sponsorProfileId && user.sponsorVerified ? (
                          <button
                            className="button button-danger"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/sponsors/${user.sponsorProfileId}/unverify`,
                                  adminToken,
                                ),
                              )
                            }
                          >
                            Remove sponsor trust
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </DataTable>
            </Panel>
          )}
        </section>
        ) : null}

        {isSectionVisible('verification') ? (
        <section id="verification" className="content-section">
          <SectionHeader
            eyebrow="Verification"
            title="Trust and profile review"
            detail="Approve or reject vendor and sponsor trust signals from one queue."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to review vendor and sponsor trust queues." />
          ) : (
            <div className="split-grid">
              <Panel
                eyebrow="Vendors"
                title="Pending vendor verification"
                detail="Profiles waiting for the Meloo verified mark."
              >
                {adminState.pendingVendors.length === 0 ? (
                  <EmptyState text="No pending vendor profiles." />
                ) : (
                  <div className="queue-list">
                    {adminState.pendingVendors.map((vendor) => (
                      <article key={vendor.id} className="queue-card">
                        <div>
                          {vendor.portfolioImageUrl ? (
                            <img
                              className="queue-card-image"
                              src={vendor.portfolioImageUrl}
                              alt={vendor.businessName}
                            />
                          ) : null}
                          <strong>{vendor.businessName}</strong>
                          <span>{vendor.category}</span>
                          <p>
                            {vendor.serviceArea} • {vendor.services.length} services •{' '}
                            {vendor.packages.length} packages
                          </p>
                          <div className="queue-card-links">
                            {vendor.portfolioImageUrl ? (
                              <a
                                href={vendor.portfolioImageUrl}
                                target="_blank"
                                rel="noreferrer"
                              >
                                View portfolio image
                              </a>
                            ) : null}
                            {vendor.verificationDocumentUrl ? (
                              <a
                                href={vendor.verificationDocumentUrl}
                                target="_blank"
                                rel="noreferrer"
                              >
                                View verification file
                              </a>
                            ) : null}
                          </div>
                        </div>
                        <button
                          className="button button-primary"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(`/admin/vendors/${vendor.id}/verify`, adminToken),
                            )
                          }
                        >
                          Verify
                        </button>
                      </article>
                    ))}
                  </div>
                )}
              </Panel>

              <Panel
                eyebrow="Sponsors"
                title="Pending sponsor verification"
                detail="Company profiles waiting for approval."
              >
                {adminState.pendingSponsors.length === 0 ? (
                  <EmptyState text="No pending sponsor profiles." />
                ) : (
                  <div className="queue-list">
                    {adminState.pendingSponsors.map((sponsor) => (
                      <article key={sponsor.id} className="queue-card">
                        <div>
                          {sponsor.logoUrl ? (
                            <img
                              className="queue-card-image"
                              src={sponsor.logoUrl}
                              alt={sponsor.companyName}
                            />
                          ) : null}
                          <strong>{sponsor.companyName}</strong>
                          <span>{sponsor.industries}</span>
                          <p>{sponsor.description}</p>
                          <div className="queue-card-links">
                            {sponsor.websiteUrl ? (
                              <a
                                href={sponsor.websiteUrl}
                                target="_blank"
                                rel="noreferrer"
                              >
                                Visit website
                              </a>
                            ) : null}
                            {sponsor.logoUrl ? (
                              <a
                                href={sponsor.logoUrl}
                                target="_blank"
                                rel="noreferrer"
                              >
                                View logo
                              </a>
                            ) : null}
                            {sponsor.verificationDocumentUrl ? (
                              <a
                                href={sponsor.verificationDocumentUrl}
                                target="_blank"
                                rel="noreferrer"
                              >
                                View verification file
                              </a>
                            ) : null}
                          </div>
                        </div>
                        <button
                          className="button button-primary"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(`/admin/sponsors/${sponsor.id}/verify`, adminToken),
                            )
                          }
                        >
                          Verify
                        </button>
                      </article>
                    ))}
                  </div>
                )}
              </Panel>
            </div>
          )}
        </section>
        ) : null}

        {isSectionVisible('support') ? (
        <section id="support" className="content-section">
          <SectionHeader
            eyebrow="Support"
            title="Tickets and escalations"
            detail="Run the service desk, assign tickets, resolve cases, and inspect AI escalations."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to manage support and escalations." />
          ) : (
            <div className="split-grid">
              <Panel
                eyebrow="Tickets"
                title="Support queue"
                detail="Organizer, attendee, and platform support traffic."
              >
                <DataTable
                  headers={['Subject', 'Requester', 'Priority', 'Status', 'AI', 'Actions']}
                >
                  {adminState.supportTickets.map((ticket) => (
                    <tr key={ticket.id}>
                      <td>
                        <div className="table-user">
                          <strong>{ticket.subject}</strong>
                          <span>{ticket.category}</span>
                        </div>
                      </td>
                      <td>
                        <div className="table-user">
                          <strong>{ticket.requester.fullName || ticket.requester.email}</strong>
                          <span>{ticket.requester.role}</span>
                        </div>
                      </td>
                      <td>{ticket.priority}</td>
                      <td>
                        <span className={`table-badge ${statusToneClass(ticket.status)}`}>
                          {ticket.status}
                        </span>
                      </td>
                      <td>
                        {ticket.aiConfidence
                          ? `${ticket.aiConfidence}${ticket.escalation ? ' • escalated' : ''}`
                          : 'No AI'}
                      </td>
                      <td>
                        <div className="table-actions">
                          <button
                            className="button button-secondary"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/support/tickets/${ticket.id}/assign`,
                                  adminToken,
                                ),
                              )
                            }
                          >
                            Assign
                          </button>
                          <button
                            className="button button-primary"
                            onClick={() =>
                              runAdminMutation(() =>
                                patchAdminJson(
                                  `/admin/support/tickets/${ticket.id}/resolve`,
                                  adminToken,
                                ),
                              )
                            }
                          >
                            Resolve
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </DataTable>
              </Panel>

              <Panel
                eyebrow="Escalations"
                title="AI escalation log"
                detail="Low-confidence or high-risk cases that need human review."
              >
                {adminState.escalations.length === 0 ? (
                  <EmptyState text="No escalations found." />
                ) : (
                  <div className="queue-list">
                    {adminState.escalations.map((item) => (
                      <article key={item.id} className="queue-card">
                        <div>
                          <strong>{item.sourceType.replaceAll('_', ' ')}</strong>
                          <span>{formatDateTime(item.updatedAt)}</span>
                          <p>{item.reason}</p>
                        </div>
                        <span className={`table-badge ${statusToneClass(item.status)}`}>
                          {item.status}
                        </span>
                      </article>
                    ))}
                  </div>
                )}
              </Panel>
            </div>
          )}
        </section>
        ) : null}

        {isSectionVisible('moderation') ? (
        <section id="moderation" className="content-section">
          <SectionHeader
            eyebrow="Moderation"
            title="Event release control"
            detail="Publish, draft, cancel, and inspect marketplace release state."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to moderate events." />
          ) : (
            <Panel
              eyebrow="Events"
              title="Moderation board"
              detail="All events sorted by most recent update."
            >
              <DataTable
                headers={['Event', 'Category', 'Visibility', 'Status', 'Start', 'Actions']}
              >
                {adminState.moderationEvents.map((event) => (
                  <tr key={event.id}>
                    <td>
                      <div className="table-user">
                        <strong>{event.title}</strong>
                        <span>
                          {event.venue}, {event.city}
                        </span>
                      </div>
                    </td>
                    <td>{event.category.name}</td>
                    <td>{event.visibility}</td>
                    <td>
                      <span className={`table-badge ${statusToneClass(event.status)}`}>
                        {event.status}
                      </span>
                    </td>
                    <td>{formatDate(event.startAt)}</td>
                    <td>
                      <div className="table-actions">
                        <button
                          className="button button-primary"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                                status: 'published',
                                visibility: 'public',
                              }),
                            )
                          }
                        >
                          Publish
                        </button>
                        <button
                          className="button button-secondary"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                                status: 'draft',
                              }),
                            )
                          }
                        >
                          Draft
                        </button>
                        <button
                          className="button button-danger"
                          onClick={() =>
                            runAdminMutation(() =>
                              patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                                status: 'cancelled',
                              }),
                            )
                          }
                        >
                          Cancel
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </DataTable>
            </Panel>
          )}
        </section>
        ) : null}

        {isSectionVisible('system') ? (
        <section id="system" className="content-section">
          <SectionHeader
            eyebrow="System"
            title="Runtime and service health"
            detail="Live infrastructure and configuration state from the running API."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to inspect system health." />
          ) : (
            <div className="split-grid">
              <Panel
                eyebrow="Runtime"
                title="Platform health"
                detail="Environment, uptime, memory, and totals."
              >
                {adminState.systemHealth ? (
                  <div className="system-grid">
                    <SystemCard
                      label="Environment"
                      value={adminState.systemHealth.nodeEnv}
                      meta={`API prefix ${adminState.systemHealth.apiPrefix}`}
                    />
                    <SystemCard
                      label="Database"
                      value={
                        adminState.systemHealth.databaseConnected ? 'Connected' : 'Offline'
                      }
                      meta={`CORS ${adminState.systemHealth.corsOrigin}`}
                    />
                    <SystemCard
                      label="Uptime"
                      value={formatDuration(adminState.systemHealth.uptimeSeconds)}
                      meta={`Heap ${adminState.systemHealth.memory.heapUsedMb} MB`}
                    />
                    <SystemCard
                      label="RSS"
                      value={`${adminState.systemHealth.memory.rssMb} MB`}
                      meta={`Heap total ${adminState.systemHealth.memory.heapTotalMb} MB`}
                    />
                  </div>
                ) : (
                  <EmptyState text="No system data loaded." />
                )}
              </Panel>

              <Panel
                eyebrow="Readiness"
                title="Service integrations"
                detail="Current readiness of AI and payments rails."
              >
                {adminState.systemHealth ? (
                  <div className="queue-list">
                    <article className="queue-card">
                      <div>
                        <strong>Local AI</strong>
                        <span>
                          {adminState.systemHealth.ai.provider} • {adminState.systemHealth.ai.model}
                        </span>
                        <p>{adminState.systemHealth.ai.detail}</p>
                      </div>
                      <span
                        className={`table-badge ${
                          adminState.systemHealth.ai.configured ? 'positive' : 'danger'
                        }`}
                      >
                        {adminState.systemHealth.ai.configured ? 'Ready' : 'Blocked'}
                      </span>
                    </article>
                    <article className="queue-card">
                      <div>
                        <strong>Stripe</strong>
                        <span>{adminState.systemHealth.payments.currency.toUpperCase()}</span>
                        <p>{adminState.systemHealth.payments.detail}</p>
                      </div>
                      <span
                        className={`table-badge ${
                          adminState.systemHealth.payments.configured
                            ? 'positive'
                            : 'danger'
                        }`}
                      >
                        {adminState.systemHealth.payments.configured ? 'Ready' : 'Blocked'}
                      </span>
                    </article>
                  </div>
                ) : (
                  <EmptyState text="No readiness data loaded." />
                )}
              </Panel>
            </div>
          )}
        </section>
        ) : null}

        {isSectionVisible('activity') ? (
        <section id="activity" className="content-section">
          <SectionHeader
            eyebrow="Logs"
            title="Activity stream"
            detail="Recent user, session, event, support, and escalation activity from live records."
          />
          {!adminToken ? (
            <LockedPanel text="Add an admin token to inspect the activity stream." />
          ) : (
            <Panel
              eyebrow="Activity"
              title="Latest platform events"
              detail="Sorted by most recent activity time."
            >
              {adminState.activity.length === 0 ? (
                <EmptyState text="No activity records found." />
              ) : (
                <div className="activity-list">
                  {adminState.activity.map((item) => (
                    <article key={item.id} className="activity-row">
                      <div className="activity-meta">
                        <span className="activity-type">{item.type}</span>
                        <span>{formatDateTime(item.createdAt)}</span>
                      </div>
                      <div className="activity-main">
                        <strong>{item.title}</strong>
                        <p>{item.detail}</p>
                      </div>
                      <div className="activity-side">
                        {item.actorLabel ? <span>{item.actorLabel}</span> : null}
                        {item.status ? (
                          <span className={`table-badge ${statusToneClass(item.status)}`}>
                            {item.status}
                          </span>
                        ) : null}
                      </div>
                    </article>
                  ))}
                </div>
              )}
            </Panel>
          )}
        </section>
        ) : null}
      </section>
    </main>
  );
}

export default function HomePage() {
  return <AdminConsole activeSection="overview" />;
}

async function loadPublicState(): Promise<PublicDashboardState> {
  const [categories, publicEvents, vendors, opportunities] = await Promise.all([
    fetchJson<EventCategory[]>('/event-categories'),
    fetchJson<EventItem[]>('/events'),
    fetchJson<VendorItem[]>('/vendors'),
    fetchJson<SponsorshipOpportunity[]>('/sponsorship-opportunities'),
  ]);

  return {
    categories,
    publicEvents,
    vendors,
    opportunities,
  };
}

async function loadAdminState(token: string): Promise<AdminDashboardState> {
  const [
    overview,
    pendingVendors,
    pendingSponsors,
    moderationEvents,
    supportTickets,
    escalations,
    users,
    systemHealth,
    activity,
  ] = await Promise.all([
    fetchAdminJson<AdminOverview>('/admin/overview', token),
    fetchAdminJson<VendorItem[]>('/admin/vendors/pending', token),
    fetchAdminJson<SponsorItem[]>('/admin/sponsors/pending', token),
    fetchAdminJson<EventItem[]>('/admin/events', token),
    fetchAdminJson<SupportTicket[]>('/admin/support/tickets', token),
    fetchAdminJson<EscalationItem[]>('/admin/support/escalations', token),
    fetchAdminJson<AdminUser[]>('/admin/users', token),
    fetchAdminJson<AdminSystemHealth>('/admin/system/health', token),
    fetchAdminJson<AdminActivityItem[]>('/admin/activity', token),
  ]);

  return {
    overview,
    pendingVendors,
    pendingSponsors,
    moderationEvents,
    supportTickets,
    escalations,
    users,
    systemHealth,
    activity,
  };
}

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    cache: 'no-store',
  });
  if (!response.ok) {
    throw new Error(`Request failed for ${path} with ${response.status}`);
  }
  return (await response.json()) as T;
}

async function fetchAdminJson<T>(path: string, token: string): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    cache: 'no-store',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) {
    throw new Error(`Admin request failed for ${path} with ${response.status}`);
  }
  return (await response.json()) as T;
}

async function patchAdminJson(
  path: string,
  token: string,
  body?: Record<string, unknown>,
): Promise<void> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Admin action failed for ${path} with ${response.status}`);
  }
}

async function postAdminJson(
  path: string,
  token: string,
  body: Record<string, unknown>,
): Promise<void> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Admin action failed for ${path} with ${response.status}`);
  }
}

async function postPublicJson<T>(
  path: string,
  body: Record<string, unknown>,
): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const payload = (await response.json()) as
    | { message?: string | string[] }
    | T;

  if (!response.ok) {
    const message =
      typeof payload === 'object' &&
      payload != null &&
      'message' in payload &&
      payload.message != null
        ? Array.isArray(payload.message)
          ? payload.message.join(', ')
          : payload.message
        : `Request failed for ${path} with ${response.status}`;
    throw new Error(message);
  }

  return payload as T;
}

async function postAdminUpload(
  path: string,
  token: string,
  file: File,
): Promise<UploadedAsset> {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
    body: formData,
  });

  if (!response.ok) {
    throw new Error(`Upload failed for ${path} with ${response.status}`);
  }

  return (await response.json()) as UploadedAsset;
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat('en', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(value));
}

function formatDateTime(value: string): string {
  return new Intl.DateTimeFormat('en', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function formatDuration(totalSeconds: number): string {
  const days = Math.floor(totalSeconds / 86_400);
  const hours = Math.floor((totalSeconds % 86_400) / 3_600);
  const minutes = Math.floor((totalSeconds % 3_600) / 60);
  if (days > 0) {
    return `${days}d ${hours}h`;
  }
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function statusToneClass(status: string): string {
  const normalized = status.toLowerCase();
  if (
    normalized.includes('active') ||
    normalized.includes('published') ||
    normalized.includes('verified') ||
    normalized.includes('resolved') ||
    normalized.includes('connected') ||
    normalized.includes('ready')
  ) {
    return 'positive';
  }
  if (
    normalized.includes('suspend') ||
    normalized.includes('deactivate') ||
    normalized.includes('cancel') ||
    normalized.includes('blocked')
  ) {
    return 'danger';
  }
  if (
    normalized.includes('draft') ||
    normalized.includes('pending') ||
    normalized.includes('review') ||
    normalized.includes('progress')
  ) {
    return 'warning';
  }
  return 'neutral';
}

function BrandLockup() {
  return (
    <div className="brand-lockup">
      <div className="brand-logo-frame">
        <img className="brand-logo" src="/branding/meloo-logo-v1.png" alt="Meloo" />
      </div>
      <div>
        <p className="brand-title">Meloo platforms</p>
        <p className="brand-subtitle">Internal operations</p>
      </div>
    </div>
  );
}

function SectionHeader({
  eyebrow,
  title,
  detail,
}: {
  eyebrow: string;
  title: string;
  detail: string;
}) {
  return (
    <div className="section-header">
      <p className="eyebrow">{eyebrow}</p>
      <h2>{title}</h2>
      <p>{detail}</p>
    </div>
  );
}

function PanelHeader({
  eyebrow,
  title,
  detail,
}: {
  eyebrow: string;
  title: string;
  detail: string;
}) {
  return (
    <header className="panel-header">
      <p className="eyebrow">{eyebrow}</p>
      <h3>{title}</h3>
      <p>{detail}</p>
    </header>
  );
}

function Panel({
  eyebrow,
  title,
  detail,
  children,
}: {
  eyebrow: string;
  title: string;
  detail: string;
  children: React.ReactNode;
}) {
  return (
    <section className="content-panel">
      <PanelHeader eyebrow={eyebrow} title={title} detail={detail} />
      {children}
    </section>
  );
}

function DataTable({
  headers,
  children,
}: {
  headers: string[];
  children: React.ReactNode;
}) {
  return (
    <div className="table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            {headers.map((header) => (
              <th key={header}>{header}</th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}

function SystemCard({
  label,
  value,
  meta,
}: {
  label: string;
  value: string;
  meta: string;
}) {
  return (
    <article className="system-card">
      <p>{label}</p>
      <strong>{value}</strong>
      <span>{meta}</span>
    </article>
  );
}

function LockedPanel({ text }: { text: string }) {
  return <section className="locked-panel">{text}</section>;
}

function EmptyState({ text }: { text: string }) {
  return <p className="empty-state">{text}</p>;
}
