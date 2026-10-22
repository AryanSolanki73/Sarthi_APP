# SYSTEM FUNCTIONAL SPECIFICATION: SARTHI MOBILITY APP
**STANDARD:** ASD-STE100 Compliant (70% Controlled Technical English)  
**TARGET:** Machine Consumption / Low-Token LLM Ingestion  
**ENCODING:** Markdown / Compact Structured Specification  

---

## 1. GLOBAL SYSTEM DEFINITION

- **System Name:** SARTHI Campus Mobility Application.
- **Core Technology:** Flutter (Client), Firebase Auth, Cloud Firestore, Firebase Realtime Database.
- **Purpose:** Manage on-campus Electric Vehicle (EV) cart hailing and inter-campus bus tracking.
- **Access Model:** Role-Based Access Control (RBAC).
- **Defined Roles:** `User` (Student/Staff), `Driver` (Vehicle Operator), `Admin` (Mobility Manager).

---

## 2. ROLE SPECIFICATION: USER (STUDENT / COMMUTER)

### 2.1 Identity and Access
- The User registers with a valid institutional email address (`@iitrpr.ac.in`).
- The User authenticates with email and password.
- The User views only personal profile data, personal booking history, and public vehicle status.
- **Denied Action:** The User cannot change the assigned role.
- **Denied Action:** The User cannot read private records of other users.

### 2.2 EV Cart Booking Functionality
- **State Flow:** `IDLE` → `REQUESTED` → `ACCEPTED` → `ARRIVING` → `ONGOING` → `COMPLETED` (or `CANCELLED`).
- **Hail Request:**
  - The User selects a pickup point from an approved campus location list.
  - The User selects a drop-off point from an approved campus location list.
  - The User submits the ride request. Fare is zero (free ride).
  - Precondition: The User does not have an active ride request.
- **Live Ride Tracking:**
  - The User views real-time cart position on the campus map during `ACCEPTED`, `ARRIVING`, and `ONGOING` states.
  - The User views driver details and cart identifier.
- **Cancellation:**
  - The User cancels a ride request before driver arrival (`REQUESTED` or `ACCEPTED` state).
  - The System updates the ride state to `CANCELLED`.

### 2.3 City Shuttle and Bus Transit
- **Schedule Discovery:**
  - The User views the scheduled bus routes, stops, and departure times.
  - The User views available seat count per scheduled bus.
- **Seat Reservation:**
  - The User reserves a seat on a scheduled bus when `availableSeats > 0`.
  - The System decrements available seat count by 1.
  - The System generates a unique digital ticket with ticket ID and verification payload.
- **Live Bus Tracking:**
  - The User selects an active bus route.
  - The User views the live bus GPS marker and last-updated timestamp.
  - The System displays the next stop and approximate ETA when telemetry is valid.
- **Ticket Vault:**
  - The User opens the ticket drawer.
  - The User displays active tickets (with alphanumeric ID / QR code) for driver inspection.

---

## 3. ROLE SPECIFICATION: DRIVER (VEHICLE OPERATOR)

### 3.1 Identity and Access
- The Driver authenticates with assigned credentials.
- The Driver binds session to an assigned vehicle (`cartId` or `busId`).
- **Denied Action:** The Driver cannot alter system routes, fares, or user records.
- **Denied Action:** The Driver cannot reassign vehicles.

### 3.2 EV Cart Operator Workflow
- **Request Dispatch:**
  - The Driver receives pending ride requests in real time.
  - The Driver views pickup location, drop-off location, and request elapsed time.
  - The Driver accepts an available ride request.
  - Constraint: One driver accepts only one ride request at a time.
- **Trip Lifecycle Execution:**
  - Action 1: Driver accepts request (`State = ACCEPTED`).
  - Action 2: Driver signals arrival at pickup (`State = ARRIVING`).
  - Action 3: Driver picks up passenger and begins trip (`State = ONGOING`).
  - Action 4: Driver completes drop-off (`State = COMPLETED`).
  - The System sets driver status back to `AVAILABLE`.
- **Capacity Signaling:**
  - The Driver updates cart status: `Empty`, `Filling`, or `Full`.

### 3.3 Bus Operator and Telemetry Workflow
- **Live Telemetry Transmission:**
  - The Driver starts a trip on a selected route.
  - The Driver device transmits GPS coordinates (`latitude`, `longitude`, `timestamp`) every 3 to 5 seconds to the Realtime Database.
  - The Driver stops location transmission upon route completion.
- **Boarding Ticket Verification:**
  - The Driver opens the QR/Code verification module.
  - The Driver scans the ticket QR code or inputs the ticket ID.
  - System validation rules:
    - If `ticket.isUsed == false`: Mark ticket `USED`, permit boarding.
    - If `ticket.isUsed == true`: Show warning `ALREADY_USED`, deny boarding.
    - If ticket not found: Show error `INVALID_TICKET`, deny boarding.

