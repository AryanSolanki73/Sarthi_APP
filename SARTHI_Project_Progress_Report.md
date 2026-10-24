# SARTHI — Project Progress & Git Commit Tracking Report

**Project:** SARTHI Campus Mobility Application  
**Repository:** `AryanSolanki73/Sarthi_APP`  
**Generated Date:** October 23, 2026  
**Tech Stack:** Flutter / Dart, Firebase Auth & Firestore, OpenStreetMap & Carto Tiles, OSRM Routing Engine  

---

## Executive Summary

The **SARTHI** application is an integrated campus mobility solution developed for the IIT Ropar community. It unifies on-demand electric vehicle (EV) cart hailing and scheduled inter-campus bus tracking into a single unified mobile platform, supplemented by a dedicated administration web portal.

Since the initial repository bootstrap on **October 11, 2026**, the development team has executed **39 commits** across 4 primary contributors, successfully completing the core foundation:
1. **End-to-End Authentication**: Email/Password, Auto-Login with encrypted credential persistence, Google OAuth sign-in with SHA-1/SHA-256 bindings, and animated Splash Screen.
2. **User Profile System**: Institutional profile display (`@iitrpr.ac.in`), role badge indicators, and account management.
3. **EV Cart Booking & Fleet Navigation**: Ride request lifecycle (`REQUESTED` → `ACCEPTED` → `ARRIVING` → `ONGOING` → `COMPLETED`), interactive pickup/drop-off point selection, and seat availability tracking.
4. **Interactive Campus Mapping & Routing**: OpenStreetMap / Carto Vector Tiles integration with custom Flutter Map, live vehicle GPS markers, and dynamic OSRM road polyline decoding.
5. **Admin Web Management Portal**: Standalone web entry point (`main_admin.dart`), admin authentication service, and role-based access control (RBAC).

---

## 1. Collaborator Directory & Module Ownership

| Collaborator | Git Username / Email | Primary Role & Module Ownership | Total Commits |
| :--- | :--- | :--- | :---: |
| **Deepak** | `2026csm1012-arch` / `Deepak`<br>`<2026csm1012@iitrpr.ac.in>` | **Lead Architecture, Backend Integration & GIS Mapping**<br>• Repo bootstrap & Flutter cross-platform config<br>• Firebase configuration & OAuth SHA keys binding<br>• Animated Splash Screen & User Profile system<br>• Campus Map & OSRM Polyline Routing Engine<br>• Multi-branch merge management & restructuring | **26** |
| **Aryan Solanki** | `AryanSolanki73`<br>`<2026csm1008@iitrpr.ac.in>` | **Student App & Core UI / Transit Experience**<br>• Core App navigation and controller wiring (`transit_controller`)<br>• Sarthi Brand Identity, Logo, and Student Transit UI<br>• Bus schedule cards, active booking modals & cart cards<br>• Google Authentication Android integration & configs | **6** |
| **Kunal Saini** | `Kunal-Saini89`<br>`<2026csm1022@iitrpr.ac.in>` | **Authentication Systems & Project Roadmap**<br>• Comprehensive Team Roadmap & Sprints specification<br>• Secure Token & Credential Storage (`credential_storage.dart`)<br>• Automated Auto-Login lifecycle & state listeners<br>• Google Sign-In initial setup & vector UI assets | **8** |
| **Ajay Dhiman** | `Ajay`<br>`<ajju.dhimann@gmail.com>` | **Administration Web Portal & RBAC Security**<br>• Dedicated Admin portal (`lib/admin/main_admin.dart`)<br>• Admin login UI with responsive web layout<br>• Admin Authorization & Role verification service<br>• Web build configuration & Gradle adjustments | **3** |

---

## 2. Detailed Collaborator Contributions

### 1. Deepak (`2026csm1012-arch` / `Deepak`)
- **Initial Repository Setup & Project Structure (`f0b1d56`):**
  - Bootstrapped the Flutter project supporting Android, iOS, and Web targets with initial Gradle, analysis options, and build targets.
