import fs from 'node:fs/promises';
import path from 'node:path';

const width = 3000;
const height = 1920;
const outputPath = path.resolve('artifacts/meloo-erd-accurate.svg');

const colors = {
  bg: '#F6F1E8',
  panel: '#FFFBF5',
  text: '#16273D',
  muted: '#6B6E73',
  line: '#7F8DA0',
  navy: '#102844',
  teal: '#0FA6B8',
  gold: '#D39B3C',
  sand: '#F7EFDF',
  border: '#D8C7AF',
};

const domains = [
  { key: 'identity', label: 'IDENTITY', x: 900, y: 40, w: 1030, h: 560, color: colors.teal },
  { key: 'events', label: 'EVENTS', x: 1010, y: 620, w: 920, h: 620, color: colors.navy },
  { key: 'vendors', label: 'VENDORS', x: 2150, y: 620, w: 760, h: 760, color: colors.teal },
  { key: 'sponsors', label: 'SPONSORS', x: 120, y: 620, w: 760, h: 720, color: colors.gold },
  { key: 'payments', label: 'PAYMENTS', x: 120, y: 1390, w: 900, h: 390, color: colors.navy },
  { key: 'communication', label: 'COMMUNICATION', x: 1060, y: 1260, w: 980, h: 540, color: colors.teal },
  { key: 'support', label: 'SUPPORT', x: 2150, y: 1410, w: 760, h: 310, color: colors.gold },
];

