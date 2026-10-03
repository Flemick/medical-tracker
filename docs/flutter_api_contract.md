# Flutter API Contract Verification

This document verifies the API contract between the Flutter USER app and the Flask backend based on a direct inspection of `d:\medeqp\backend\app.py`.

## 1. Authentication Endpoints

### `POST /api/auth/login`
- **Method:** POST
- **Auth Required:** No
- **Request JSON:** `{"email": "user@domain.com", "password": "password"}`
- **Actual JSON Response (Flask):** Returns `{ "message": "...", "access_token": "...", "user": {"id": "...", "email": "..."}, "profile": {"id": "...", "name": "...", "role": "...", "department": "...", "is_active": true} }`
- **Error Response:** `{"error": "...", "details": "..."}` (400, 401, 403)

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/auth/login` | POST | `{"access_token": "...", "profile": {...}, "user": {...}}` | `{"access_token": "...", "profile": {...}, "user": {...}}` | ✅ Yes |

### `GET /api/auth/me`
- **Method:** GET
- **Auth Required:** Yes (Bearer Token)
- **Actual JSON Response (Flask):** Returns `{ "user": {"id": "...", "email": "..."}, "profile": {"id": "...", "name": "...", "role": "...", "department": "...", "is_active": true} }`
- **Error Response:** Handled by `@require_auth` (401, 403)

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/auth/me` | GET | `{"user": {...}, "profile": {...}}` | `{"user": {...}, "profile": {...}}` | ✅ Yes |

---

## 2. Equipment Endpoints

### `GET /api/equipment`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Supabase `select('*, locations(*), qr_codes(*)')`. Wraps in `{"count": X, "data": [...]}`.
- Equipment uses `equipment_id` (not `id`).
- Location is nested in `locations` object.
- QR Codes are nested in `qr_codes` array.

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/equipment` | GET | `{"count": X, "data": [{"equipment_id": "...", "equipment_name": "...", "locations": {...}, "qr_codes": [...]}]}` | `{"count": X, "data": [{"equipment_id": "...", ...}]}` | ✅ Yes |

### `GET /api/equipment/{id}`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** `{"data": {"equipment_id": "...", ...}}` (Single object wrapped in `data`)
- **Error Response:** `{"error": "Not Found", "message": "..."}` (404)

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/equipment/{id}` | GET | `{"data": {"equipment_id": "...", ...}}` | `{"data": {"equipment_id": "...", ...}}` | ✅ Yes |

### `GET /api/equipment/{id}/qr`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Returns `{ "data": {"qr_id": "...", "equipment_id": "...", "qr_url": "...", "status": "ACTIVE"} }`. If no QR code exists, Flask auto-generates one and returns it.

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/equipment/{id}/qr` | GET | `{"data": {"qr_url": "...", "status": "ACTIVE", ...}}` | `{"data": {"qr_url": "...", "status": "ACTIVE", ...}}` | ✅ Yes |

---

## 3. Location Endpoints

### `GET /api/locations`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Supabase `select('*')`. Returns `{"data": [{"location_id": "...", "building": "...", "floor": "...", "department": "...", "room": "..."}]}`.

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/locations` | GET | `{"data": [{"location_id": "...", ...}]}` | `{"data": [{"location_id": "...", ...}]}` | ✅ Yes |

---

## 4. Complaints Endpoints

### `GET /api/complaints`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Returns `{"count": X, "data": [{"id": "...", "ticket_number": "...", "equipment_id": "...", "status": "...", ...}]}`

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/complaints` | GET | `{"count": X, "data": [{"id": "...", ...}]}` | `{"count": X, "data": [{"id": "...", ...}]}` | ✅ Yes |

### `POST /api/complaints`
- **Method:** POST
- **Auth Required:** Yes
- **Request JSON:** `{"equipment_id": "...", "description": "...", "type": "...", "severity": "...", ...}`
- **Actual JSON Response (Flask):** Returns `{"message": "...", "data": {"id": "...", "ticket_number": "...", ...}}`

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/complaints` | POST | `{"message": "...", "data": {...}}` | `{"message": "...", "data": {...}}` | ✅ Yes |

### `PUT /api/complaints/{id}/status`
- **Method:** PUT
- **Auth Required:** Yes
- **Request JSON:** `{"status": "...", "assigned_tech_name": "...", "resolution_summary": "..."}`
- **Actual JSON Response (Flask):** Returns `{"message": "...", "data": [...]}`

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/complaints/{id}/status` | PUT | `{"message": "...", "data": [...]}` | `{"message": "...", "data": [...]}` | ✅ Yes |

---

## 5. Notifications Endpoints

### `GET /api/notifications`
- **Method:** GET
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Returns `{"data": [{"id": "...", "title": "...", "message": "...", "type": "...", "is_read": false, ...}]}`

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/notifications` | GET | `{"data": [{"id": "...", ...}]}` | `{"data": [{"id": "...", ...}]}` | ✅ Yes |

### `PUT /api/notifications/{id}/read`
- **Method:** PUT
- **Auth Required:** Yes
- **Actual JSON Response (Flask):** Returns `{"message": "...", "data": [...]}`

| Endpoint | Method | Actual JSON response | Flutter expects | Match? |
|----------|--------|----------------------|-----------------|--------|
| `/api/notifications/{id}/read` | PUT | `{"message": "...", "data": [...]}` | `{"message": "...", "data": [...]}` | ✅ Yes |


---

## Field Name Verifications

- **Authentication Token:** Extracted from JSON `access_token`. Sent via header `Authorization: Bearer <token>`.
- **Response Wrapping:** Most routes wrap lists/objects in a `{"data": ...}` payload. Exceptions: `POST /api/auth/login` returns `access_token`, `user`, `profile` at root.
- **Equipment Primary Key:** `equipment_id` (not `id`).
- **Location Primary Key:** `location_id`.
- **Complaint Primary Key:** `id`.
- **Notification Primary Key:** `id`.

---

## Conclusion & Recommendations

### A. MATCHING ENDPOINTS
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/equipment`
- `GET /api/equipment/{id}`
- `GET /api/equipment/{id}/qr`
- `GET /api/locations`
- `GET /api/complaints`
- `POST /api/complaints`
- `PUT /api/complaints/{id}/status`
- `GET /api/notifications`
- `PUT /api/notifications/{id}/read`

### B. MISMATCHED ENDPOINTS
- None. The current Flutter implementation in `lib/services/api_service.dart` has already been perfectly adapted to match the Flask backend exactly as documented above.

### C. MISSING ENDPOINTS
- None required for the USER mobile application scope. (Maintenance endpoints exist on the backend but are primarily for Admin/BioMed roles).

### D. FIELD NAME MISMATCHES
- None. The Flutter models (`user_model.dart`, `equipment.dart`, `complaint.dart`, etc.) perfectly map the snake_case JSON fields from Flask to Dart's camelCase format.

### E. AUTHENTICATION MISMATCHES
- None. Flask requires `Authorization: Bearer <token>` and Flutter `auth_service.dart` supplies exactly this.

### F. RECOMMENDED CHANGES
- **No changes to Flask backend are necessary.** The backend provides all necessary REST endpoints with proper `data` wrapping and status codes.
- **No further changes to Flutter API parsing are necessary.** The parsing in `ApiService` correctly unwraps `data`, checks `count` where applicable, and properly uses `equipment_id` for equipment data.