- **Firebase Infrastructure & Options (`be92960`):**
  - Configured Firebase Core and generated `lib/firebase_options.dart` across Android and Web platforms.
- **Splash Screen & Startup Lifecycle (`7c8291a`):**
  - Built `lib/views/splash_screen.dart` with custom fade/scale animations, branding, and automatic session restoration checks.
- **User Profile Management (`28865b8`):**
  - Created `lib/models/user_profile.dart` and `lib/views/profile_page.dart` featuring user status, quick actions, settings, and secure sign-out.
- **Security & Google OAuth Integration (`87e6207`):**
  - Bound SHA-1 and SHA-256 certificate fingerprints inside `android/app/google-services.json` to enable native Google OAuth login on real Android devices.
- **Campus Mapping & OSRM Real-Time Routing (`b577cfc`, `1602002`):**
  - Engineered `lib/services/routing_service.dart` featuring Open Source Routing Machine (OSRM) HTTP integration and polyline decoding to calculate real road paths between campus landmarks.
  - Implemented `lib/models/cart_location.dart` and significantly upgraded `lib/views/transit/campus_map_view.dart` with Carto/OpenStreetMap tiles, location pickers, live vehicle markers, route layer rendering, and clear route bounds fitting.
  - Overhauled `transit_service.dart` and `transit_controller.dart` to support full EV ride and bus tracking states.

### 2. Aryan Solanki (`AryanSolanki73`)
- **Initial Auth & Presentation Scaffolding (`ca19018`):**
  - Designed the initial authentication view (`lib/views/auth/login_page.dart`), `AuthController`, and `UserModel`.
- **Architectural Overhaul & Transit Foundation (`7852016`):**
  - Integrated full transit models (`Bus`, `Ticket`, `RideRequest`), controllers (`TransitController`), and initial Transit Home & Campus Map views.
  - Added centralized color palette (`lib/core/app_colors.dart`) and core application shell (`lib/app.dart`).
- **Sarthi Brand Identity & Transit UI Refinement (`7633d45`):**
  - Redesigned `transit_home_view.dart` into an interactive student dashboard featuring custom Sarthi branding, vehicle selection cards, status indicators, and quick action chips.
- **Google Authentication Stabilization (`43183e8`):**
  - Configured Android build gradle and updated `google-services.json` to resolve OAuth client credential mismatches.

### 3. Kunal Saini (`Kunal-Saini89`)
- **Project Roadmap & Specification Documentation (`9e0f4a9`):**
  - Authored `SARTHI_Project_Plan_and_Team_Roadmap.md`, defining a 6-week roadmap, 4-member responsibility split, database schema, and test strategies.
- **Credential Storage & Auto-Login Architecture (`9e0f4a9`, `53e77f6`, `7701c93`, `60cea30`, `b6e1d2b`):**
  - Implemented `lib/services/credential_storage.dart` for local session caching.
  - Built auto-login verification pipeline inside `app.dart` and `auth_service.dart` allowing users to bypass login screens on app relaunch.
- **Google Authentication Integration (`8acd615`):**
  - Added Google Sign-In dependency and created `lib/views/widgets/google_logo_icon.dart` for polished third-party authentication buttons.

### 4. Ajay Dhiman (`Ajay`)
- **Admin Web Portal Architecture (`134cebe`):**
  - Created dedicated admin application entry point in `lib/admin/main_admin.dart` for campus transport managers.
  - Built responsive `admin_login_screen.dart` with modern styling and authentication controls.
- **Admin Role Verification & Authorization (`4bca2b6` on `ajju` branch):**
  - Implemented `lib/admin/auth/admin_auth_service.dart` with role verification logic to ensure only users with verified administrative roles access fleet controls.
- **Build & Platform Configurations (`5d32c29`):**
  - Fine-tuned Android Gradle properties for smooth cross-compilation.

---

## 3. Chronological Commit-Wise Progress Log

Below is the complete chronological audit of all commits in the repository history:

