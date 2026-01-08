# NGO Charity Flow Analytics — API Contract (v1)

Purpose:
A full-stack app to manage NGOs, campaigns, donations, beneficiaries, and produce analytics dashboards
(showing donation flows, distributions, and performance KPIs).

Base URL:
- http://localhost:3000

Global rules:
- All responses are JSON
- Errors always return:
  { "error": "message" }

ID format:
- All IDs are MongoDB ObjectId strings.

--------------------------------------------------------------------
1) DATA MODELS (Collections + Field Names)
--------------------------------------------------------------------

## 1.1 NGOs (collection: ngos)
Represents an organization receiving donations.

Fields:
- name: String (required, trim)
- country: String (required, trim)
- category: String enum ["health","education","food","shelter","environment","emergency"]
- isVerified: Boolean (default false)
- foundedAt: Date
- tags: [String] (default [])
- contact: Object (JSON-like)
  - email: String
  - phone: String
  - address: String
- createdAt, updatedAt: Date (timestamps)

Example NGO:
{
  "name": "Hope Lebanon",
  "country": "Lebanon",
  "category": "health",
  "isVerified": true,
  "foundedAt": "2015-05-10",
  "tags": ["medical","emergency"],
  "contact": { "email": "info@hope.org", "phone": "+96170000000", "address": "Beirut" }
}

------------------------------------------------------------

## 1.2 Campaigns (collection: campaigns)
Represents fundraising campaigns that belong to an NGO.

Fields:
- title: String (required, trim)
- ngoId: ObjectId (required, ref "NGO")  ✅ foreign key to ngos
- startDate: Date (required)
- endDate: Date (required)
- goalAmount: Number (max 1000000)       ✅ Number max example
- status: String enum ["planned","active","paused","completed"]
- channels: [String] enum values allowed ["online","offline","partner"]
- metadata: Object (JSON-like) { theme, region, notes }
- createdAt, updatedAt

Example Campaign:
{
  "title": "Winter Drive 2026",
  "ngoId": "NGO_ID",
  "startDate": "2026-01-01",
  "endDate": "2026-02-01",
  "goalAmount": 50000,
  "status": "active",
  "channels": ["online","partner"],
  "metadata": { "theme":"winter", "region":"Beirut", "notes":"Target families in need" }
}

------------------------------------------------------------

## 1.3 Donations (collection: donations)
Represents a donation transaction. This collection is the core of analytics.

Fields (Assignment requirements included ✅):
- donorName: String (required, lowercase)              ✅ String #1 lowercase/uppercase
- method: String enum ["cash","card","bank_transfer","crypto"]  ✅ String #2 enum
- amount: Number (required, max 100000)               ✅ Number max value
- donationDate: Date (required)                       ✅ Date field
- isRecurring: Boolean (default false)                ✅ Boolean field
- tags: [String] (default [])                         ✅ Array field
- meta: Object (JSON-like)                            ✅ JSON-like field
  { source, platform, note }
- donorEmail: String (required, validate email regex)  ✅ Validation rule field
- ngoId: ObjectId (required, ref "NGO")               ✅ foreign key
- campaignId: ObjectId (optional, ref "Campaign")      (extra link for analytics)
- status: String enum ["pending","completed","failed","refunded"]
- currency: String enum ["USD","EUR","LBP"]
- createdAt, updatedAt

Example Donation:
{
  "donorName": "jean paul",
  "method": "card",
  "amount": 250,
  "donationDate": "2026-01-07",
  "isRecurring": true,
  "tags": ["education","winter"],
  "meta": { "source":"instagram", "platform":"web", "note":"first donation" },
  "donorEmail": "jeanpaul@example.com",
  "ngoId": "NGO_ID",
  "campaignId": "CAMPAIGN_ID",
  "status": "completed",
  "currency": "USD"
}

------------------------------------------------------------

## 1.4 Beneficiaries (collection: beneficiaries)
Represents beneficiaries supported by NGOs (optional but makes project bigger).

Fields:
- fullName: String (required, uppercase)  (another string constraint example)
- ngoId: ObjectId (required, ref "NGO")
- category: String enum ["family","child","elderly","refugee","student"]
- isActive: Boolean (default true)
- registeredAt: Date (required)
- needs: [String]
- profile: Object (JSON-like) { city, phone, notes }
- createdAt, updatedAt

--------------------------------------------------------------------
2) ENDPOINTS
--------------------------------------------------------------------

--------------------
2.1 NGO ENDPOINTS
--------------------

POST /ngos
Body: NGO example
Returns: created NGO

GET /ngos
Returns: array of NGOs

GET /ngos/:id
Returns: NGO by id

PUT /ngos/:id
Body: partial NGO fields
Returns: updated NGO

------------------------
2.2 CAMPAIGN ENDPOINTS
------------------------

POST /campaigns
Body: Campaign example
Returns: created Campaign