const entities = [
  {
    id: 'users',
    title: 'USERS',
    domain: 'identity',
    x: 1320,
    y: 110,
    w: 270,
    fields: ['id (PK)', 'email', 'password_hash', 'role', 'status', 'created_at', 'updated_at'],
  },
  {
    id: 'sessions',
    title: 'SESSIONS',
    domain: 'identity',
    x: 950,
    y: 90,
    w: 250,
    fields: ['id (PK)', 'user_id (FK)', 'refresh_token_hash', 'device_info', 'created_at', 'expires_at'],
  },
  {
    id: 'email_tokens',
    title: 'EMAIL_VERIFICATION_TOKENS',
    domain: 'identity',
    x: 900,
    y: 320,
    w: 300,
    fields: ['id (PK)', 'user_id (FK)', 'token_hash', 'created_at', 'expires_at', 'consumed_at'],
  },
  {
    id: 'reset_tokens',
    title: 'PASSWORD_RESET_TOKENS',
    domain: 'identity',
    x: 900,
    y: 510,
    w: 300,
    fields: ['id (PK)', 'user_id (FK)', 'token_hash', 'created_at', 'expires_at', 'consumed_at'],
  },
  {
    id: 'user_profiles',
    title: 'USER_PROFILES',
    domain: 'identity',
    x: 1700,
    y: 90,
    w: 250,
    fields: ['id (PK)', 'user_id (FK)', 'full_name', 'avatar_url', 'phone', 'bio'],
  },
  {
    id: 'user_settings',
    title: 'USER_SETTINGS',
    domain: 'identity',
    x: 1700,
    y: 330,
    w: 280,
    fields: ['id (PK)', 'user_id (FK)', 'notifications_enabled', 'marketing_enabled', 'privacy_level', 'ai_assist_enabled'],
  },
  {
    id: 'event_categories',
    title: 'EVENT_CATEGORIES',
    domain: 'events',
    x: 1080,
    y: 700,
    w: 240,
    fields: ['id (PK)', 'name', 'slug'],
  },
  {
    id: 'events',
    title: 'EVENTS',
    domain: 'events',
    x: 1410,
    y: 670,
    w: 290,
    fields: ['id (PK)', 'organizer_id (FK)', 'category_id (FK)', 'title', 'venue', 'city', 'latitude', 'longitude', 'vendor_match_radius_km', 'start_at', 'end_at', 'status', 'visibility'],
  },
  {
    id: 'event_views',
    title: 'EVENT_VIEWS',
    domain: 'events',
    x: 1780,
    y: 690,
    w: 240,
    fields: ['id (PK)', 'user_id (FK)', 'event_id (FK)', 'view_count', 'created_at', 'updated_at'],
  },
  {
    id: 'event_favorites',
    title: 'EVENT_FAVORITES',
    domain: 'events',
    x: 1080,
    y: 1010,
    w: 240,
    fields: ['id (PK)', 'user_id (FK)', 'event_id (FK)', 'created_at'],
  },
  {
    id: 'ticket_types',
    title: 'TICKET_TYPES',
    domain: 'events',
    x: 1410,
    y: 970,
    w: 270,
    fields: ['id (PK)', 'event_id (FK)', 'name', 'price', 'quantity', 'remaining', 'sale_start_at', 'sale_end_at'],
  },
  {
    id: 'registrations',
    title: 'REGISTRATIONS',
    domain: 'events',
    x: 1780,
    y: 950,
    w: 260,
    fields: ['id (PK)', 'event_id (FK)', 'attendee_id (FK)', 'ticket_type_id (FK)', 'quantity', 'status', 'created_at'],
  },
  {
    id: 'vendor_profiles',
    title: 'VENDOR_PROFILES',
    domain: 'vendors',
    x: 2210,
    y: 690,
    w: 280,
    fields: ['id (PK)', 'user_id (FK)', 'business_name', 'category', 'service_area', 'latitude', 'longitude', 'travel_radius_km', 'verified', 'rating_average'],
  },
  {
    id: 'vendor_services',
    title: 'VENDOR_SERVICES',
    domain: 'vendors',
    x: 2580,
    y: 670,
    w: 250,
    fields: ['id (PK)', 'vendor_id (FK)', 'name', 'description', 'base_price', 'pricing_model'],
  },
  {
    id: 'vendor_packages',
    title: 'VENDOR_PACKAGES',
    domain: 'vendors',
    x: 2580,
    y: 950,
    w: 250,
    fields: ['id (PK)', 'vendor_id (FK)', 'name', 'description', 'price'],
  },
  {
    id: 'vendor_requests',
    title: 'VENDOR_REQUESTS',
    domain: 'vendors',
    x: 2210,
    y: 1040,
    w: 290,
    fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'vendor_id (FK)', 'status', 'message', 'proposed_budget', 'created_at', 'updated_at'],
  },
  {
    id: 'vendor_booking_preferences',
    title: 'VENDOR_BOOKING_PREFERENCES',
    domain: 'vendors',
    x: 2550,
    y: 1240,
    w: 310,
    fields: ['id (PK)', 'vendor_id (FK)', 'allow_direct_booking', 'allow_request_booking'],
  },
  {
    id: 'sponsor_profiles',
    title: 'SPONSOR_PROFILES',
    domain: 'sponsors',
    x: 180,
    y: 720,
    w: 260,
    fields: ['id (PK)', 'user_id (FK)', 'company_name', 'description', 'industries', 'logo_url', 'website_url', 'verified'],
  },
  {
    id: 'sponsorship_opportunities',
    title: 'SPONSORSHIP_OPPORTUNITIES',
    domain: 'sponsors',
    x: 180,
    y: 1040,
    w: 300,
    fields: ['id (PK)', 'event_id (FK)', 'organizer_id (FK)', 'title', 'required_amount', 'target_audience', 'status', 'created_at'],
  },
  {
    id: 'sponsorship_interests',
    title: 'SPONSORSHIP_INTERESTS',
    domain: 'sponsors',
    x: 560,
    y: 1020,
    w: 270,
    fields: ['id (PK)', 'sponsor_id (FK)', 'opportunity_id (FK)', 'status', 'message', 'created_at'],
  },
  {
    id: 'bookings',
    title: 'BOOKINGS',
    domain: 'payments',
    x: 220,
    y: 1480,
    w: 280,
    fields: ['id (PK)', 'requester_id (FK)', 'target_user_id (FK)', 'event_id (FK)', 'registration_id (FK)', 'status', 'amount', 'currency', 'created_at'],
  },
  {
    id: 'payments',
    title: 'PAYMENTS',
    domain: 'payments',
    x: 590,
    y: 1480,
    w: 260,
    fields: ['id (PK)', 'booking_id (FK)', 'payer_id (FK)', 'provider', 'provider_ref', 'amount', 'currency', 'status', 'paid_at'],
  },
  {
    id: 'refunds',
    title: 'REFUNDS',
    domain: 'payments',
    x: 760,
    y: 1645,
    w: 230,
    fields: ['id (PK)', 'payment_id (FK)', 'reason', 'status', 'amount'],
  },
  {
    id: 'conversations',
    title: 'CONVERSATIONS',
    domain: 'communication',
    x: 1140,
    y: 1360,
    w: 250,
    fields: ['id (PK)', 'type', 'created_at'],
  },
  {
    id: 'conversation_participants',
    title: 'CONVERSATION_PARTICIPANTS',
    domain: 'communication',
    x: 1460,
    y: 1330,
    w: 310,
    fields: ['id (PK)', 'conversation_id (FK)', 'user_id (FK)', 'joined_at'],
  },
  {
    id: 'messages',
    title: 'MESSAGES',
    domain: 'communication',
    x: 1160,
    y: 1590,
    w: 260,
    fields: ['id (PK)', 'conversation_id (FK)', 'sender_id (FK)', 'body', 'message_type', 'created_at'],
  },
  {
    id: 'notifications',
    title: 'NOTIFICATIONS',
    domain: 'communication',
    x: 1550,
    y: 1510,
    w: 260,
    fields: ['id (PK)', 'user_id (FK)', 'type', 'title', 'resource_type', 'resource_id', 'read_at', 'created_at'],
  },
  {
    id: 'support_tickets',
    title: 'SUPPORT_TICKETS',
    domain: 'support',
    x: 2230,
    y: 1480,
    w: 280,
    fields: ['id (PK)', 'user_id (FK)', 'category', 'subject', 'status', 'priority', 'assigned_admin_id', 'ai_confidence', 'created_at'],
  },
  {
    id: 'escalations',
    title: 'ESCALATIONS',
    domain: 'support',
    x: 2590,
    y: 1490,
    w: 240,
    fields: ['id (PK)', 'source_type', 'source_id', 'reason', 'ai_confidence', 'status', 'assigned_to', 'created_at'],
  },
];