```
[2026-10-11] -------------------------------------------------------------
f0b1d56 | 2026csm1012-arch | first commit
  - Initialized Flutter codebase with Android, iOS, and Web scaffolding.
  - Added base configuration files (.gitignore, analysis_options.yaml, pubspec.yaml).

03e5958 | Kunal-Saini89 | Testing 1st push
  - Verified remote repository synchronization and updated README.

ca19018 | AryanSolanki73 | auth page
  - Created initial AuthController, UserModel, and basic LoginPage UI.

d755c50 | AryanSolanki73 | Merge branch 'main' of .../Sarthi_APP
  - Synchronized remote main branch into local development branch.

[2026-10-14] -------------------------------------------------------------
7852016 | AryanSolanki73 | Overwrite remote repository with local code
  - Introduced core transit models: Bus, RideRequest, Ticket.
  - Added TransitController and TransitService.
  - Added TransitHomeView, CampusMapView, SignUpPage, and core color tokens.

9e0f4a9 | Kunal-Saini89 | hohoho
  - Added SARTHI_Project_Plan_and_Team_Roadmap.md (374-line comprehensive roadmap).
  - Implemented CredentialStorage service and updated login flow.

be92960 | 2026csm1012-arch | firebase
  - Initialized Firebase Flutter configurations and generated firebase_options.dart.
  - Configured Android settings.gradle and app-level plugins.

6ffffbd | 2026csm1012-arch | merge
  - Merged remote updates into local branch.

53e77f6 | Kunal-Saini89 | auto login
  - Refined auto-login state checks and transit home routing parameters.

7633d45 | AryanSolanki73 | Sarthi Logo Changes
  - Redesigned TransitHomeView with custom branding, logo, and active ride cards.

b763618 | AryanSolanki73 | Aryan
  - Merged auto-login changes with updated login screen presentation.

7701c93 | Kunal-Saini89 | auto login 02
  - Enhanced AuthService with token caching and streamlined App authentication wrapper.

60cea30 | Kunal-Saini89 | auto login 03
  - Resolved reactive session routing edge cases in App and LoginPage.

b6e1d2b | Kunal-Saini89 | auto login 04
  - Added auto-login fallback and form validation to SignUpPage.

21305c0 | Kunal-Saini89 | Merge remote-tracking branch 'refs/remotes/origin/main'
  - Harmonized authentication branch with upstream main.

[2026-10-17 — 2026-10-18] ------------------------------------------------
5d32c29 | Ajay | lnbkdc
  - Configured android/gradle.properties.

a038f2a | 2026csm1012-arch | web
  - Added Flutter web support configurations.

134cebe | Ajay | admin web authentication
  - Created lib/admin/ module: main_admin.dart, admin_login_screen.dart, admin_auth_service.dart.

fd6d035 | 2026csm1012-arch | Merge remote-tracking branch 'refs/remotes/origin/main'
  - Merged remote tracking changes into local workspace.

fa3d2ab | Deepak | Merge branch 'main' into ajju
  - Synced main branch updates into Ajay's admin branch.

8d2432a | Deepak | merge pull req from ajju to main
  - Integrated Admin Web Authentication module into main branch.

1dfda1e | 2026csm1012-arch | ad
  - Minor cleanup on configuration files.

4a60245 | 2026csm1012-arch | pubspec
  - Updated pubspec dependency constraints.

bbfd4cd | 2026csm1012-arch | Merge branch 'main' of .../Sarthi_APP
  - Synced local branch with remote main.

2d6c826 | 2026csm1012-arch | ad
  - Minor fix on package lock.

[2026-10-19] -------------------------------------------------------------
7c8291a | 2026csm1012-arch | splash screen added
  - Implemented SplashScreen with branding, animation, and auto-route authentication detection.
  - Linked SplashScreen as the initial application home.

28865b8 | 2026csm1012-arch | user profile  added, and clear signup
  - Created UserProfile model and ProfilePage with user metadata, badges, and settings.
  - Cleaned up signup redirects and enabled direct sign-in routing.

4bca2b6 | Ajay (branch 'ajju') | authorization added
  - Implemented role-based authorization check in AdminAuthService (admin Firestore validation).

[2026-10-21 — 2026-10-23] ------------------------------------------------
8acd615 | Kunal-Saini89 | Intorduce google authentication
  - Added Google Sign-In dependencies and GoogleLogoIcon widget.
  - Updated login and sign up pages to display Google Sign-In options.

7dabf41 | 2026csm1012-arch | before merge
  - Pre-merge checkpoint before major transit integration.

e0eba22 | 2026csm1012-arch | feat: initialize Flutter application with transit models...
  - Integrated SARTHI_Role_Functionality_Specification.md.
  - Restructured transit controllers and model associations.

0a030ba | 2026csm1012-arch | Merge branch 'main' of .../Sarthi_APP
  - Synced main branch.

2d13acd | 2026csm1012-arch | asd
  - Merge checkpoint.

51bb4f9 | 2026csm1012-arch | restructure
  - Streamlined LoginPage and removed deprecated SignUpPage redundancy.
  - Consolidated authentication styling and debug launch configs.

43183e8 | AryanSolanki73 | Google Authentication Working
  - Fixed Google Auth client ID in google-services.json and updated Gradle configurations.

87e6207 | 2026csm1012-arch | added SHA1, SHA256
  - Embedded developer machine SHA-1 and SHA-256 certificate fingerprints into google-services.json.

b577cfc | 2026csm1012-arch | maps
  - Implemented routing_service.dart with OSRM API & polyline decoding.
  - Added CartLocation model and overhauled CampusMapView and TransitHomeView.
  - Integrated dynamic route plotting, pickup/drop-off markers, and vehicle positioning.

1602002 | 2026csm1012-arch | maps route working
  - Optimized polyline path decoding and campus route coordinates rendering.
  - Fine-tuned map camera zoom and bounds animation.
```

