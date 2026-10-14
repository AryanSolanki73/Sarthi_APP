# SARTHI — Campus Mobility App

## Project Plan, Team Responsibilities & Development Roadmap

**Frontend:** Flutter / Dart  
**Backend:** Firebase Authentication, Cloud Firestore, Firebase Realtime Database, and optionally Cloud Functions  
**Team size:** 4 members  
**Suggested timeline:** 6 weeks (adjust to your actual deadline)

> **Goal:** Build one campus app where students can request an EV cart and view campus bus locations. Deliver a small, secure end-to-end prototype before adding advanced features.

---

## 1. Product Scope

SARTHI combines two campus transportation services in one Flutter app.

### A. EV Cart Booking

- Students choose pickup and drop-off points and request an available electric cart.
- A driver accepts the request, arrives at pickup, starts the ride, and marks it completed.
- Students see booking status and, when available, the cart's live location.
- Ride status lifecycle: `requested` → `accepted` → `arriving` → `ongoing` → `completed`; handle cancellation explicitly.
- Prevent the same cart from being assigned to more than one active ride.

### B. Campus Bus Tracking

- Students browse campus buses, routes, and stops.
- A map displays the bus's latest GPS position and last-updated time.
- Show the next stop and approximate ETA only when route and location data are reliable.
- A driver phone can send GPS updates; simulated coordinates can be used during early development.

### C. Shared Features

- Student and driver login, profile, logout, and role-aware navigation.
- Basic admin flow to manage routes, buses, carts, and drivers.
- Notifications for booking updates can be added after core workflows work.
- Loading, error, empty, and offline states.

**MVP scope recommendation:** Build the student app first, then driver mode and a basic admin interface. Leave payments, ratings, complex ETA prediction, and advanced analytics for later.

---

## 2. Four-Member Responsibility Split

Each person owns a module from UI through testing. Agree on database fields and service interfaces before parallel development starts.

### Member 1 — Student App & UI

**Owns:** Student-facing screens and navigation.

- Login/signup UI and role-aware navigation.
- Home screen with EV booking and bus tracking.
- Pickup/drop selection and route selection screens.
- Profile, booking history, and reusable UI widgets.
- Integrate the other members' features into the main app.

**Deliverable:** A consistent student-facing app with working navigation and connected screens.

### Member 2 — EV Cart Booking

**Owns:** The complete cart-booking workflow.

- Create and cancel ride requests.
- Manage cart availability and driver acceptance/rejection.
- Driver mode: accept ride, arrive at pickup, start ride, and complete ride.
- Display ride status to the student.
- Prevent a cart from being assigned to two active rides.

**Deliverable:** A student can book a cart and follow the ride from request to completion.

### Member 3 — Live Bus Tracking

**Owns:** Bus location and route visualization.

- Bus list, route, and stop screens.
- Read and display live GPS coordinates from Firebase.
- Integrate a map provider such as Google Maps.
- Show bus markers, next stop, and approximate ETA where data supports it.
- Build the driver-side location-sharing screen or simulator.

**Deliverable:** Students can select a bus and see its location update on a map.

### Member 4 — Firebase & Integration

**Owns:** Shared backend foundation and security.

- Firebase project setup and Flutter configuration.
- Firebase Authentication and protected user roles.
- Cloud Firestore data models for users, buses, carts, routes, and bookings.
- Realtime Database for live GPS and active ride updates.
- Firebase Security Rules, indexes, and test data.
- Coordinate database interfaces and help integrate both modules.

**Deliverable:** All modules use the same secure, consistent backend.

> This is a substantial role. Each feature owner should test their own Firebase reads and writes so Member 4 does not become the only person able to debug the backend.

### Shared Team Rules

- Every member writes and tests their own module.
- Member 1 should integrate working pieces throughout development, not only at the end.
- Agree on model fields and service method signatures before coding in parallel.
- Use separate Git feature branches and merge small changes regularly.
- Avoid having multiple people edit `main.dart` at once.

---

## 3. Flutter + Firebase Architecture

Flutter is the client app. Firebase services handle identity, persistent app data, and rapidly changing vehicle locations.