const entityMap = new Map(entities.map((entity) => [entity.id, entity]));

const relations = [
  rel('users', 'right', 'user_profiles', 'left', ['1630,170'], '1', '1'),
  rel('users', 'right', 'user_settings', 'left', ['1640,320', '1640,410'], '1', '1'),
  rel('users', 'left', 'sessions', 'right', ['1260,170'], '1', '*'),
  rel('users', 'left', 'email_tokens', 'right', ['1240,290', '1240,390'], '1', '*'),
  rel('users', 'left', 'reset_tokens', 'right', ['1230,330', '1230,580'], '1', '*'),
  rel('users', 'bottom', 'events', 'top', ['1450,470'], '1', '*'),
  rel('users', 'bottom', 'event_views', 'top', ['1620,470', '1620,640'], '1', '*'),
  rel('users', 'bottom', 'event_favorites', 'top', ['1280,470', '1280,960'], '1', '*'),
  rel('users', 'bottom', 'registrations', 'top', ['1740,470', '1740,900'], '1', '*'),
  rel('users', 'right', 'vendor_profiles', 'left', ['2090,210', '2090,830'], '1', '1'),
  rel('users', 'left', 'sponsor_profiles', 'right', ['820,210', '820,840'], '1', '1'),
  rel('users', 'bottom', 'conversation_participants', 'top', ['1600,470', '1600,1290'], '1', '*'),
  rel('users', 'bottom', 'messages', 'top', ['1350,470', '1350,1540'], '1', '*'),
  rel('users', 'bottom', 'notifications', 'top', ['1720,470', '1720,1460'], '1', '*'),
  rel('users', 'bottom', 'support_tickets', 'top', ['2440,470', '2440,1430'], '1', '*'),
  rel('users', 'left', 'bookings', 'top', ['820,250', '820,1440'], '1', '*'),
  rel('users', 'left', 'payments', 'top', ['940,250', '940,1440'], '1', '*'),
  rel('event_categories', 'right', 'events', 'left', [], '1', '*'),
  rel('events', 'right', 'event_views', 'left', [], '1', '*'),
  rel('events', 'left', 'event_favorites', 'top', ['1210,930'], '1', '*'),
  rel('events', 'bottom', 'ticket_types', 'top', [], '1', '*'),
  rel('events', 'bottom', 'registrations', 'top', ['1670,900'], '1', '*'),
  rel('events', 'right', 'vendor_requests', 'left', ['2050,1030'], '1', '*'),
  rel('events', 'left', 'sponsorship_opportunities', 'right', ['1330,830', '1330,1100'], '1', '*'),
  rel('ticket_types', 'right', 'registrations', 'left', ['1735,1080'], '1', '*'),
  rel('vendor_profiles', 'right', 'vendor_services', 'left', ['2530,790'], '1', '*'),
  rel('vendor_profiles', 'right', 'vendor_packages', 'left', ['2525,970', '2525,1030'], '1', '*'),
  rel('vendor_profiles', 'bottom', 'vendor_booking_preferences', 'top', ['2700,1140'], '1', '1'),
  rel('vendor_profiles', 'bottom', 'vendor_requests', 'top', ['2350,990'], '1', '*'),
  rel('sponsor_profiles', 'bottom', 'sponsorship_interests', 'left', ['430,1160', '540,1160'], '1', '*'),
  rel('sponsorship_opportunities', 'right', 'sponsorship_interests', 'left', [], '1', '*'),
  rel('conversations', 'right', 'conversation_participants', 'left', [], '1', '*'),
  rel('conversations', 'bottom', 'messages', 'top', ['1280,1540'], '1', '*'),
  rel('support_tickets', 'right', 'escalations', 'left', ['2560,1540'], '1', '*'),
  rel('registrations', 'left', 'bookings', 'top', ['1560,1210', '1560,1370', '360,1370'], '1', '1'),
  rel('bookings', 'right', 'payments', 'left', [], '1', '*'),
  rel('payments', 'bottom', 'refunds', 'top', ['810,1615'], '1', '*'),
];

