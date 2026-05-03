import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:3000/api';
const outputDir = path.resolve(process.cwd(), '.tooling/demo');
const defaultPassword = 'Password123!';

const cityCatalog = {
  kathmandu: {
    city: 'Kathmandu',
    venue: 'Bhrikutimandap Exhibition Hall',
    latitude: 27.7172,
    longitude: 85.324,
  },
  lalitpur: {
    city: 'Lalitpur',
    venue: 'Patan Durbar Civic Hall',
    latitude: 27.6644,
    longitude: 85.3188,
  },
  bhaktapur: {
    city: 'Bhaktapur',
    venue: 'Bhaktapur Heritage Courtyard',
    latitude: 27.671,
    longitude: 85.4298,
  },
  pokhara: {
    city: 'Pokhara',
    venue: 'Pokhara Exhibition Centre',
    latitude: 28.2096,
    longitude: 83.9856,
  },
  biratnagar: {
    city: 'Biratnagar',
    venue: 'Morang Trade Center',
    latitude: 26.4525,
    longitude: 87.2718,
  },
  chitwan: {
    city: 'Chitwan',
    venue: 'Bharatpur Riverside Convention Lawn',
    latitude: 27.5291,
    longitude: 84.3542,
  },
  butwal: {
    city: 'Butwal',
    venue: 'Butwal International Conference Hall',
    latitude: 27.7006,
    longitude: 83.4484,
  },
  dharan: {
    city: 'Dharan',
    venue: 'Dharan City Event Pavilion',
    latitude: 26.812,
    longitude: 87.2833,
  },
  janakpur: {
    city: 'Janakpur',
    venue: 'Janakpur Cultural Plaza',
    latitude: 26.7288,
    longitude: 85.925,
  },
  nepalgunj: {
    city: 'Nepalgunj',
    venue: 'Nepalgunj Trade and Transit Hall',
    latitude: 28.05,
    longitude: 81.6167,
  },
};

const users = [
  {
    email: 'admin@meloo.local',
    password: defaultPassword,
    role: 'admin',
    profile: {
      fullName: 'Aayusha Adhikari',
      phone: '+9779801000001',
      bio: 'Platform operations lead handling moderation, trust review, synthetic QA, and support across Nepal deployments.',
    },
  },
  {
    email: 'organizer@meloo.local',
    password: defaultPassword,
    role: 'organizer',
    profile: {
      fullName: 'Sanjog Shrestha',
      phone: '+9779801000002',
      bio: 'Kathmandu-based organizer focused on AI, startup, and civic-tech events with strong vendor coordination needs.',
    },
  },
  {
    email: 'vendor@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Prerana Gurung',
      phone: '+9779801000003',
      bio: 'Event production specialist serving Kathmandu, Lalitpur, and large-format stage builds across Nepal.',
    },
  },
  {
    email: 'sponsor@meloo.local',
    password: defaultPassword,
    role: 'sponsor',
    profile: {
      fullName: 'Nima Karki',
      phone: '+9779801000004',
      bio: 'Commercial partnerships lead interested in technology, mobility, education, and youth audiences in Nepal.',
    },
  },
  {
    email: 'attendee@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Ritesh Rai',
      phone: '+9779801000005',
      bio: 'Attendee from Biratnagar following technology meetups, startup communities, and practical business events in Nepal.',
    },
  },
  {
    email: 'mira.joshi@meloo.local',
    password: defaultPassword,
    role: 'organizer',
    profile: {
      fullName: 'Mira Joshi',
      phone: '+9779801000011',
      bio: 'Pokhara organizer building creator-economy, education, and destination events around tourism and local commerce.',
    },
  },
  {
    email: 'bikash.chaudhary@meloo.local',
    password: defaultPassword,
    role: 'organizer',
    profile: {
      fullName: 'Bikash Chaudhary',
      phone: '+9779801000012',
      bio: 'Biratnagar organizer focused on manufacturing, logistics, and business networking programs in eastern Nepal.',
    },
  },
  {
    email: 'anusha.poudel@meloo.local',
    password: defaultPassword,
    role: 'organizer',
    profile: {
      fullName: 'Anusha Poudel',
      phone: '+9779801000013',
      bio: 'Chitwan organizer creating youth, community, and culture-led programs with sponsor and safety dependencies.',
    },
  },
  {
    email: 'deepak.kunwar@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Deepak Kunwar',
      phone: '+9779801000021',
      bio: 'Pokhara photography and scenic event coverage specialist for destination events and conferences.',
    },
  },
  {
    email: 'sushma.lama@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Sushma Lama',
      phone: '+9779801000022',
      bio: 'Biratnagar expo fabrication and booth operations partner for trade events and industrial exhibitions.',
    },
  },
  {
    email: 'krishna.giri@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Krishna Giri',
      phone: '+9779801000023',
      bio: 'Butwal catering lead serving conferences, corporate meetups, and food logistics-heavy events.',
    },
  },
  {
    email: 'sarita.thapa@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Sarita Thapa',
      phone: '+9779801000024',
      bio: 'Chitwan security and crowd operations partner for sports, public, and youth events.',
    },
  },
  {
    email: 'manish.shakya@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Manish Shakya',
      phone: '+9779801000025',
      bio: 'Bhaktapur decor, signage, and heritage venue styling vendor for cultural events and launches.',
    },
  },
  {
    email: 'rekha.tamang@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Rekha Tamang',
      phone: '+9779801000026',
      bio: 'Lalitpur livestream and hybrid event technician supporting panels, education forums, and sponsor showcases.',
    },
  },
  {
    email: 'abinash.yadav@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Abinash Yadav',
      phone: '+9779801000027',
      bio: 'Janakpur audio and stage systems operator for concerts, community events, and political programs.',
    },
  },
  {
    email: 'tsering.sherpa@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Tsering Sherpa',
      phone: '+9779801000028',
      bio: 'Kathmandu lighting and rigging coordinator for summits, performances, and premium stage builds.',
    },
  },
  {
    email: 'rahul.khanal@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Rahul Khanal',
      phone: '+9779801000029',
      bio: 'Nepalgunj logistics and transport planner for roadshow, transit, and equipment-heavy events.',
    },
  },
  {
    email: 'sabina.rai@meloo.local',
    password: defaultPassword,
    role: 'vendor',
    profile: {
      fullName: 'Sabina Rai',
      phone: '+9779801000030',
      bio: 'Dharan guest-experience and registration desk operator for business and education events.',
    },
  },
  {
    email: 'sponsor.yeti@meloo.local',
    password: defaultPassword,
    role: 'sponsor',
    profile: {
      fullName: 'Pratiksha Bista',
      phone: '+9779801000031',
      bio: 'Kathmandu sponsorship manager for mobility, AI, digital public services, and startup ecosystem programs.',
    },
  },
  {
    email: 'sponsor.lakeside@meloo.local',
    password: defaultPassword,
    role: 'sponsor',
    profile: {
      fullName: 'Aashish Gurung',
      phone: '+9779801000032',
      bio: 'Pokhara brand lead investing in tourism, creator commerce, and community engagement experiences.',
    },
  },
  {
    email: 'sponsor.koshi@meloo.local',
    password: defaultPassword,
    role: 'sponsor',
    profile: {
      fullName: 'Sandeep Jha',
      phone: '+9779801000033',
      bio: 'Biratnagar commercial lead focused on agriculture, manufacturing, logistics, and industrial audiences.',
    },
  },
  {
    email: 'sponsor.himal@meloo.local',
    password: defaultPassword,
    role: 'sponsor',
    profile: {
      fullName: 'Binita Maharjan',
      phone: '+9779801000034',
      bio: 'Lalitpur partnerships lead for education, youth skilling, and social-impact event collaborations.',
    },
  },
  {
    email: 'attendee.pokhara@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Sujan Kafle',
      phone: '+9779801000041',
      bio: 'Pokhara attendee interested in creator economy, tourism innovation, and community business events.',
    },
  },
  {
    email: 'attendee.lalitpur@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Asmita Maharjan',
      phone: '+9779801000042',
      bio: 'Lalitpur attendee following education, civic design, and youth innovation programs near Kathmandu Valley.',
    },
  },
  {
    email: 'attendee.butwal@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Dipesh GC',
      phone: '+9779801000043',
      bio: 'Butwal attendee interested in supply chain, food systems, logistics, and regional business networking.',
    },
  },
  {
    email: 'attendee.chitwan@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Rojina Regmi',
      phone: '+9779801000044',
      bio: 'Chitwan attendee attending youth, sports, culture, and sponsor-backed public events.',
    },
  },
  {
    email: 'attendee.dharan@meloo.local',
    password: defaultPassword,
    role: 'attendee',
    profile: {
      fullName: 'Niraj Rai',
      phone: '+9779801000045',
      bio: 'Dharan attendee interested in music, entrepreneurship, and practical training events in eastern Nepal.',
    },
  },
];