GET /campaigns
Query params (optional):
- ngoId=...
- status=active
Returns: campaigns list

GET /campaigns/:id
Returns: campaign by id

PUT /campaigns/:id
Body: partial campaign update
Returns: updated campaign

-----------------------
2.3 DONATION ENDPOINTS
-----------------------

POST /donations                         ✅ Create/Insert
Body: Donation example
Returns: created donation

PUT /donations/:id                      ✅ Update record
Body: partial update fields (amount/status/tags/meta/isRecurring/etc.)
Returns: updated donation

GET /donations                          ✅ Display all
Query params (optional):
- ngoId=...
- campaignId=...
- status=completed
- method=card
- from=YYYY-MM-DD
- to=YYYY-MM-DD

-----------------------------------------------
2.4 REQUIRED "FIND" / FILTER (at least 2 ways)
-----------------------------------------------

GET /donations/by-method/:method         ✅ Criteria #1
Example: /donations/by-method/card

GET /donations/search                    ✅ Criteria #2 (2+ conditions)
Query params supported:
- minAmount=100
- maxAmount=1000
- recurring=true|false
- status=completed|pending|failed|refunded
- ngoId=...
- campaignId=...
- from=YYYY-MM-DD
- to=YYYY-MM-DD

Example (two conditions):
/donations/search?minAmount=100&recurring=true

--------------------------------
2.5 REQUIRED POPULATE ENDPOINT
--------------------------------

GET /donations/populated                 ✅ populate()
Returns donations with:
- ngoId populated (select: name, country, category)
- campaignId populated (select: title, status)

-----------------------------------------
2.6 REQUIRED AGGREGATE JOIN ENDPOINT
-----------------------------------------

GET /donations/aggregate/join            ✅ aggregate + $lookup
Joins donations + ngos (and campaign if exists)
Returns array objects like:
{
  "_id": "DONATION_ID",
  "donorName": "jean paul",
  "amount": 250,
  "method": "card",
  "status": "completed",
  "donationDate": "...",
  "ngo": { "_id":"NGO_ID", "name":"Hope Lebanon", "country":"Lebanon" },
  "campaign": { "_id":"CAMPAIGN_ID", "title":"Winter Drive 2026", "status":"active" }
}

---------------------------
2.7 BENEFICIARY ENDPOINTS
---------------------------

POST /beneficiaries
GET /beneficiaries
Query params (optional):
- ngoId=...
- isActive=true|false
- category=family|child|elderly|refugee|student

PUT /beneficiaries/:id

--------------------------------------------------------------------
3) ANALYTICS ENDPOINTS (Big Project / Dashboard)
--------------------------------------------------------------------
These are for charts and “flow analytics” screens in Flutter.

GET /analytics/summary
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
- ngoId=optional
- campaignId=optional
Returns:
{
  "totalAmount": 12500,
  "donationsCount": 68,
  "uniqueDonors": 45,
  "recurringCount": 12,
  "refundedCount": 3
}

GET /analytics/by-ngo
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
Returns ranking:
[
  { "ngoId":"...", "ngoName":"Hope Lebanon", "totalAmount":9000, "count":40 },
  { "ngoId":"...", "ngoName":"Food For All", "totalAmount":3500, "count":28 }
]

GET /analytics/by-method
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
Returns:
[
  { "method":"card", "totalAmount":7000, "count":30 },
  { "method":"cash", "totalAmount":3000, "count":25 }
]

GET /analytics/by-status
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
Returns:
[
  { "status":"completed", "totalAmount":11000, "count":60 },
  { "status":"refunded", "totalAmount":500, "count":3 }
]

GET /analytics/timeseries/daily
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
- ngoId=optional
- campaignId=optional
Returns:
[
  { "date":"2026-01-01", "totalAmount":500, "count":3 },
  { "date":"2026-01-02", "totalAmount":200, "count":1 }
]

GET /analytics/top-donors
Query params:
- from=YYYY-MM-DD
- to=YYYY-MM-DD
- limit=10
Returns:
[
  { "donorEmail":"a@x.com", "donorName":"ali", "totalAmount":1200, "count":4 },
  { "donorEmail":"b@y.com", "donorName":"mira", "totalAmount":900, "count":2 }
]

--------------------------------------------------------------------
4) REQUIRED FEATURES CHECKLIST (for grading)
--------------------------------------------------------------------
✅ Schema types: String, Number/Integer, Date, Boolean, Array, Object(JSON-like)
✅ Constraints:
- donorName: lowercase (or uppercase)
- method: enum
- amount: max
- donorEmail: custom validation
✅ Relationship:
- Donation.ngoId references NGO
✅ Queries:
- /donations/by-method/:method  (criteria #1)
- /donations/search?...         (criteria #2 with >=2 conditions)
✅ populate:
- /donations/populated
✅ aggregate join:
- /donations/aggregate/join
✅ CRUD:
- POST create, PUT update, GET retrieve (and optional extra for NGO/Campaign)
