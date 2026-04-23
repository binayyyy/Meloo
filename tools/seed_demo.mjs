import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:3000/api';
const outputDir = path.resolve(process.cwd(), '.tooling/demo');

const userDefinitions = {
  admin: {
    email: 'admin@meloo.local',
    password: 'Password123!',
    role: 'admin',
    profile: {
      fullName: 'Amina Admin',
      phone: '+15551000001',
      bio: 'Platform operations lead for moderation, verification, and support.',
    },
  },
  organizer: {
    email: 'organizer@meloo.local',
    password: 'Password123!',
    role: 'organizer',
    profile: {
      fullName: 'Owen Organizer',
      phone: '+15552000002',
      bio: 'Organizer focused on technology events and sponsor growth in San Francisco.',
    },
  },
  vendor: {
    email: 'vendor@meloo.local',
    password: 'Password123!',
    role: 'vendor',
    profile: {
      fullName: 'Vera Vendor',
      phone: '+15553000003',
      bio: 'Event production partner for AV, stage support, and venue operations.',
    },
  },
  sponsor: {
    email: 'sponsor@meloo.local',
    password: 'Password123!',
    role: 'sponsor',
    profile: {
      fullName: 'Sam Sponsor',
      phone: '+15554000004',
      bio: 'Brand partnerships lead looking for technology and business audiences.',
    },
  },
  attendee: {
    email: 'attendee@meloo.local',
    password: 'Password123!',
    role: 'attendee',
    profile: {
      fullName: 'Avery Attendee',
      phone: '+15555000005',
      bio: 'Attendee interested in technology, community, and business networking in San Francisco.',
    },
  },
};

const demoNames = {
  vendorBusinessName: 'Northwind Event Works',
  sponsorCompanyName: 'Luma Growth Partners',
  eventTitle: 'Smart City Expo 2026',
  opportunityTitle: 'Headline Innovation Sponsor',
  supportSubject: 'Checkout readiness follow-up',
};