const vendorDefinitions = [
  {
    email: 'vendor@meloo.local',
    businessName: 'Everest AV & Staging',
    description:
      'Kathmandu production partner handling stage builds, LED walls, keynote audio, and high-pressure conference changeovers.',
    category: 'AV / production',
    serviceArea: 'Kathmandu Valley',
    location: cityCatalog.kathmandu,
    travelRadiusKm: 70,
    allowDirectBooking: true,
    allowRequestBooking: true,
    services: [
      ['Keynote AV Control', 'Audio mixing, screen routing, and presenter cueing for summits and flagship sessions.', '145000.00', 'per event'],
      ['Stage Build Crew', 'Truss, backdrop, lectern, and backstage operations support for large venues.', '110000.00', 'per event'],
    ],
    packages: [
      ['Summit Main Stage Package', 'Main stage sound, LED support, operator crew, and transition staffing.', '285000.00'],
    ],
  },
  {
    email: 'deepak.kunwar@meloo.local',
    businessName: 'Phewa Moments Studio',
    description:
      'Pokhara photography and short-form content studio for destination conferences, tourism launches, and creator events.',
    category: 'Photography',
    serviceArea: 'Pokhara and Kaski',
    location: cityCatalog.pokhara,
    travelRadiusKm: 90,
    allowDirectBooking: true,
    allowRequestBooking: true,
    services: [
      ['Event Photo Coverage', 'Full-day still coverage with speaker, crowd, and sponsor asset delivery.', '65000.00', 'per event'],
      ['Social Reel Capture', 'Short-form vertical clips for creator and tourism campaigns.', '45000.00', 'per event'],
    ],
    packages: [
      ['Destination Storytelling Package', 'Photography, reels, and sponsor booth media from setup through closing.', '125000.00'],
    ],
  },
  {
    email: 'sushma.lama@meloo.local',
    businessName: 'Koshi Expo Fabrication',
    description:
      'Biratnagar exhibition fabrication partner for trade booths, traffic flow, signage, and vendor floor builds.',
    category: 'Venue operations',
    serviceArea: 'Biratnagar and Sunsari-Morang corridor',
    location: cityCatalog.biratnagar,
    travelRadiusKm: 110,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Booth Fabrication', 'Custom booth walls, display islands, and sponsor structures for expos.', '155000.00', 'per event'],
      ['Floor Operations Support', 'Vendor load-in sequencing, utility coordination, and hall reset support.', '78000.00', 'per event'],
    ],
    packages: [
      ['Trade Expo Floor Package', 'Booth production, signage rails, and vendor hall operations for regional expos.', '310000.00'],
    ],
  },
  {
    email: 'krishna.giri@meloo.local',
    businessName: 'Lumbini Feast Catering',
    description:
      'Butwal catering company serving business forums, food-industry meetups, and formal seated community events.',
    category: 'Catering',
    serviceArea: 'Butwal, Bhairahawa, and Rupandehi',
    location: cityCatalog.butwal,
    travelRadiusKm: 85,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Conference Meal Service', 'Tea breaks, buffet service, and plated lunch operations for day events.', '950.00', 'per attendee'],
      ['VIP Hosting Menu', 'Premium hosted service for sponsors, speakers, and partner dinners.', '2400.00', 'per attendee'],
    ],
    packages: [
      ['Business Forum Catering Package', 'Tea, lunch, service crew, and hygiene setup for 150 to 300 guests.', '210000.00'],
    ],
  },
  {
    email: 'sarita.thapa@meloo.local',
    businessName: 'Narayani Crowd & Security',
    description:
      'Chitwan event security and crowd operations vendor for public gatherings, sports programming, and sponsor activations.',
    category: 'Security',
    serviceArea: 'Chitwan and Bharatpur',
    location: cityCatalog.chitwan,
    travelRadiusKm: 75,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Perimeter Security', 'Entry gate, backstage, and public perimeter staffing.', '85000.00', 'per event'],
      ['Crowd Flow Planning', 'Queue design, incident routing, and volunteer briefing for public programs.', '52000.00', 'per event'],
    ],
    packages: [
      ['Festival Safety Package', 'Supervisors, perimeter crew, entry control, and incident escalation coverage.', '185000.00'],
    ],
  },
  {
    email: 'manish.shakya@meloo.local',
    businessName: 'Bhaktapur Decor House',
    description:
      'Heritage-sensitive decor and signage workshop for culture festivals, launches, receptions, and courtyard venues.',
    category: 'Branding / signage',
    serviceArea: 'Bhaktapur and Kathmandu Valley',
    location: cityCatalog.bhaktapur,
    travelRadiusKm: 45,
    allowDirectBooking: true,
    allowRequestBooking: true,
    services: [
      ['Directional Signage Build', 'Wayfinding, sponsor placement, and venue marker production.', '58000.00', 'per event'],
      ['Heritage Decor Styling', 'Floral, textile, and courtyard-safe decor setup for culture-facing programs.', '72000.00', 'per event'],
    ],
    packages: [
      ['Courtyard Identity Package', 'Entrance styling, sign systems, and photo-op decor for branded heritage events.', '138000.00'],
    ],
  },
  {
    email: 'rekha.tamang@meloo.local',
    businessName: 'Himalayan StreamWorks',
    description:
      'Lalitpur hybrid event and livestream team covering panels, education forums, and sponsor-backed broadcasts.',
    category: 'Streaming support',
    serviceArea: 'Kathmandu Valley',
    location: cityCatalog.lalitpur,
    travelRadiusKm: 40,
    allowDirectBooking: true,
    allowRequestBooking: true,
    services: [
      ['Hybrid Event Streaming', 'Multi-camera livestreaming with lower-third and remote speaker support.', '135000.00', 'per event'],
      ['Session Recording', 'Clean session capture for later publication and sponsor recap assets.', '42000.00', 'per event'],
    ],
    packages: [
      ['Forum Broadcast Package', 'Hybrid setup, encoding, streaming crew, and recording delivery.', '225000.00'],
    ],
  },
  {
    email: 'abinash.yadav@meloo.local',
    businessName: 'Janakpur Sound Collective',
    description:
      'Janakpur stage sound operator for concerts, community shows, and politically sensitive public gatherings.',
    category: 'Music',
    serviceArea: 'Janakpur and Madhesh Province',
    location: cityCatalog.janakpur,
    travelRadiusKm: 120,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Live Sound Setup', 'Concert front-of-house, monitor control, and stage patching.', '98000.00', 'per event'],
      ['Mic and Backline Support', 'Microphones, DI routing, and stage input management for live acts.', '51000.00', 'per event'],
    ],
    packages: [
      ['Community Concert Audio Package', 'PA system, sound engineer, monitor control, and stage support.', '198000.00'],
    ],
  },
  {
    email: 'tsering.sherpa@meloo.local',
    businessName: 'Dharma Light Lab',
    description:
      'Kathmandu lighting vendor focused on premium keynote scenes, stage mood design, and indoor sponsor reveals.',
    category: 'Lighting',
    serviceArea: 'Kathmandu Valley and Pokhara',
    location: cityCatalog.kathmandu,
    travelRadiusKm: 140,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Stage Lighting Design', 'Scene programming, keynote follow cues, and sponsor reveal transitions.', '118000.00', 'per event'],
      ['Architectural Uplighting', 'Venue mood lighting for launch nights, receptions, and gala setups.', '64000.00', 'per event'],
    ],
    packages: [
      ['Premium Stage Lighting Package', 'Programmed keynote scenes, operator, uplighting, and transition support.', '205000.00'],
    ],
  },
  {
    email: 'rahul.khanal@meloo.local',
    businessName: 'Nepalgunj Transit Logistics',
    description:
      'Equipment logistics and overland transport coordinator for roadshows, regional expos, and distributed events.',
    category: 'Logistics',
    serviceArea: 'Nepalgunj and western Nepal',
    location: cityCatalog.nepalgunj,
    travelRadiusKm: 220,
    allowDirectBooking: false,
    allowRequestBooking: true,
    services: [
      ['Equipment Transport Planning', 'Vehicle routing, route sequencing, and overnight logistics planning.', '72000.00', 'per event'],
      ['Load-in Coordination', 'Dock sequencing, unloading crews, and supplier timing control.', '54000.00', 'per event'],
    ],
    packages: [
      ['Regional Expo Logistics Package', 'Transport, route planning, load-in management, and teardown routing.', '190000.00'],
    ],
  },
  {
    email: 'sabina.rai@meloo.local',
    businessName: 'Dharan Guest Flow Desk',
    description:
      'Dharan registration, guest support, and check-in operations vendor for conferences and education forums.',
    category: 'Guest experience',
    serviceArea: 'Dharan and eastern Nepal',
    location: cityCatalog.dharan,
    travelRadiusKm: 95,
    allowDirectBooking: true,
    allowRequestBooking: true,
    services: [
      ['Registration Desk Staffing', 'QR check-in, badge handling, and attendee issue support.', '46000.00', 'per event'],
      ['Help Desk Operations', 'Volunteer briefing, attendee support, and escalation triage on event day.', '39000.00', 'per event'],
    ],
    packages: [
      ['Conference Guest Flow Package', 'Check-in desk, attendee help point, and day-of issue handling crew.', '98000.00'],
    ],
  },
];

