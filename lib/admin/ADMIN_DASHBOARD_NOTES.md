# Admin dashboard implementation notes

## Increment 1: Responsive overview and metrics

The dashboard follows the supplied `sarthi_admin_dashboard.html` reference for
its green SARTHI branding, left navigation, compact summary cards, and responsive
operations panels. Its sample numbers, simulated controls, decorative map, and
pretend fleet or activity entries were not carried over.

### Connected data

The dashboard reads the existing Firestore collections with aggregate counts
where possible. A failed or unauthorized count is displayed as unavailable.

| Dashboard label | Source | Meaning |
| --- | --- | --- |
| Student accounts | `users`, filtered by `role == student` | Registered student profiles |
| Active bus records | `buses`, filtered by `isActive == true` | Bus documents marked active |
| Active ride requests | `rides`, statuses `pending`, `accepted`, `in_progress` | Matches the current `RideRequest.isActive` model |
| Location records | `locations` | Location documents only; this is not a verified fleet count |

Each metric uses a Firestore aggregate count. A failed or unauthorized count is
displayed as unavailable instead of zero.

## Increment 2: Bounded operations panels

Recent rides are limited to five documents ordered by `createdAt`. The location
panel is limited to five documents and shows their stored status and timestamp.
It does not claim that a timestamp or position is current GPS.

Both panels have loading, empty, and read-error states.

## Increment 3: Management availability and session behavior

### Navigation status

- **Students:** Opens the existing `StudentManagementScreen`.
- **EV Cart Fleet, Bus Schedules, Rides & Bookings, Drivers:** Clearly marked as
  unavailable until an admin management screen exists.

Logout continues through Firebase Authentication and returns to the app's `/`
home route. Admin authorization remains in `AdminAuthService`.

### Follow-up dependencies

- A dedicated fleet registry is needed before reporting total carts or fleet
  availability.
- Reliable location freshness needs a defined update interval and trusted
  location source.
- Ride status naming should be aligned between the current model and roadmap
  before more detailed activity or lifecycle reporting is added.
- Firestore rules must permit the authorized admin account to read each
  dashboard collection; this change does not modify security rules.