function rel(from, fromSide, to, toSide, mids, fromLabel, toLabel) {
  return { from, fromSide, to, toSide, mids, fromLabel, toLabel };
}

function entityHeight(entity) {
  return 44 + entity.fields.length * 24 + 18;
}

function pointFor(entity, side) {
  const h = entityHeight(entity);
  switch (side) {
    case 'left':
      return { x: entity.x, y: entity.y + h / 2 };
    case 'right':
      return { x: entity.x + entity.w, y: entity.y + h / 2 };
    case 'top':
      return { x: entity.x + entity.w / 2, y: entity.y };
    case 'bottom':
      return { x: entity.x + entity.w / 2, y: entity.y + h };
    default:
      throw new Error(`Unknown side ${side}`);
  }
}

function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function drawDomain(domain) {
  return `
    <g>
      <rect x="${domain.x}" y="${domain.y}" width="${domain.w}" height="${domain.h}" rx="28" fill="rgba(255,251,245,0.78)" stroke="${domain.color}" stroke-width="2"/>
      <rect x="${domain.x + 24}" y="${domain.y - 16}" width="${Math.max(170, domain.label.length * 14)}" height="38" rx="19" fill="${colors.bg}"/>
      <text x="${domain.x + 46}" y="${domain.y + 9}" fill="${domain.color}" font-size="18" font-weight="800" letter-spacing="2">${domain.label}</text>
    </g>
  `;
}

function domainColor(entity) {
  const domain = domains.find((item) => item.key === entity.domain);
  return domain?.color ?? colors.navy;
}