const sponsorDefinitions = [
  {
    email: 'sponsor@meloo.local',
    companyName: 'Sagarmatha Digital Ventures',
    description:
      'Nepal-focused technology growth partner backing AI, digital public service, and operator community programs.',
    industries: 'technology, artificial intelligence, civic tech, SaaS, digital services',
    websiteUrl: 'https://sagarmatha.meloo.local',
  },
  {
    email: 'sponsor.yeti@meloo.local',
    companyName: 'Yeti Mobility Labs',
    description:
      'Mobility and data systems company supporting smart-city pilots, transport tech, and infrastructure conversations.',
    industries: 'mobility, smart cities, transportation, data platforms, urban technology',
    websiteUrl: 'https://yeti-mobility.meloo.local',
  },
  {
    email: 'sponsor.lakeside@meloo.local',
    companyName: 'Lakeside Commerce Bank',
    description:
      'Pokhara commercial bank investing in tourism, creator transactions, and regional entrepreneurship ecosystems.',
    industries: 'tourism, creator economy, finance, small business, commerce',
    websiteUrl: 'https://lakeside-bank.meloo.local',
  },
  {
    email: 'sponsor.koshi@meloo.local',
    companyName: 'Koshi Agro Ventures',
    description:
      'Eastern Nepal agribusiness group supporting manufacturing, logistics, cold-chain, and regional trade events.',
    industries: 'agriculture, manufacturing, logistics, supply chain, trade',
    websiteUrl: 'https://koshi-agro.meloo.local',
  },
  {
    email: 'sponsor.himal@meloo.local',
    companyName: 'Himal Education Trust',
    description:
      'Education and youth-skilling foundation funding practical learning, employability, and social impact forums.',
    industries: 'education, youth, skilling, nonprofit, social impact',
    websiteUrl: 'https://himal-education.meloo.local',
  },
];

