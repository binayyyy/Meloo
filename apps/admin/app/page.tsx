'use client';

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
  verified: boolean;
  services: Array<{ id: string }>;
  packages: Array<{ id: string }>;
};

type SponsorItem = {
  id: string;
  companyName: string;
  industries: string;
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
  assistantSuggestion: string | null;
  aiConfidence: string | null;
  escalation: {
    id: string;
    reason: string;
    status: string;
  } | null;
};

type AdminOverview = {
  publishedEventCount: number;
  pendingVendorVerificationCount: number;
  pendingSponsorVerificationCount: number;
  openSupportTicketCount: number;
  openEscalationCount: number;
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
};

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/api';
const TOKEN_STORAGE_KEY = 'smart-event-admin-token';

export default function HomePage() {
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
  });
  const [isPublicLoading, setIsPublicLoading] = useState(true);
  const [isAdminLoading, setIsAdminLoading] = useState(false);
  const [publicError, setPublicError] = useState<string | null>(null);
  const [adminError, setAdminError] = useState<string | null>(null);
  const [adminTokenInput, setAdminTokenInput] = useState('');
  const [adminToken, setAdminToken] = useState('');
  const [isMutating, setIsMutating] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategorySlug, setNewCategorySlug] = useState('');

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
        const [categories, publicEvents, vendors, opportunities] =
          await Promise.all([
            fetchJson<EventCategory[]>('/event-categories'),
            fetchJson<EventItem[]>('/events'),
            fetchJson<VendorItem[]>('/vendors'),
            fetchJson<SponsorshipOpportunity[]>('/sponsorship-opportunities'),
          ]);

        if (!cancelled) {
          setPublicState({
            categories,
            publicEvents,
            vendors,
            opportunities,
          });
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
        });
        setAdminError(null);
        return;
      }

      setIsAdminLoading(true);
      setAdminError(null);

      try {
        const [overview, pendingVendors, pendingSponsors, moderationEvents, supportTickets] =
          await Promise.all([
            fetchAdminJson<AdminOverview>('/admin/overview', adminToken),
            fetchAdminJson<VendorItem[]>('/admin/vendors/pending', adminToken),
            fetchAdminJson<SponsorItem[]>('/admin/sponsors/pending', adminToken),
            fetchAdminJson<EventItem[]>('/admin/events', adminToken),
            fetchAdminJson<SupportTicket[]>('/admin/support/tickets', adminToken),
          ]);

        if (!cancelled) {
          setAdminState({
            overview,
            pendingVendors,
            pendingSponsors,
            moderationEvents,
            supportTickets,
          });
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

  async function refreshAdminState() {
    if (!adminToken) {
      return;
    }
    const [overview, pendingVendors, pendingSponsors, moderationEvents, supportTickets] =
      await Promise.all([
        fetchAdminJson<AdminOverview>('/admin/overview', adminToken),
        fetchAdminJson<VendorItem[]>('/admin/vendors/pending', adminToken),
        fetchAdminJson<SponsorItem[]>('/admin/sponsors/pending', adminToken),
        fetchAdminJson<EventItem[]>('/admin/events', adminToken),
        fetchAdminJson<SupportTicket[]>('/admin/support/tickets', adminToken),
      ]);
    setAdminState({
      overview,
      pendingVendors,
      pendingSponsors,
      moderationEvents,
      supportTickets,
    });
  }

  async function runAdminMutation(callback: () => Promise<void>) {
    setIsMutating(true);
    setAdminError(null);
    try {
      await callback();
      await refreshAdminState();
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
      const categories = await fetchJson<EventCategory[]>('/event-categories');
      setPublicState((current) => ({
        ...current,
        categories,
      }));
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

  const publicSignals = useMemo(
    () => [
      {
        label: 'Live events',
        value: publicState.publicEvents.length,
        detail: 'Public inventory visible to mobile + web discovery.',
      },
      {
        label: 'Verified vendors',
        value: publicState.vendors.filter((vendor) => vendor.verified).length,
        detail: 'Profiles ready for organizer outreach and booking.',
      },
      {
        label: 'Sponsor asks',
        value: publicState.opportunities.length,
        detail: 'Open revenue conversations across live events.',
      },
      {
        label: 'Taxonomy',
        value: publicState.categories.length,
        detail: 'Discovery categories powering creation and search.',
      },
    ],
    [publicState],
  );

  const adminSignals = useMemo(() => {
    if (!adminState.overview) {
      return [];
    }
    return [
      {
        label: 'Vendor queue',
        value: adminState.overview.pendingVendorVerificationCount,
        detail: 'Profiles awaiting trust approval.',
      },
      {
        label: 'Sponsor queue',
        value: adminState.overview.pendingSponsorVerificationCount,
        detail: 'Brands waiting for verification.',
      },
      {
        label: 'Support load',
        value: adminState.overview.openSupportTicketCount,
        detail: 'Open cases requiring assignment or resolution.',
      },
      {
        label: 'Escalations',
        value: adminState.overview.openEscalationCount,
        detail: 'AI-low-confidence or higher-risk incidents.',
      },
    ];
  }, [adminState.overview]);

  const cityMomentum = useMemo(() => {
    const cityCounts = new Map<string, number>();
    for (const event of publicState.publicEvents) {
      cityCounts.set(event.city, (cityCounts.get(event.city) ?? 0) + 1);
    }
    return [...cityCounts.entries()]
      .sort((left, right) => right[1] - left[1])
      .slice(0, 4);
  }, [publicState.publicEvents]);

  return (
    <main className="ops-shell">
      <section className="ops-hero">
        <div>
          <p className="ops-kicker">Smart Event Hub control room</p>
          <h1>Run release operations without leaving the live system.</h1>
          <p className="ops-copy">
            This surface is built as a real operating desk, not a placeholder
            dashboard. Public discovery, verification lanes, moderation, support,
            taxonomy, Stripe-ready commerce, and AI-assisted risk context all
            converge here.
          </p>
          <div className="hero-chip-row">
            <span className="hero-chip">Live API: {API_BASE_URL}</span>
            <span className="hero-chip">Stripe-backed checkout</span>
            <span className="hero-chip">Local model assistance</span>
          </div>
        </div>
        <div className="hero-signal-stack">
          {publicSignals.slice(0, 2).map((signal) => (
            <SignalCard
              key={signal.label}
              label={signal.label}
              value={String(signal.value)}
              detail={signal.detail}
            />
          ))}
        </div>
      </section>

      {(publicError || adminError) && (
        <section className="inline-alert">
          <p className="ops-kicker">Attention</p>
          <p className="alert-copy">{publicError ?? adminError}</p>
        </section>
      )}

      <section className="signal-band">
        {publicSignals.map((signal) => (
          <SignalCard
            key={signal.label}
            label={signal.label}
            value={String(signal.value)}
            detail={signal.detail}
          />
        ))}
      </section>

      <div className="ops-layout">
        <aside className="ops-rail">
          <RailPanel title="Admin session" eyebrow="Access">
            <div className="stack">
              <input
                className="token-input"
                type="password"
                value={adminTokenInput}
                placeholder="Paste admin bearer token"
                onChange={(event) => setAdminTokenInput(event.target.value)}
              />
              <div className="button-row">
                <button className="action-button primary" onClick={saveToken}>
                  Save token
                </button>
                <button className="action-button ghost" onClick={clearToken}>
                  Clear
                </button>
              </div>
              <p className="support-copy">
                {adminToken
                  ? 'Admin actions are unlocked for this browser session.'
                  : 'Public monitoring is always visible. Verification and moderation unlock after auth.'}
              </p>
            </div>
          </RailPanel>

          <RailPanel title="City momentum" eyebrow="Market pulse">
            <div className="stack compact">
              {cityMomentum.length === 0 ? (
                <EmptyState text="No public event momentum yet." />
              ) : (
                cityMomentum.map(([city, count]) => (
                  <MiniRow
                    key={city}
                    title={city}
                    detail={`${count} published event${count === 1 ? '' : 's'}`}
                  />
                ))
              )}
            </div>
          </RailPanel>

          <RailPanel title="Category desk" eyebrow="Taxonomy">
            {!adminToken ? (
              <EmptyState text="Add an admin token to create categories." />
            ) : (
              <div className="stack">
                <input
                  className="token-input"
                  type="text"
                  value={newCategoryName}
                  placeholder="Category name"
                  onChange={(event) => setNewCategoryName(event.target.value)}
                />
                <input
                  className="token-input"
                  type="text"
                  value={newCategorySlug}
                  placeholder="category-slug"
                  onChange={(event) => setNewCategorySlug(event.target.value)}
                />
                <button className="action-button primary" onClick={createCategory}>
                  {isMutating ? 'Working...' : 'Create category'}
                </button>
                <div className="stack compact">
                  {publicState.categories.map((category) => (
                    <MiniRow
                      key={category.id}
                      title={category.name}
                      detail={category.slug}
                    />
                  ))}
                </div>
              </div>
            )}
          </RailPanel>

          <RailPanel title="Release scope" eyebrow="Status">
            <ul className="scope-list">
              <li>Auth, event discovery, vendors, sponsors, chat, support, AI, and notifications are live.</li>
              <li>Paid checkout is wired to Stripe instead of a mock provider.</li>
              <li>Mobile and admin surfaces now run against the same real backend.</li>
              <li>Remaining work is production credentials, infra, migrations, and release hardening.</li>
            </ul>
          </RailPanel>
        </aside>

        <section className="ops-main">
          {adminSignals.length > 0 && (
            <section className="signal-band admin-band">
              {adminSignals.map((signal) => (
                <SignalCard
                  key={signal.label}
                  label={signal.label}
                  value={String(signal.value)}
                  detail={signal.detail}
                  muted
                />
              ))}
            </section>
          )}

          <section className="board-grid">
            <LanePanel
              title="Live event board"
              eyebrow="Public supply"
              loading={isPublicLoading}
            >
              {publicState.publicEvents.length === 0 ? (
                <EmptyState text="No public events found." />
              ) : (
                publicState.publicEvents.slice(0, 6).map((event) => (
                  <DataCard
                    key={event.id}
                    title={event.title}
                    eyebrow={event.category.name}
                    status={event.status}
                    detail={`${event.venue}, ${event.city}`}
                    meta={`${formatDate(event.startAt)} • ${event.visibility}`}
                  />
                ))
              )}
            </LanePanel>

            <LanePanel
              title="Vendor review lane"
              eyebrow="Trust queue"
              loading={isAdminLoading}
            >
              {!adminToken ? (
                <EmptyState text="Authenticate to review pending vendors." />
              ) : adminState.pendingVendors.length === 0 ? (
                <EmptyState text="No pending vendor profiles." />
              ) : (
                adminState.pendingVendors.map((vendor) => (
                  <ActionCard
                    key={vendor.id}
                    title={vendor.businessName}
                    eyebrow={vendor.category}
                    status={vendor.verified ? 'verified' : 'pending'}
                    detail={vendor.serviceArea}
                    meta={`${vendor.services.length} services • ${vendor.packages.length} packages`}
                    actions={[
                      {
                        label: isMutating ? 'Working...' : 'Verify vendor',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/vendors/${vendor.id}/verify`, adminToken),
                          ),
                      },
                    ]}
                  />
                ))
              )}
            </LanePanel>

            <LanePanel
              title="Sponsor review lane"
              eyebrow="Brand approvals"
              loading={isAdminLoading}
            >
              {!adminToken ? (
                <EmptyState text="Authenticate to review pending sponsors." />
              ) : adminState.pendingSponsors.length === 0 ? (
                <EmptyState text="No pending sponsor profiles." />
              ) : (
                adminState.pendingSponsors.map((sponsor) => (
                  <ActionCard
                    key={sponsor.id}
                    title={sponsor.companyName}
                    eyebrow="Sponsor"
                    status={sponsor.verified ? 'verified' : 'pending'}
                    detail={sponsor.industries}
                    actions={[
                      {
                        label: isMutating ? 'Working...' : 'Verify sponsor',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/sponsors/${sponsor.id}/verify`, adminToken),
                          ),
                      },
                    ]}
                  />
                ))
              )}
            </LanePanel>

            <LanePanel
              title="Support queue"
              eyebrow="Interventions"
              loading={isAdminLoading}
            >
              {!adminToken ? (
                <EmptyState text="Authenticate to manage support." />
              ) : adminState.supportTickets.length === 0 ? (
                <EmptyState text="No support tickets found." />
              ) : (
                adminState.supportTickets.slice(0, 8).map((ticket) => (
                  <ActionCard
                    key={ticket.id}
                    title={ticket.subject}
                    eyebrow={`${ticket.category} • ${ticket.priority}`}
                    status={ticket.status}
                    detail={`${ticket.requester.email} • ${ticket.requester.role}`}
                    meta={ticket.escalation?.reason ?? ticket.assistantSuggestion ?? undefined}
                    actions={[
                      {
                        label: isMutating ? 'Working...' : 'Assign',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/support/tickets/${ticket.id}/assign`, adminToken),
                          ),
                      },
                      {
                        label: isMutating ? 'Working...' : 'Resolve',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/support/tickets/${ticket.id}/resolve`, adminToken),
                          ),
                      },
                    ]}
                  />
                ))
              )}
            </LanePanel>

            <LanePanel
              title="Event moderation"
              eyebrow="Policy + visibility"
              loading={isAdminLoading}
            >
              {!adminToken ? (
                <EmptyState text="Authenticate to moderate events." />
              ) : adminState.moderationEvents.length === 0 ? (
                <EmptyState text="No events available for moderation." />
              ) : (
                adminState.moderationEvents.slice(0, 8).map((event) => (
                  <ActionCard
                    key={event.id}
                    title={event.title}
                    eyebrow={event.category.name}
                    status={event.status}
                    detail={`${event.venue}, ${event.city}`}
                    meta={`${event.visibility} • ${formatDate(event.startAt)}`}
                    actions={[
                      {
                        label: isMutating ? 'Working...' : 'Publish',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                              status: 'published',
                              visibility: 'public',
                            }),
                          ),
                      },
                      {
                        label: isMutating ? 'Working...' : 'Draft',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                              status: 'draft',
                            }),
                          ),
                      },
                      {
                        label: isMutating ? 'Working...' : 'Cancel',
                        onClick: () =>
                          runAdminMutation(() =>
                            patchAdminJson(`/admin/events/${event.id}/moderate`, adminToken, {
                              status: 'cancelled',
                            }),
                          ),
                      },
                    ]}
                  />
                ))
              )}
            </LanePanel>

            <LanePanel
              title="Sponsorship market"
              eyebrow="Revenue flow"
              loading={isPublicLoading}
            >
              {publicState.opportunities.length === 0 ? (
                <EmptyState text="No sponsorship opportunities found." />
              ) : (
                publicState.opportunities.slice(0, 6).map((opportunity) => (
                  <DataCard
                    key={opportunity.id}
                    title={opportunity.title}
                    eyebrow={opportunity.event.title}
                    status={opportunity.status}
                    detail={`${opportunity.event.venue}, ${opportunity.event.city}`}
                    meta={`Target ${opportunity.requiredAmount} • ${opportunity.targetAudience}`}
                  />
                ))
              )}
            </LanePanel>
          </section>
        </section>
      </div>
    </main>
  );
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