async function main() {
  await mkdir(outputDir, { recursive: true });
  await waitForApi();

  const sessions = {};
  for (const [role, definition] of Object.entries(userDefinitions)) {
    sessions[role] = await authenticateUser(definition);
    await updateMe(sessions[role], definition.profile);
    sessions[role].user = await requestJson('/users/me', {
      token: sessions[role].tokens.accessToken,
    });
  }

  const categories = await requestJson('/event-categories');
  const technologyCategory =
    categories.find((item) => item.slug === 'technology') ?? categories[0];

  let organizerEvents = await requestJson('/events/my', {
    token: sessions.organizer.tokens.accessToken,
  });
  let event =
    organizerEvents.find((item) => item.title === demoNames.eventTitle) ?? null;

  if (event == null) {
    event = await requestJson('/events', {
      method: 'POST',
      token: sessions.organizer.tokens.accessToken,
      body: {
        title: demoNames.eventTitle,
        description:
          'A live showcase for event technology, vendor coordination, sponsor programs, and attendee experience design.',
        categoryId: technologyCategory.id,
        venue: 'Pier 48 Conference Hall',
        city: 'San Francisco',
        latitude: 37.7749,
        longitude: -122.4194,
        vendorMatchRadiusKm: 70,
        startAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 18).toISOString(),
        endAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 18 + 1000 * 60 * 60 * 8).toISOString(),
        status: 'published',
        visibility: 'public',
      },
    });
    organizerEvents = await requestJson('/events/my', {
      token: sessions.organizer.tokens.accessToken,
    });
  }

  let ticketTypes = await requestJson(`/events/${event.id}/ticket-types/manage`, {
    token: sessions.organizer.tokens.accessToken,
  });

  if (!ticketTypes.some((item) => item.name === 'Community Pass')) {
    await requestJson(`/events/${event.id}/ticket-types`, {
      method: 'POST',
      token: sessions.organizer.tokens.accessToken,
      body: {
        name: 'Community Pass',
        price: '0.00',
        quantity: 200,
        saleStartAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
        saleEndAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 17).toISOString(),
      },
    });
  }

  if (!ticketTypes.some((item) => item.name === 'VIP Access')) {
    await requestJson(`/events/${event.id}/ticket-types`, {
      method: 'POST',
      token: sessions.organizer.tokens.accessToken,
      body: {
        name: 'VIP Access',
        price: '49.00',
        quantity: 60,
        saleStartAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
        saleEndAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 17).toISOString(),
      },
    });
  }

  ticketTypes = await requestJson(`/events/${event.id}/ticket-types/manage`, {
    token: sessions.organizer.tokens.accessToken,
  });
  const freeTicket = ticketTypes.find((item) => Number.parseFloat(item.price) === 0);
  const paidTicket = ticketTypes.find((item) => Number.parseFloat(item.price) > 0);

  let vendorProfile = await requestJson('/vendors/me/profile', {
    token: sessions.vendor.tokens.accessToken,
  });
  vendorProfile = await requestJson('/vendors/me/profile', {
    method: 'PATCH',
    token: sessions.vendor.tokens.accessToken,
    body: {
      businessName: demoNames.vendorBusinessName,
      description:
        'Full-service AV and on-site operations partner for conferences, showcases, and city-scale activations.',
      category: 'AV & production',
      serviceArea: 'San Francisco Bay Area',
      latitude: 37.7849,
      longitude: -122.4094,
      travelRadiusKm: 90,
    },
  });
  await requestJson('/vendors/me/booking-preference', {
    method: 'PATCH',
    token: sessions.vendor.tokens.accessToken,
    body: {
      allowDirectBooking: true,
      allowRequestBooking: true,
    },
  });

  if (!vendorProfile.services.some((item) => item.name === 'AV Control Desk')) {
    vendorProfile = await requestJson('/vendors/me/services', {
      method: 'POST',
      token: sessions.vendor.tokens.accessToken,
      body: {
        name: 'AV Control Desk',
        description: 'Audio mixing, display routing, and live session support.',
        basePrice: '1200.00',
        pricingModel: 'per event',
      },
    });
  }

  if (!vendorProfile.packages.some((item) => item.name === 'Launch Stage Package')) {
    vendorProfile = await requestJson('/vendors/me/packages', {
      method: 'POST',
      token: sessions.vendor.tokens.accessToken,
      body: {
        name: 'Launch Stage Package',
        description: 'Stage management, AV support, microphones, and transition staffing.',
        price: '2800.00',
      },
    });
  }

  let sponsorProfile = await requestJson('/sponsors/me/profile', {
    token: sessions.sponsor.tokens.accessToken,
  });
  sponsorProfile = await requestJson('/sponsors/me/profile', {
    method: 'PATCH',
    token: sessions.sponsor.tokens.accessToken,
    body: {
      companyName: demoNames.sponsorCompanyName,
      description:
        'Growth partner investing in technology communities, smart-city pilots, and business networking programs.',
      industries: 'technology, innovation, smart cities, SaaS',
    },
  });

  await verifyProfileIfNeeded(
    sessions.admin.tokens.accessToken,
    '/admin/vendors/pending',
    `/admin/vendors/${vendorProfile.id}/verify`,
    vendorProfile.id,
  );
  await verifyProfileIfNeeded(
    sessions.admin.tokens.accessToken,
    '/admin/sponsors/pending',
    `/admin/sponsors/${sponsorProfile.id}/verify`,
    sponsorProfile.id,
  );

  let opportunities = await requestJson('/sponsorship-opportunities/my', {
    token: sessions.organizer.tokens.accessToken,
  });
  let opportunity =
    opportunities.find((item) => item.title === demoNames.opportunityTitle) ?? null;

  if (opportunity == null) {
    opportunity = await requestJson(`/events/${event.id}/sponsorship-opportunities`, {
      method: 'POST',
      token: sessions.organizer.tokens.accessToken,
      body: {
        title: demoNames.opportunityTitle,
        description:
          'Lead the innovation zone, keynote visibility, and attendee activation across the expo floor.',
        requiredAmount: '5000.00',
        targetAudience: 'City-tech founders, operators, and ecosystem partners',
        benefitsOffered: 'Headline booth, keynote mention, lead capture, and premium signage',
        status: 'open',
      },
    });
    opportunities = await requestJson('/sponsorship-opportunities/my', {
      token: sessions.organizer.tokens.accessToken,
    });
  }

  const sponsorInterests = await requestJson('/sponsorship-interests/my', {
    token: sessions.sponsor.tokens.accessToken,
  });
  if (!sponsorInterests.some((item) => item.opportunity.id === opportunity.id)) {
    await requestJson(`/sponsorship-opportunities/${opportunity.id}/interests`, {
      method: 'POST',
      token: sessions.sponsor.tokens.accessToken,
      body: {
        message:
          'We want to support the innovation zone and connect with city-tech operators.',
      },
    });
  }

  const organizerVendorRequests = await requestJson('/vendors/requests/my-organizer', {
    token: sessions.organizer.tokens.accessToken,
  });
  let vendorRequest =
    organizerVendorRequests.find(
      (item) => item.event.id === event.id && item.vendor.id === vendorProfile.id,
    ) ?? null;

  if (vendorRequest == null) {
    vendorRequest = await requestJson(`/vendors/${vendorProfile.id}/requests`, {
      method: 'POST',
      token: sessions.organizer.tokens.accessToken,
      body: {
        eventId: event.id,
        message:
          'We need AV and stage operations support for the expo keynote block.',
        proposedBudget: '3200.00',
        directBookingPreferred: false,
      },
    });
  }

  if (vendorRequest.status === 'pending') {
    vendorRequest = await requestJson(`/vendors/requests/${vendorRequest.id}/respond`, {
      method: 'PATCH',
      token: sessions.vendor.tokens.accessToken,
      body: { status: 'accepted' },
    });
  }

  if (vendorRequest.status === 'accepted') {
    vendorRequest = await requestJson(`/vendors/requests/${vendorRequest.id}/book`, {
      method: 'PATCH',
      token: sessions.organizer.tokens.accessToken,
    });
  }

  await ensureConversation(
    sessions.organizer.tokens.accessToken,
    sessions.vendor.user.id,
    'Can you share your load-in timing for the keynote build?',
  );
  await ensureConversation(
    sessions.organizer.tokens.accessToken,
    sessions.sponsor.user.id,
    'We would like to walk through sponsor branding placements and lead capture.',
  );

  await requestJson(`/events/${event.id}/favorite`, {
    method: 'POST',
    token: sessions.attendee.tokens.accessToken,
  });
  await requestJson(`/events/${event.id}/view`, {
    method: 'POST',
    token: sessions.attendee.tokens.accessToken,
  });

  const attendeeRegistrations = await requestJson('/registrations/my', {
    token: sessions.attendee.tokens.accessToken,
  });
  if (freeTicket && !attendeeRegistrations.some((item) => item.ticketType.id === freeTicket.id)) {
    await requestJson(`/events/${event.id}/registrations`, {
      method: 'POST',
      token: sessions.attendee.tokens.accessToken,
      body: {
        ticketTypeId: freeTicket.id,
        quantity: 1,
      },
    });
  }

  const attendeePayments = await requestJson('/payments/my', {
    token: sessions.attendee.tokens.accessToken,
  });
  let initiatedStripeCheckout = null;
  if (paidTicket && attendeePayments.length === 0) {
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY ?? '';
    if (stripeSecretKey.length > 0) {
      initiatedStripeCheckout = await requestJson(
        `/events/${event.id}/payments/checkout-session`,
        {
          method: 'POST',
          token: sessions.attendee.tokens.accessToken,
          body: {
            ticketTypeId: paidTicket.id,
            quantity: 1,
            returnUrl:
              process.env.PAYMENT_RETURN_URL ?? 'http://127.0.0.1:8081',
          },
        },
      );
    }
  }

  const supportTickets = await requestJson('/support/tickets/my', {
    token: sessions.attendee.tokens.accessToken,
  });
  let supportTicket =
    supportTickets.find((item) => item.subject === demoNames.supportSubject) ?? null;
  if (supportTicket == null) {
    supportTicket = await requestJson('/support/tickets', {
      method: 'POST',
      token: sessions.attendee.tokens.accessToken,
      body: {
        category: 'payment',
        subject: demoNames.supportSubject,
        description:
          initiatedStripeCheckout == null
            ? 'Please confirm that paid checkout is configured correctly before the VIP flow goes live.'
            : 'Please confirm the VIP Stripe checkout session is configured correctly and ready for manual completion.',
      },
    });
  }

  if (supportTicket.status !== 'resolved') {
    await requestJson(`/admin/support/tickets/${supportTicket.id}/assign`, {
      method: 'PATCH',
      token: sessions.admin.tokens.accessToken,
    });
    await requestJson(`/admin/support/tickets/${supportTicket.id}/resolve`, {
      method: 'PATCH',
      token: sessions.admin.tokens.accessToken,
    });
  }

  for (const [role, session] of Object.entries(sessions)) {
    session.user = await requestJson('/users/me', {
      token: session.tokens.accessToken,
    });
    session.notifications = await requestJson('/notifications/my', {
      token: session.tokens.accessToken,
    });
  }

  const output = {
    generatedAt: new Date().toISOString(),
    apiBaseUrl,
    eventId: event.id,
    opportunityId: opportunity.id,
    vendorRequestId: vendorRequest.id,
    supportTicketId: supportTicket.id,
    initiatedStripeCheckout,
    roles: sessions,
  };

  await writeFile(
    path.join(outputDir, 'demo-data.json'),
    JSON.stringify(output, null, 2),
  );

  console.log(`Demo data written to ${path.join(outputDir, 'demo-data.json')}`);
}