const eventDefinitions = [
  {
    organizerEmail: 'organizer@meloo.local',
    title: 'Kathmandu AI & Civic Tech Summit 2026',
    description:
      'A practical summit for AI operators, civic-tech builders, startup teams, and digital service leaders working in Nepal.',
    categorySlug: 'technology',
    location: cityCatalog.kathmandu,
    vendorMatchRadiusKm: 60,
    dayOffset: 18,
    durationHours: 9,
    ticketTypes: [
      ['Community Pass', '0.00', 320],
      ['Operator Pass', '2500.00', 120],
    ],
    opportunities: [
      {
        title: 'AI Infrastructure Lead Partner',
        description:
          'Lead support for keynote infrastructure, operator lounges, and the civic-tech demo corridor.',
        requiredAmount: '450000.00',
        targetAudience: 'AI operators, startup teams, public-service technologists, and product builders',
        benefitsOffered: 'Keynote mention, demo corridor branding, lead capture, and operator roundtable access',
      },
    ],
  },
  {
    organizerEmail: 'mira.joshi@meloo.local',
    title: 'Pokhara Creator Commerce Fest',
    description:
      'A destination event for tourism storytellers, creator businesses, hospitality operators, and ecommerce service partners.',
    categorySlug: 'business',
    location: cityCatalog.pokhara,
    vendorMatchRadiusKm: 85,
    dayOffset: 26,
    durationHours: 8,
    ticketTypes: [
      ['Community Entry', '0.00', 260],
      ['Creator Pro Pass', '1800.00', 90],
    ],
    opportunities: [
      {
        title: 'Lakeside Experience Sponsor',
        description:
          'Own the creator lounge, destination content wall, and commerce activation zone.',
        requiredAmount: '320000.00',
        targetAudience: 'Tourism creators, local businesses, hospitality brands, and young entrepreneurs',
        benefitsOffered: 'Lounge branding, activation booth, social media mentions, and lead capture',
      },
    ],
  },
  {
    organizerEmail: 'bikash.chaudhary@meloo.local',
    title: 'Biratnagar Industry and Logistics Expo',
    description:
      'A regional trade event for manufacturers, warehouse operators, distributors, and logistics decision makers.',
    categorySlug: 'business',
    location: cityCatalog.biratnagar,
    vendorMatchRadiusKm: 120,
    dayOffset: 31,
    durationHours: 10,
    ticketTypes: [
      ['Trade Visitor Pass', '0.00', 500],
      ['Business Match Pass', '2200.00', 130],
    ],
    opportunities: [
      {
        title: 'Regional Supply Chain Sponsor',
        description:
          'Back the logistics zone, trade floor networking, and matchmaking sessions for eastern Nepal operators.',
        requiredAmount: '520000.00',
        targetAudience: 'Manufacturing leaders, transport operators, traders, and warehouse managers',
        benefitsOffered: 'Trade floor branding, networking session sponsorship, and sector lead capture',
      },
    ],
  },
  {
    organizerEmail: 'anusha.poudel@meloo.local',
    title: 'Chitwan Youth Sports and Culture Weekend',
    description:
      'A community event mixing youth sports programming, culture showcases, sponsor activations, and public attendance.',
    categorySlug: 'community',
    location: cityCatalog.chitwan,
    vendorMatchRadiusKm: 70,
    dayOffset: 22,
    durationHours: 11,
    ticketTypes: [
      ['Community Access', '0.00', 800],
      ['Premium Seating', '1200.00', 140],
    ],
    opportunities: [
      {
        title: 'Youth Impact Activation Sponsor',
        description:
          'Support the youth stage, sports area signage, and community engagement booths.',
        requiredAmount: '280000.00',
        targetAudience: 'Youth audiences, families, schools, local communities, and civic partners',
        benefitsOffered: 'Activation booth, field branding, emcee mentions, and community impact storytelling',
      },
    ],
  },
  {
    organizerEmail: 'organizer@meloo.local',
    title: 'Lalitpur Education Innovation Forum',
    description:
      'A forum for educators, edtech builders, training providers, and youth employability partners.',
    categorySlug: 'education',
    location: cityCatalog.lalitpur,
    vendorMatchRadiusKm: 35,
    dayOffset: 14,
    durationHours: 7,
    ticketTypes: [
      ['Forum Pass', '0.00', 240],
      ['Institution Pass', '1500.00', 80],
    ],
    opportunities: [
      {
        title: 'Future Skills Session Sponsor',
        description:
          'Sponsor the main learning track, student networking zone, and practical skilling booths.',
        requiredAmount: '260000.00',
        targetAudience: 'Educators, students, youth programs, and training institutions',
        benefitsOffered: 'Session branding, learning zone presence, and post-event partner visibility',
      },
    ],
  },
  {
    organizerEmail: 'mira.joshi@meloo.local',
    title: 'Butwal Food Supply Chain Meetup',
    description:
      'A compact meetup for food operators, distributors, logistics partners, and regional business owners.',
    categorySlug: 'food-culture',
    location: cityCatalog.butwal,
    vendorMatchRadiusKm: 90,
    dayOffset: 38,
    durationHours: 6,
    ticketTypes: [
      ['Meetup Pass', '0.00', 180],
      ['Buyer Connect Pass', '1300.00', 60],
    ],
    opportunities: [
      {
        title: 'Regional Food Systems Sponsor',
        description:
          'Own the buyer lounge, supply chain panel branding, and tasting-zone co-presence.',
        requiredAmount: '210000.00',
        targetAudience: 'Food operators, distributors, agriculture partners, and logistics buyers',
        benefitsOffered: 'Panel branding, tasting visibility, and buyer lead capture',
      },
    ],
  },
];