---

## 4. Current Architecture & Feature Completion Status

| Feature / Module | Specification Status | Implementation Status | Key Components |
| :--- | :--- | :--- | :--- |
| **Splash Screen** | Completed | 100% | `lib/views/splash_screen.dart` |
| **Email/Password Auth** | Completed | 100% | `lib/services/auth_service.dart`, `lib/views/login_page.dart` |
| **Credential Auto-Login** | Completed | 100% | `lib/services/credential_storage.dart`, `lib/app.dart` |
| **Google Sign-In OAuth** | Completed | 100% | `lib/views/widgets/google_logo_icon.dart`, `google-services.json` |
| **User Profile Management** | Completed | 100% | `lib/models/user_profile.dart`, `lib/views/profile_page.dart` |
| **Bus Transit & Schedules** | Completed | 90% | `lib/models/bus.dart`, `lib/models/ticket.dart`, `transit_home_view.dart` |
| **EV Cart Hailing Workflow** | Completed | 90% | `lib/models/ride_request.dart`, `lib/controllers/transit_controller.dart` |
| **Campus Map & GIS View** | Completed | 95% | `lib/views/transit/campus_map_view.dart`, Carto/OSM tiles |
| **OSRM Route Navigation** | Completed | 95% | `lib/services/routing_service.dart` (OSRM Polyline Decoding) |
| **Admin Web Portal** | In Progress | 80% | `lib/admin/main_admin.dart`, `lib/admin/screen/admin_login_screen.dart` |
| **Driver Location Sharing** | Planned | 30% | `lib/models/cart_location.dart`, Telemetry interface |

---

## 5. Next Steps & Recommended Milestones

1. **Driver Interface Module**: Complete the driver-side toggle to broadcast live GPS telemetry every 3–5 seconds to Firebase Realtime Database.
2. **Merge Admin Authorization**: Merge Ajay's `ajju` branch (`4bca2b6`) into `main` to activate backend admin role enforcement.
3. **QR Code Ticket Generation**: Integrate digital QR code generation in `lib/models/ticket.dart` for fast boarding verification.
4. **End-to-End Field Validation**: Run an on-campus live trial of EV hailing and GPS route tracking between Main Gate, Academic Blocks, and Hostels.