| Service | Purpose | Example use |
|---|---|---|
| Firebase Authentication | Identity and sign-in | Email/password login and user UID |
| Cloud Firestore | Structured application data | Users, routes, buses, carts, bookings, and history |
| Firebase Realtime Database | Frequent live updates | Current vehicle GPS and active ride state |
| Cloud Functions (recommended) | Trusted backend validation | Validate availability and assign a cart safely |
| Maps provider | Map display | Map tiles and vehicle markers |

### Suggested Firestore Collections

| Collection | Example fields |
|---|---|
| `users/{uid}` | `name`, `email`, `role`, `createdAt` |
| `buses/{busId}` | `routeId`, `driverId`, `active`, `displayName` |
| `routes/{routeId}` | `name`, `stops`, route metadata |
| `carts/{cartId}` | `driverId`, `status` |
| `bookings/{bookingId}` | `studentId`, `cartId`, `pickup`, `drop`, `status`, `createdAt` |

### Suggested Realtime Database Paths

```json
{
  "busLocations": {
    "bus_01": {
      "lat": 30.516,
      "lng": 76.659,
      "updatedAt": 1791900000000
    }
  },
  "cartLocations": {
    "cart_01": {
      "lat": 30.517,
      "lng": 76.660,
      "updatedAt": 1791900000000
    }
  },
  "activeRides": {
    "ride_01": {
      "status": "accepted",
      "driverId": "driver_01"
    }
  }
}
```

*The coordinates above are illustrative, not actual campus locations.*

### Firebase Authentication and Roles

Authentication manages sign-in and identity. It does not automatically establish whether someone is a student, driver, or administrator.

- Store role information in protected data.
- Enforce permissions through Security Rules and trusted backend logic.
- Do not trust a role supplied by the client.
- Restrict drivers to their assigned vehicles and rides.
- Students should only access bookings they are authorized to view.

### Security and Privacy Essentials

- Only share live location while a vehicle is on duty or a ride is active.
- Validate location timestamps and handle stale GPS data.
- Never commit service-account keys or other secrets to GitHub.
- Restrict and secure any maps API key.
- Use trusted backend logic to prevent two students from booking the same cart simultaneously.

Firebase is not a traditional relational database. Firestore and Realtime Database can work together without adding SQL or a separate database server.

---

## 4. Recommended Flutter File Structure

Use a feature-based structure so team members can work mostly inside their assigned feature. Keep your existing project and add folders gradually; do not create every file before you need it.