const vendorRequestPlans = [
  {
    organizerEmail: 'organizer@meloo.local',
    vendorEmail: 'vendor@meloo.local',
    eventTitle: 'Kathmandu AI & Civic Tech Summit 2026',
    message: 'We need keynote AV, stage transitions, and backstage operator support for the full summit day.',
    proposedBudget: '320000.00',
    directBookingPreferred: false,
    finalStatus: 'booked',
  },
  {
    organizerEmail: 'organizer@meloo.local',
    vendorEmail: 'rekha.tamang@meloo.local',
    eventTitle: 'Lalitpur Education Innovation Forum',
    message: 'Please cover the hybrid stream, panel recording, and remote speaker workflow for the forum.',
    proposedBudget: '190000.00',
    directBookingPreferred: true,
    finalStatus: 'accepted',
  },
  {
    organizerEmail: 'mira.joshi@meloo.local',
    vendorEmail: 'deepak.kunwar@meloo.local',
    eventTitle: 'Pokhara Creator Commerce Fest',
    message: 'We need reels, sponsor booth photography, and event recap assets from morning setup to close.',
    proposedBudget: '135000.00',
    directBookingPreferred: true,
    finalStatus: 'booked',
  },
  {
    organizerEmail: 'bikash.chaudhary@meloo.local',
    vendorEmail: 'sushma.lama@meloo.local',
    eventTitle: 'Biratnagar Industry and Logistics Expo',
    message: 'Can you handle booth fabrication, directional signage, and vendor hall load-in sequencing?',
    proposedBudget: '355000.00',
    directBookingPreferred: false,
    finalStatus: 'accepted',
  },
  {
    organizerEmail: 'anusha.poudel@meloo.local',
    vendorEmail: 'sarita.thapa@meloo.local',
    eventTitle: 'Chitwan Youth Sports and Culture Weekend',
    message: 'We need crowd flow, entry checks, and escalation coverage for the public-facing field program.',
    proposedBudget: '210000.00',
    directBookingPreferred: false,
    finalStatus: 'booked',
  },
  {
    organizerEmail: 'mira.joshi@meloo.local',
    vendorEmail: 'krishna.giri@meloo.local',
    eventTitle: 'Butwal Food Supply Chain Meetup',
    message: 'We need lunch service, tea stations, and VIP host support for speakers and buyers.',
    proposedBudget: '145000.00',
    directBookingPreferred: false,
    finalStatus: 'accepted',
  },
];

const sponsorInterestPlans = [
  ['sponsor.yeti@meloo.local', 'Kathmandu AI & Civic Tech Summit 2026', 'AI Infrastructure Lead Partner', 'We want visibility with AI operators and digital public-service builders in Kathmandu.'],
  ['sponsor.lakeside@meloo.local', 'Pokhara Creator Commerce Fest', 'Lakeside Experience Sponsor', 'This audience fits our tourism and creator-commerce positioning in Pokhara.'],
  ['sponsor.koshi@meloo.local', 'Biratnagar Industry and Logistics Expo', 'Regional Supply Chain Sponsor', 'We want to reach logistics operators, distributors, and trade-floor decision makers.'],
  ['sponsor.himal@meloo.local', 'Lalitpur Education Innovation Forum', 'Future Skills Session Sponsor', 'This fits our youth, education, and skilling investment priorities.'],
];

const attendeeActions = [
  ['attendee@meloo.local', 'Kathmandu AI & Civic Tech Summit 2026', 'Community Pass'],
  ['attendee.pokhara@meloo.local', 'Pokhara Creator Commerce Fest', 'Community Entry'],
  ['attendee.lalitpur@meloo.local', 'Lalitpur Education Innovation Forum', 'Forum Pass'],
  ['attendee.butwal@meloo.local', 'Butwal Food Supply Chain Meetup', 'Meetup Pass'],
  ['attendee.chitwan@meloo.local', 'Chitwan Youth Sports and Culture Weekend', 'Community Access'],
  ['attendee.dharan@meloo.local', 'Biratnagar Industry and Logistics Expo', 'Trade Visitor Pass'],
];