function formatDate(value: string): string {
  return new Intl.DateTimeFormat('en', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(value));
}

function SignalCard({
  label,
  value,
  detail,
  muted = false,
}: {
  label: string;
  value: string;
  detail: string;
  muted?: boolean;
}) {
  return (
    <article className={`signal-card${muted ? ' muted' : ''}`}>
      <p className="signal-label">{label}</p>
      <p className="signal-value">{value}</p>
      <p className="signal-detail">{detail}</p>
    </article>
  );
}

function RailPanel({
  title,
  eyebrow,
  children,
}: {
  title: string;
  eyebrow: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rail-panel">
      <p className="ops-kicker">{eyebrow}</p>
      <h2>{title}</h2>
      <div className="stack">{children}</div>
    </section>
  );
}

function LanePanel({
  title,
  eyebrow,
  loading,
  children,
}: {
  title: string;
  eyebrow: string;
  loading: boolean;
  children: React.ReactNode;
}) {
  return (
    <section className="lane-panel">
      <div className="lane-header">
        <div>
          <p className="ops-kicker">{eyebrow}</p>
          <h2>{title}</h2>
        </div>
        {loading ? <span className="lane-badge">Refreshing</span> : null}
      </div>
      <div className="lane-stack">{children}</div>
    </section>
  );
}

