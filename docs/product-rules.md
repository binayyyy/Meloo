# Meloo Product Rules

This document locks the current product rules before further hardening, redesign, and workflow completion.

## Identity And Access

- One account maps to exactly one public role.
- Public roles are `attendee`, `organizer`, `vendor`, and `sponsor`.
- `admin` is internal-only and separate from normal sign-up.
- No public sign-up path may create an admin account.

## Admin Model

- Admin access stays separate from organizer access.
- Organizers do not automatically inherit internal admin dashboard access.
- Admin is responsible for internal moderation, optional verification review, platform support oversight, and taxonomy management.

## Event Visibility

- Organizers choose visibility when publishing an event.
- Visibility must support at least public and private modes.
- Private events may be selectively shared according to organizer intent.
- Sponsor-targeted private event outreach is allowed.

## Vendor Workflow

- The platform acts as a mediator, not the fulfillment party.
- Vendors can respond to organizer demand.
- Organizer-to-vendor direct booking should be supported as a real workflow, not only application-based matching.
- Vendor commitments happen between the parties; the platform records intent and workflow state.

## Sponsor Workflow

- Sponsor commitments are agreements between organizer and sponsor.
- The platform mediates discovery, expression of interest, and workflow coordination.
- Private sponsor outreach is allowed for organizer-controlled opportunities.

## Payments

- Stripe is the target real provider.
- Real payment implementation is deferred for now.
- Current phase should keep payment architecture compatible with later Stripe hardening without making it a delivery blocker.

## Geography And Matching

- Matching should use `city + lat/lng + radius`.
- Radius-aware discovery is part of the core product behavior.
- City labels remain important for browsing and presentation.

## AI Runtime

- Local AI target is `Ollama + llama3.1`.
- AI should assist with planning and support responses.
- Organizer support workflows should allow AI-assisted reply drafting.

## Verification

- Verification is optional.
- Verified profiles should show a platform-verified badge/checkmark.
- Unverified profiles remain visible without that mark.

## Uploads

- Real file uploads are required.
- Upload support must cover event banners, vendor portfolio images, sponsor logos, verification files, and user profile photos.

## Chat And Support

- Chat is allowed between users with public profiles who are allowed to discover each other.
- Organizer-vendor chat is allowed.
- Organizer-sponsor chat is allowed when those profiles are part of a valid discovery or opportunity flow.
- Attendees can chat with other attendees.
- Attendees should not directly chat organizers for support; they create support tickets instead.
- Organizer accounts need a support tickets section.

## Ticketing

- Paid ticketing is not the current delivery priority.
- MVP support for registration and reservation can continue while the product is hardened.

## Phase 1 Delivery Focus

- First priority in this phase is UI redesign.
- Redesign should not strip working features already present in mobile, admin, or API.
- Performance optimization is secondary to making the requested features real and usable.

## Immediate Implementation Implications

- Keep a consistent Meloo identity across mobile, admin, and public touchpoints.
- Redesign the admin web console as the reference visual system for the product.
- Bring the mobile auth surface into the same brand direction next.
- After the redesign pass, harden real uploads, profile/settings coverage, event workflow completeness, and support tooling in that order.