---

## 4. ROLE SPECIFICATION: ADMIN (CAMPUS MOBILITY MANAGER)

### 4.1 Identity and Access
- The Admin authenticates with administrative credentials.
- Access requires backend validation via custom security claims or protected database documents.
- The Admin possesses full read/write access to transit configuration and fleet entities.

### 4.2 Fleet Management
- **Vehicle Inventory:**
  - The Admin creates, edits, and deletes vehicles in the database (`buses`, `carts`).
  - Attributes: `vehicleId`, `registrationNumber`, `type`, `capacity`, `activeStatus`.
  - The Admin views operational health and maintenance flags.
- **Driver and Vehicle Pairing:**
  - The Admin assigns a verified driver to a specific bus or cart.
  - The Admin revokes driver vehicle assignments.

### 4.3 Transit Network Configuration
- **Route Management:**
  - The Admin creates new campus routes and city shuttle paths.
  - The Admin sets sequential transit stops and geographic boundaries (geofences).
  - The Admin updates schedule departure and arrival tables.
- **Location Landmarks:**
  - The Admin manages authorized campus pickup and drop-off points (e.g., Hostels, Academic Blocks, Gates).

### 4.4 Operations Monitoring and Auditing
- **Live Fleet Telemetry:**
  - The Admin monitors real-time locations of all active carts and buses on a central dashboard.
  - The Admin detects stalled vehicles or offline telemetry streams.
- **Override and Safety Controls:**
  - The Admin force-cancels stranded ride requests.
  - The Admin reassigns stuck trips to alternative drivers.
  - The Admin broadcasts emergency alerts or operational delays to Users and Drivers.
- **Audit Logs:**
  - The Admin reviews completed ride histories, ticket redemption rates, and fleet utilization metrics.

---

## 5. RBAC PERMISSIONS AND DATA ACCESS MATRIX

| Capability / Entity | User (Student) | Driver | Admin |
|:---|:---:|:---:|:---:|
| Submit EV ride request | **ALLOW** | DENY | DENY |
| Accept / Execute ride request | DENY | **ALLOW** | DENY |
| Force-cancel any ride request | DENY | DENY | **ALLOW** |
| Book bus seat ticket | **ALLOW** | DENY | DENY |
| Scan and redeem bus ticket | DENY | **ALLOW** | **ALLOW** |
| Broadcast vehicle GPS position | DENY | **ALLOW** | DENY |
| Read real-time vehicle positions | **ALLOW** | **ALLOW** | **ALLOW** |
| Create / Edit routes and stops | DENY | DENY | **ALLOW** |
| Register / Deactivate vehicles | DENY | DENY | **ALLOW** |
| Change user roles (RBAC) | DENY | DENY | **ALLOW** |

---

## 6. DATA ENTITY SCHEMAS (COMPACT REFERENCE)

```yaml
UserProfile:
  uid: string (primary key)
  name: string
  email: string
  photoUrl: string?
  role: enum [student, driver, admin]
  createdAt: timestamp

RideRequest:
  id: string (primary key)
  studentId: string
  driverId: string?
  pickupLocation: string
  dropLocation: string
  status: enum [requested, accepted, arriving, ongoing, completed, cancelled]
  createdAt: timestamp
  updatedAt: timestamp

BusSchedule:
  id: string (primary key)
  route: string
  registrationNumber: string
  departureTime: string
  totalSeats: integer
  availableSeats: integer
  isActive: boolean

Ticket:
  id: string (primary key)
  busId: string
  studentId: string
  bookingTime: timestamp
  isUsed: boolean

TelemetryPayload:
  vehicleId: string
  role: enum [bus, cart]
  latitude: float
  longitude: float
  heading: float?
  speed: float?
  timestamp: integer (unix epoch ms)
```

---

## 7. SYSTEM LIFECYCLE STATE MACHINE (LLM INGESTION RULES)

```
[EV Cart Lifecycle]
(User Hail)   --> [REQUESTED]
[REQUESTED]   --> (Driver Accept)  --> [ACCEPTED]
[REQUESTED]   --> (User Cancel)    --> [CANCELLED]
[ACCEPTED]    --> (Driver Arrive)  --> [ARRIVING]
[ARRIVING]    --> (Start Trip)     --> [ONGOING]
[ONGOING]     --> (End Trip)       --> [COMPLETED]

[Ticket Verification Lifecycle]
(User Booking) --> [TICKET ISSUED (isUsed = false)]
[TICKET ISSUED] --> (Driver Scan Valid)   --> [TICKET REDEEMED (isUsed = true)]
[TICKET REDEEMED]--> (Duplicate Scan)     --> [REJECT: ALREADY_USED]
```