async function authenticateUser(definition) {
  if (definition.role === 'admin') {
    return requestJson('/auth/bootstrap-local-admin', {
      method: 'POST',
      headers: {
        'x-setup-key':
          process.env.LOCAL_SETUP_KEY ?? 'change-this-local-setup-key',
      },
      body: {
        email: definition.email,
        password: definition.password,
        fullName: definition.profile.fullName,
      },
    });
  }

  try {
    return await requestJson('/auth/signup', {
      method: 'POST',
      body: {
        email: definition.email,
        password: definition.password,
        role: definition.role,
      },
    });
  } catch (error) {
    if (error.status !== 409) {
      throw error;
    }
    return requestJson('/auth/login', {
      method: 'POST',
      body: {
        email: definition.email,
        password: definition.password,
      },
    });
  }
}

async function updateMe(session, profile) {
  await requestJson('/users/me', {
    method: 'PATCH',
    token: session.tokens.accessToken,
    body: {
      profile,
      settings: {
        notificationsEnabled: true,
        marketingEnabled: false,
        privacyLevel: 'community',
        aiAssistEnabled: true,
      },
    },
  });
}

async function verifyProfileIfNeeded(adminToken, listPath, verifyPath, profileId) {
  const pendingItems = await requestJson(listPath, { token: adminToken });
  if (pendingItems.some((item) => item.id === profileId)) {
    await requestJson(verifyPath, {
      method: 'PATCH',
      token: adminToken,
    });
  }
}

async function ensureConversation(accessToken, participantUserId, seedMessage) {
  const conversation = await requestJson('/chat/conversations/direct', {
    method: 'POST',
    token: accessToken,
    body: {
      participantUserId,
    },
  });

  const messages = await requestJson(
    `/chat/conversations/${conversation.id}/messages`,
    {
      token: accessToken,
    },
  );

  if (!messages.some((item) => item.body === seedMessage)) {
    await requestJson(`/chat/conversations/${conversation.id}/messages`, {
      method: 'POST',
      token: accessToken,
      body: { body: seedMessage },
    });
  }
}

async function requestJson(pathname, options = {}) {
  const response = await fetch(`${apiBaseUrl}${pathname}`, {
    method: options.method ?? 'GET',
    headers: {
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers ?? {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  const data = text.length > 0 ? JSON.parse(text) : null;

  if (!response.ok) {
    const error = new Error(
      data?.message instanceof Array
        ? data.message.join(', ')
        : data?.message ?? `Request failed for ${pathname}`,
    );
    error.status = response.status;
    throw error;
  }

  return data;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function waitForApi() {
  const attempts = 30;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      await requestJson('/event-categories');
      return;
    } catch (error) {
      if (attempt === attempts) {
        throw error;
      }
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }
  }
}