const seededConversations = [
  {
    a: 'organizer@meloo.local',
    b: 'vendor@meloo.local',
    messages: [
      ['a', 'For the Kathmandu summit, can you confirm if your team can handle keynote transitions and rehearsal support the day before?'],
      ['b', 'Yes, we can cover rehearsal support as long as we lock the final run sheet and LED content timeline 72 hours in advance.'],
      ['a', 'Share the crew count and load-in timing you recommend for that venue so we can line it up with security and registration.'],
    ],
  },
  {
    a: 'mira.joshi@meloo.local',
    b: 'deepak.kunwar@meloo.local',
    messages: [
      ['a', 'We need strong sponsor booth imagery and quick reels from the Pokhara creator event. What does your on-site turnaround look like?'],
      ['b', 'We can deliver same-day reels and a next-day photo gallery if we get the sponsor shot list, access windows, and stage timing early.'],
    ],
  },
  {
    a: 'bikash.chaudhary@meloo.local',
    b: 'sushma.lama@meloo.local',
    messages: [
      ['a', 'The Biratnagar expo needs disciplined booth load-in and aisle control. Can your team supervise vendor setup windows?'],
      ['b', 'Yes, but I need the floor plan, utility points, and which exhibitors require early access or heavier fabrication support.'],
    ],
  },
  {
    a: 'anusha.poudel@meloo.local',
    b: 'sarita.thapa@meloo.local',
    messages: [
      ['a', 'We expect family traffic and youth team arrivals at once in Chitwan. What crowd-flow setup do you suggest?'],
      ['b', 'Use separate entry and spectator lanes, then give us a final map so we can assign supervisors and incident routes.'],
    ],
  },
  {
    a: 'organizer@meloo.local',
    b: 'sponsor.yeti@meloo.local',
    messages: [
      ['a', 'The AI summit audience is heavy on operators and product teams. Are you more interested in a keynote presence or a demo corridor activation?'],
      ['b', 'The demo corridor and operator lounge fit us better, especially if we can collect leads and host a short partner briefing.'],
      ['a', 'Send the lead volume you expect and any non-negotiable branding asks so I can shape the package tightly.'],
    ],
  },
  {
    a: 'mira.joshi@meloo.local',
    b: 'sponsor.lakeside@meloo.local',
    messages: [
      ['a', 'We can position your brand at the creator lounge and the commerce stage in Pokhara. Which audience segment matters most to you?'],
      ['b', 'Local businesses moving online and tourism creators are the highest fit for us.'],
    ],
  },
];

const supportTicketPlans = [
  {
    attendeeEmail: 'attendee@meloo.local',
    category: 'payment',
    subject: 'VIP checkout readiness for Kathmandu summit',
    description:
      'Please confirm whether the paid operator pass checkout flow is configured correctly before the summit registration push.',
  },
  {
    attendeeEmail: 'attendee.lalitpur@meloo.local',
    category: 'technical',
    subject: 'Unable to see my registration after refresh',
    description:
      'I registered for the Lalitpur forum but the registrations view looked stale after app refresh. Please confirm the expected behavior.',
  },
  {
    attendeeEmail: 'attendee.chitwan@meloo.local',
    category: 'account',
    subject: 'Need confirmation about verification status',
    description:
      'I signed up successfully and want to confirm if my account is fully active before community event registration opens.',
  },
];