function drawEntity(entity) {
  const h = entityHeight(entity);
  const headerColor = domainColor(entity);
  const rows = entity.fields
    .map(
      (field, index) => `
        <text x="${entity.x + 18}" y="${entity.y + 68 + index * 24}" fill="${colors.text}" font-size="14" font-weight="500">${escapeXml(field)}</text>
      `,
    )
    .join('');

  return `
    <g>
      <rect x="${entity.x}" y="${entity.y}" width="${entity.w}" height="${h}" rx="16" fill="${colors.panel}" stroke="${headerColor}" stroke-width="1.5"/>
      <rect x="${entity.x}" y="${entity.y}" width="${entity.w}" height="38" rx="16" fill="${headerColor}"/>
      <rect x="${entity.x}" y="${entity.y + 22}" width="${entity.w}" height="16" fill="${headerColor}"/>
      <text x="${entity.x + entity.w / 2}" y="${entity.y + 25}" fill="#FFFFFF" font-size="14" font-weight="800" text-anchor="middle">${entity.title}</text>
      ${rows}
    </g>
  `;
}

function drawRelation(relation) {
  const fromEntity = entityMap.get(relation.from);
  const toEntity = entityMap.get(relation.to);
  const from = pointFor(fromEntity, relation.fromSide);
  const to = pointFor(toEntity, relation.toSide);
  const points = [from, ...relation.mids.map((value) => {
    const [x, y] = value.split(',').map(Number);
    return { x, y };
  }), to];
  const path = points.map((point) => `${point.x},${point.y}`).join(' ');
  const firstMid = points[1] ?? to;
  const lastMid = points.at(-2) ?? from;

  return `
    <g>
      <polyline points="${path}" fill="none" stroke="${colors.line}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="${from.x}" cy="${from.y}" r="3.5" fill="${colors.line}"/>
      <circle cx="${to.x}" cy="${to.y}" r="3.5" fill="${colors.line}"/>
      <text x="${(from.x + firstMid.x) / 2}" y="${(from.y + firstMid.y) / 2 - 6}" fill="${colors.muted}" font-size="13" font-weight="700">${relation.fromLabel}</text>
      <text x="${(to.x + lastMid.x) / 2}" y="${(to.y + lastMid.y) / 2 - 6}" fill="${colors.muted}" font-size="13" font-weight="700">${relation.toLabel}</text>
    </g>
  `;
}

const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <filter id="cardShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="14" stdDeviation="18" flood-color="#102844" flood-opacity="0.08"/>
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="${colors.bg}"/>
  <circle cx="2580" cy="130" r="180" fill="rgba(15,166,184,0.08)"/>
  <circle cx="350" cy="1820" r="220" fill="rgba(211,155,60,0.08)"/>
  <text x="120" y="115" fill="${colors.navy}" font-size="74" font-weight="800" font-family="Georgia, 'Times New Roman', serif">Meloo ERD</text>
  <text x="122" y="160" fill="${colors.muted}" font-size="20" font-weight="500">Schema-verified overview of the production data model</text>
  <line x1="120" y1="184" x2="860" y2="184" stroke="${colors.gold}" stroke-width="3"/>
  ${domains.map(drawDomain).join('')}
  <g filter="url(#cardShadow)">
    ${relations.map(drawRelation).join('')}
    ${entities.map(drawEntity).join('')}
  </g>
  <g>
    <rect x="2500" y="120" width="300" height="118" rx="18" fill="${colors.panel}" stroke="${colors.border}" stroke-width="1.5"/>
    <text x="2530" y="156" fill="${colors.navy}" font-size="18" font-weight="800">Legend</text>
    <text x="2530" y="188" fill="${colors.text}" font-size="14">PK = Primary key</text>
    <text x="2530" y="212" fill="${colors.text}" font-size="14">FK = Foreign key</text>
    <text x="2660" y="188" fill="${colors.text}" font-size="14">1 = one</text>
    <text x="2660" y="212" fill="${colors.text}" font-size="14">* = many</text>
  </g>
</svg>`;

await fs.writeFile(outputPath, svg.trimStart(), 'utf8');
console.log(`Wrote ${outputPath}`);