function DataCard({
  title,
  eyebrow,
  status,
  detail,
  meta,
}: {
  title: string;
  eyebrow: string;
  status: string;
  detail: string;
  meta: string;
}) {
  return (
    <article className="data-card">
      <div className="card-head">
        <div>
          <p className="card-eyebrow">{eyebrow}</p>
          <h3>{title}</h3>
        </div>
        <span className="status-pill">{status}</span>
      </div>
      <p className="card-detail">{detail}</p>
      <p className="card-meta">{meta}</p>
    </article>
  );
}

function ActionCard({
  title,
  eyebrow,
  status,
  detail,
  meta,
  actions,
}: {
  title: string;
  eyebrow: string;
  status: string;
  detail: string;
  meta?: string;
  actions: Array<{ label: string; onClick: () => void }>;
}) {
  return (
    <article className="data-card action-card">
      <div className="card-head">
        <div>
          <p className="card-eyebrow">{eyebrow}</p>
          <h3>{title}</h3>
        </div>
        <span className="status-pill">{status}</span>
      </div>
      <p className="card-detail">{detail}</p>
      {meta ? <p className="card-meta">{meta}</p> : null}
      <div className="button-row">
        {actions.map((action) => (
          <button
            key={`${title}-${action.label}`}
            className="action-button primary"
            onClick={action.onClick}
          >
            {action.label}
          </button>
        ))}
      </div>
    </article>
  );
}

function MiniRow({ title, detail }: { title: string; detail: string }) {
  return (
    <article className="mini-row">
      <p className="mini-title">{title}</p>
      <p className="mini-detail">{detail}</p>
    </article>
  );
}

function EmptyState({ text }: { text: string }) {
  return <p className="empty-state">{text}</p>;
}