async function main() {
  await mkdir(outputDir, { recursive: true });
  await waitForApi();

  const sessions = new Map();
  for (const user of users) {
    const session = await authenticateUser(user);
    await updateMe(session, user.profile);
    sessions.set(user.email, session);
  }

  const adminSession = sessions.get('admin@meloo.local');
  await activateSeedUsers(adminSession.tokens.accessToken);

  for (const user of users) {
    const session = sessions.get(user.email);
    session.user = await requestJson('/users/me', {
      token: session.tokens.accessToken,
    });
  }

  const categories = await requestJson('/event-categories');
  const categoryBySlug = new Map(categories.map((item) => [item.slug, item]));

  const vendorProfiles = new Map();
  for (const definition of vendorDefinitions) {
    const session = sessions.get(definition.email);
    let vendorProfile = await requestJson('/vendors/me/profile', {
      token: session.tokens.accessToken,
    });
    vendorProfile = await requestJson('/vendors/me/profile', {
      method: 'PATCH',
      token: session.tokens.accessToken,
      body: {
        businessName: definition.businessName,
        description: definition.description,
        category: definition.category,
        serviceArea: definition.serviceArea,
        latitude: definition.location.latitude,
        longitude: definition.location.longitude,
        travelRadiusKm: definition.travelRadiusKm,
      },
    });
    await requestJson('/vendors/me/booking-preference', {
      method: 'PATCH',
      token: session.tokens.accessToken,
      body: {
        allowDirectBooking: definition.allowDirectBooking,
        allowRequestBooking: definition.allowRequestBooking,
      },
    });

    for (const [name, description, basePrice, pricingModel] of definition.services) {
      if (!vendorProfile.services.some((item) => item.name === name)) {
        vendorProfile = await requestJson('/vendors/me/services', {
          method: 'POST',
          token: session.tokens.accessToken,
          body: {
            name,
            description,
            basePrice,
            pricingModel,
          },
        });
      }
    }

    for (const [name, description, price] of definition.packages) {
      if (!vendorProfile.packages.some((item) => item.name === name)) {
        vendorProfile = await requestJson('/vendors/me/packages', {
          method: 'POST',
          token: session.tokens.accessToken,
          body: {
            name,
            description,
            price,
          },
        });
      }
    }

    await verifyProfileIfNeeded(
      adminSession.tokens.accessToken,
      '/admin/vendors/pending',
      `/admin/vendors/${vendorProfile.id}/verify`,
      vendorProfile.id,
    );

    vendorProfiles.set(definition.email, await requestJson('/vendors/me/profile', {
      token: session.tokens.accessToken,
    }));
  }

  const sponsorProfiles = new Map();
  for (const definition of sponsorDefinitions) {
    const session = sessions.get(definition.email);
    let sponsorProfile = await requestJson('/sponsors/me/profile', {
      token: session.tokens.accessToken,
    });
    sponsorProfile = await requestJson('/sponsors/me/profile', {
      method: 'PATCH',
      token: session.tokens.accessToken,
      body: {
        companyName: definition.companyName,
        description: definition.description,
        industries: definition.industries,
        websiteUrl: definition.websiteUrl,
      },
    });

    await verifyProfileIfNeeded(
      adminSession.tokens.accessToken,
      '/admin/sponsors/pending',
      `/admin/sponsors/${sponsorProfile.id}/verify`,
      sponsorProfile.id,
    );

    sponsorProfiles.set(definition.email, await requestJson('/sponsors/me/profile', {
      token: session.tokens.accessToken,
    }));
  }

  const eventsByTitle = new Map();
  const opportunitiesByTitle = new Map();

  for (const definition of eventDefinitions) {
    const session = sessions.get(definition.organizerEmail);
    const organizerEvents = await requestJson('/events/my', {
      token: session.tokens.accessToken,
    });
    const existing =
      organizerEvents.find((item) => item.title === definition.title) ?? null;
    const category = categoryBySlug.get(definition.categorySlug) ?? categories[0];
    const event =
      existing ??
      (await requestJson('/events', {
        method: 'POST',
        token: session.tokens.accessToken,
        body: {
          title: definition.title,
          description: definition.description,
          categoryId: category.id,
          venue: definition.location.venue,
          city: definition.location.city,
          latitude: definition.location.latitude,
          longitude: definition.location.longitude,
          vendorMatchRadiusKm: definition.vendorMatchRadiusKm,
          startAt: buildDate(definition.dayOffset, 10),
          endAt: buildDate(definition.dayOffset, 10 + definition.durationHours),
          status: 'published',
          visibility: 'public',
        },
      }));

    eventsByTitle.set(definition.title, event);

    let ticketTypes = await requestJson(`/events/${event.id}/ticket-types/manage`, {
      token: session.tokens.accessToken,
    });
    for (const [name, price, quantity] of definition.ticketTypes) {
      const existingTicketType = ticketTypes.find((item) => item.name === name) ?? null;
      const saleStartAt = buildDate(Math.min(-2, definition.dayOffset - 20), 9);
      const saleEndAt = buildDate(definition.dayOffset - 1, 23);
      if (existingTicketType == null) {
        await requestJson(`/events/${event.id}/ticket-types`, {
          method: 'POST',
          token: session.tokens.accessToken,
          body: {
            name,
            price,
            quantity,
            saleStartAt,
            saleEndAt,
          },
        });
      } else {
        await requestJson(`/ticket-types/${existingTicketType.id}`, {
          method: 'PATCH',
          token: session.tokens.accessToken,
          body: {
            price,
            quantity,
            saleStartAt,
            saleEndAt,
          },
        });
      }
      if (existingTicketType == null) {
        ticketTypes = await requestJson(`/events/${event.id}/ticket-types/manage`, {
          token: session.tokens.accessToken,
        });
      }
    }

    let organizerOpportunities = await requestJson('/sponsorship-opportunities/my', {
      token: session.tokens.accessToken,
    });
    for (const opportunityDefinition of definition.opportunities) {
      let opportunity =
        organizerOpportunities.find((item) => item.title === opportunityDefinition.title) ??
        null;
      if (opportunity == null) {
        opportunity = await requestJson(`/events/${event.id}/sponsorship-opportunities`, {
          method: 'POST',
          token: session.tokens.accessToken,
          body: {
            ...opportunityDefinition,
            status: 'open',
          },
        });
        organizerOpportunities = await requestJson('/sponsorship-opportunities/my', {
          token: session.tokens.accessToken,
        });
      }
      opportunitiesByTitle.set(opportunityDefinition.title, opportunity);
    }
  }

  for (const [sponsorEmail, eventTitle, opportunityTitle, message] of sponsorInterestPlans) {
    const session = sessions.get(sponsorEmail);
    const opportunity = opportunitiesByTitle.get(opportunityTitle);
    const interests = await requestJson('/sponsorship-interests/my', {
      token: session.tokens.accessToken,
    });
    if (!interests.some((item) => item.opportunity.id === opportunity.id)) {
      await requestJson(`/sponsorship-opportunities/${opportunity.id}/interests`, {
        method: 'POST',
        token: session.tokens.accessToken,
        body: { message },
      });
    }
  }

  const vendorRequestsByKey = new Map();
  for (const plan of vendorRequestPlans) {
    const organizerSession = sessions.get(plan.organizerEmail);
    const vendorSession = sessions.get(plan.vendorEmail);
    const vendorProfile = vendorProfiles.get(plan.vendorEmail);
    const event = eventsByTitle.get(plan.eventTitle);
    let requests = await requestJson('/vendors/requests/my-organizer', {
      token: organizerSession.tokens.accessToken,
    });
    let vendorRequest =
      requests.find(
        (item) => item.event.id === event.id && item.vendor.id === vendorProfile.id,
      ) ?? null;

    if (vendorRequest == null) {
      vendorRequest = await requestJson(`/vendors/${vendorProfile.id}/requests`, {
        method: 'POST',
        token: organizerSession.tokens.accessToken,
        body: {
          eventId: event.id,
          message: plan.message,
          proposedBudget: plan.proposedBudget,
          directBookingPreferred: plan.directBookingPreferred,
        },
      });
    }

    if (
      (plan.finalStatus === 'accepted' || plan.finalStatus === 'booked') &&
      vendorRequest.status === 'pending'
    ) {
      vendorRequest = await requestJson(`/vendors/requests/${vendorRequest.id}/respond`, {
        method: 'PATCH',
        token: vendorSession.tokens.accessToken,
        body: { status: 'accepted' },
      });
    }

    if (plan.finalStatus === 'booked' && vendorRequest.status === 'accepted') {
      vendorRequest = await requestJson(`/vendors/requests/${vendorRequest.id}/book`, {
        method: 'PATCH',
        token: organizerSession.tokens.accessToken,
      });
    }

    vendorRequestsByKey.set(
      `${plan.eventTitle}:${plan.vendorEmail}`,
      vendorRequest,
    );
  }

  const conversations = [];
  for (const plan of seededConversations) {
    const conversation = await ensureConversation(
      sessions.get(plan.a),
      sessions.get(plan.b),
      plan.messages,
    );
    conversations.push({
      participants: [plan.a, plan.b],
      conversationId: conversation.id,
    });
  }

  for (const [attendeeEmail, eventTitle, ticketName] of attendeeActions) {
    const session = sessions.get(attendeeEmail);
    const event = eventsByTitle.get(eventTitle);
    await requestJson(`/events/${event.id}/favorite`, {
      method: 'POST',
      token: session.tokens.accessToken,
    });
    await requestJson(`/events/${event.id}/view`, {
      method: 'POST',
      token: session.tokens.accessToken,
    });

    const ticketTypes = await requestJson(`/events/${event.id}/ticket-types`, {
      token: session.tokens.accessToken,
    });
    const ticketType = ticketTypes.find((item) => item.name === ticketName);
    const registrations = await requestJson('/registrations/my', {
      token: session.tokens.accessToken,
    });
    if (!registrations.some((item) => item.ticketType.id === ticketType.id)) {
      await requestJson(`/events/${event.id}/registrations`, {
        method: 'POST',
        token: session.tokens.accessToken,
        body: {
          ticketTypeId: ticketType.id,
          quantity: 1,
        },
      });
    }
  }

  const supportTickets = [];
  for (const plan of supportTicketPlans) {
    const attendeeSession = sessions.get(plan.attendeeEmail);
    let tickets = await requestJson('/support/tickets/my', {
      token: attendeeSession.tokens.accessToken,
    });
    let ticket = tickets.find((item) => item.subject === plan.subject) ?? null;
    if (ticket == null) {
      ticket = await requestJson('/support/tickets', {
        method: 'POST',
        token: attendeeSession.tokens.accessToken,
        body: {
          category: plan.category,
          subject: plan.subject,
          description: plan.description,
        },
      });
    }
    if (ticket.status !== 'resolved') {
      await requestJson(`/admin/support/tickets/${ticket.id}/assign`, {
        method: 'PATCH',
        token: adminSession.tokens.accessToken,
      });
      await requestJson(`/admin/support/tickets/${ticket.id}/resolve`, {
        method: 'PATCH',
        token: adminSession.tokens.accessToken,
      });
    }
    supportTickets.push(ticket);
  }

  const output = {
    seedVersion: 2,
    generatedAt: new Date().toISOString(),
    apiBaseUrl,
    accounts: users.reduce((accumulator, user) => {
      if (!accumulator[user.role]) {
        accumulator[user.role] = [];
      }
      accumulator[user.role].push({
        email: user.email,
        password: user.password,
        fullName: user.profile.fullName,
      });
      return accumulator;
    }, {}),
    events: Array.from(eventsByTitle.values()).map((event) => ({
      id: event.id,
      title: event.title,
      city: event.city,
    })),
    opportunities: Array.from(opportunitiesByTitle.values()).map((opportunity) => ({
      id: opportunity.id,
      title: opportunity.title,
    })),
    vendors: Array.from(vendorProfiles.values()).map((vendor) => ({
      id: vendor.id,
      businessName: vendor.businessName,
      city: vendor.serviceArea,
    })),
    vendorRequests: Array.from(vendorRequestsByKey.values()).map((request) => ({
      id: request.id,
      status: request.status,
      eventTitle: request.event.title,
      vendorBusinessName: request.vendor.businessName,
    })),
    conversations,
    supportTickets: supportTickets.map((ticket) => ({
      id: ticket.id,
      subject: ticket.subject,
      status: ticket.status,
    })),
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
        'x-setup-key': process.env.LOCAL_SETUP_KEY ?? 'change-this-local-setup-key',
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

async function activateSeedUsers(adminToken) {
  const adminUsers = await requestJson('/admin/users', { token: adminToken });
  for (const user of adminUsers) {
    if (user.role !== 'admin' && user.status !== 'active') {
      await requestJson(`/admin/users/${user.id}/status`, {
        method: 'PATCH',
        token: adminToken,
        body: { status: 'active' },
      });
    }
  }
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

async function ensureConversation(sessionA, sessionB, seedMessages) {
  const conversation = await requestJson('/chat/conversations/direct', {
    method: 'POST',
    token: sessionA.tokens.accessToken,
    body: {
      participantUserId: sessionB.user.id,
    },
  });

  const existingMessages = await requestJson(
    `/chat/conversations/${conversation.id}/messages`,
    {
      token: sessionA.tokens.accessToken,
    },
  );

  for (const [senderLabel, body] of seedMessages) {
    if (existingMessages.some((message) => message.body === body)) {
      continue;
    }
    const token =
      senderLabel === 'a' ? sessionA.tokens.accessToken : sessionB.tokens.accessToken;
    await requestJson(`/chat/conversations/${conversation.id}/messages`, {
      method: 'POST',
      token,
      body: { body },
    });
  }

  return conversation;
}

function buildDate(dayOffset, hour) {
  const date = new Date();
  date.setUTCMinutes(0, 0, 0);
  date.setUTCHours(hour, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() + dayOffset);
  return date.toISOString();
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