```text
sarthi/
├── android/                         # Android configuration
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── lib/
│   ├── main.dart                    # Entry point; initialize Firebase
│   ├── app.dart                     # MaterialApp, theme, and routes
│   ├── firebase_options.dart        # Generated by FlutterFire
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── firebase_paths.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── routing/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       └── validators.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── booking_model.dart
│   │   ├── cart_model.dart
│   │   ├── bus_model.dart
│   │   └── route_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── realtime_location_service.dart
│   │   ├── location_service.dart
│   │   └── notification_service.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   └── widgets/
│   │   ├── home/
│   │   │   └── screens/
│   │   │       └── home_screen.dart
│   │   ├── cart_booking/
│   │   │   ├── screens/
│   │   │   │   ├── booking_screen.dart
│   │   │   │   └── ride_tracking_screen.dart
│   │   │   ├── widgets/
│   │   │   └── data/
│   │   │       └── booking_repository.dart
│   │   ├── bus_tracking/
│   │   │   ├── screens/
│   │   │   │   ├── bus_list_screen.dart
│   │   │   │   └── bus_map_screen.dart
│   │   │   ├── widgets/
│   │   │   └── data/
│   │   │       └── bus_repository.dart
│   │   ├── driver/
│   │   │   └── screens/
│   │   │       ├── driver_home_screen.dart
│   │   │       └── active_ride_screen.dart
│   │   ├── admin/
│   │   │   └── screens/
│   │   └── profile/
│   │       └── screens/
│   │           └── profile_screen.dart
│   └── shared/
│       └── widgets/
│           ├── loading_widget.dart
│           ├── error_widget.dart
│           └── empty_state_widget.dart
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### File Ownership by Member

| Member | Primary files/folders |
|---|---|
| Member 1 — Student UI | `features/auth/screens/` UI, `features/home/`, `features/profile/`, `shared/widgets/`; coordinate authentication logic with Member 4 |
| Member 2 — Cart booking | `features/cart_booking/`, driver ride screens, `booking_model.dart` (agree fields with Member 4) |
| Member 3 — Bus tracking | `features/bus_tracking/`, bus/route UI and location display |
| Member 4 — Firebase | `services/`, `core/constants/firebase_paths.dart`, Firebase configuration and Security Rules |

**Start with only:** `main.dart`, `app.dart`, your existing login screen, `auth_service.dart`, `user_model.dart`, and Firebase setup. Add booking and bus files when those features begin.

---

## 5. Six-Week Development Timeline

| Week | Main work | Exit criteria |
|---|---|---|
| **Week 1 — Plan** | Requirements, wireframes, GitHub, Firebase setup, agree data schema and interfaces | App launches; Firebase initializes; schema agreed |
| **Week 2 — Foundation** | Authentication, roles, navigation, home screen, sample data | User can sign in and reach the correct screen |
| **Week 3 — Core build** | Cart request and driver acceptance; GPS sender/simulator and map marker | Booking status changes; test vehicle appears on map |
| **Week 4 — Complete** | Ride lifecycle, route/stop screens, live streams, history, basic admin | Both services work end-to-end on Firebase |
| **Week 5 — Test** | Multi-device testing, permissions, duplicate booking, GPS interruption, offline recovery | Critical bugs fixed; rules reviewed |
| **Week 6 — Submit** | APK, demo data, report, screenshots, architecture diagram, demo practice | Repeatable demo and submission package ready |

If your deadline is shorter, preserve the order but reduce scope. Use seeded routes, simulated vehicle GPS, and a basic admin workflow before adding advanced ETA or notifications.

---

## 6. Firebase Setup Commands

Run these from the Flutter project root (the folder containing `pubspec.yaml`). If the app is already connected to Firebase, verify the current project instead of creating a duplicate one.

### Add Firebase packages

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_database
```

### Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Install the Firebase CLI separately, then log in and configure:

```bash
firebase login
flutterfire configure
flutter run
```

`flutterfire configure` should generate `lib/firebase_options.dart`.

### Initialize Firebase Before `runApp()`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

Keep your existing root widget name if it is not `MyApp`.

In Firebase Console, enable **Authentication → Sign-in method → Email/Password**. Register the Android app using its actual application ID.

---

## 7. MVP Acceptance Checklist

A screen is not complete until its behavior is tested with Firebase and, where relevant, multiple accounts or devices.

- [ ] **Foundation:** App starts and Firebase initializes without errors.
- [ ] **Authentication:** Signup, login, logout, and invalid-credential handling work.
- [ ] **Roles:** Student/driver/admin access is protected; users cannot grant themselves privileged roles.
- [ ] **Cart booking:** Student requests a cart; driver accepts; status updates for the student.
- [ ] **Availability:** A cart cannot be assigned to two active bookings simultaneously.
- [ ] **Bus tracking:** Selected bus marker updates when new GPS coordinates arrive.
- [ ] **Freshness:** UI handles stale or missing GPS rather than implying it is live.
- [ ] **Permissions:** A student cannot access another student's private booking or driver-only data.
- [ ] **Recovery:** Loading, empty, error, offline, and reconnect states are tested.
- [ ] **Submission:** APK, demo steps, report, architecture diagram, and test data are ready.

---

## 8. First Demo Flow

1. Student signs in and opens the SARTHI home screen.
2. Student requests an EV cart; driver accepts; status updates on the student screen.
3. Student opens bus tracking and sees a bus marker move as test GPS data updates.
4. A permission test shows that one student cannot read another student's private booking.

> **Definition of success:** one complete cart-booking flow, one bus-tracking flow, secure Firebase access, and a repeatable demonstration.

---

## Official References

- [Firebase setup for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Firebase Authentication for Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Realtime Database for Flutter](https://firebase.google.com/docs/database/flutter/start)
