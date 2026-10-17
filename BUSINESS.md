# Bank8:Admin — Business Requirements & Functionality

> Audience: product owners, business analysts, and anyone evaluating what
> Bank8:Admin **does for the business**. For architecture read `README.md`;
> for wire-level detail read `DESIGN.md`.

## 1. Business Purpose

- Give bank staff **one console** for the entire vertical: ledger, payments,
  and FDX administration, plus sentin8 service enablement and health —
  authored once, rendered from the services' own admin UI definitions.
- Eliminate admin-code drift: when a service gains a capability, its admin
  surface appears in the console through the RFW contract without console
  releases.

## 2. Business Scope (What the Service Provides)

| Capability | Delivered through |
|---|---|
| Service health overview (ledger / payments / fdx) | each service `/v1/health` |
| Sentin8 service enablement per environment (view + toggle) | Sentin8:Sys |
| Ledger administration: products (create), accounts, postings, schedules, DLQ, balances, customers, audit | Bank8:Ledger admin APIs + RFW |
| Payments administration: instructions, rules, cards, files, integrations, manual decisions, mandates, templates, calendars, dashboards | Bank8:Payments admin APIs + RFW |
| FDX administration: provider profile, recipients, consents | Bank8:FDX admin APIs + RFW |
| RFW-rendered service admin pages (fetch, render, submit) | platform RFW contract via BFF |

**What Admin does NOT own (business boundary):**

| Concern | Owning service |
|---|---|
| Staff identity and sign-in | Sentin8:Auth |
| Session/token custody, scope gating | Sentin8:BFF |
| Admin UX definitions and their business logic | Bank8:Ledger / Bank8:Payments / Bank8:FDX |
| Vertical service enablement state | Sentin8:Sys |
| Structured persistence | Sentin8:DB |
| Policy decisions | Shield within each service |

## 3. Business Capabilities

| Area | Capability | Business rule |
|---|---|---|
| Overview | Health visibility | Staff see each vertical service's health at a glance before working its sections. |
| Provisioning | Service enablement | Staff enable/disable vertical services per environment; enablement drives the platform's per-tenant initialization. |
| Ledger admin | Product lifecycle | Staff create products and browse accounts/postings/schedules/balances/customers/audit; every action is admin-scoped and audited upstream. |
| Ledger ops | DLQ handling | Staff land and replay failed messages deliberately; replay is explicit, never automatic. |
| Payments admin | Operations control | Staff review and manage instructions, rules, cards, files, mandates, templates, calendars, and manual decisions through the payments service's own gates. |
| FDX admin | Open-banking oversight | Staff manage the provider profile, review registered recipients, and monitor consents. |
| Rendering | RFW host | Admin pages defined by the services render unchanged in the console; mutations follow the POST alias data contract. |

## 4. Business Events (Outbound)

Admin emits no domain events of its own; staff actions produce upstream
events in the owning services:

| Console action | Upstream event |
|---|---|
| Product create / data mutation | Owning service's domain event + audit journal entry |
| Service enablement toggle | `sentin8:sys:service:updated` → per-tenant vertical initialization |
| DLQ republish | Ledger DLQ replay event |

**Inbound (consumed):** none — the console is request/response only; lists
refresh on page entry.

## 5. Business Rules & Invariants

1. The console is staff-only; every capability is admin-scoped upstream and
   audited.
2. The console carries no backend business knowledge — it renders service
   definitions and calls service admin APIs.
3. New admin surfaces ship with their service (RFW definition + scopes), not
   with console releases.
4. DLQ replay and manual decisions are deliberate staff actions.
5. Service enablement is an explicit per-environment act, validated and
   audited by Sentin8:Sys.
6. The console fails closed: without a verified instance identity and staff
   session, nothing renders.

## 6. Target-User Roles & Use Cases

| Persona | What they do |
|---|---|
| Bank operations staff | Day-to-day administration: monitors health, manages ledger/payment products and records, handles DLQ and decisions. |
| Tenant administrator | Enables vertical services, oversees provider/recipients/consents, reads audit. |
| Platform / vertical product owner | Ships new admin surfaces by publishing RFW definitions + admin scopes — no console release needed. |

## 7. KPIs / Success Criteria

- **Reliability:** per-service isolation — one service's outage degrades only
  its own console sections.
- **Latency:** admin lists and RFW pages render promptly (single proxy hop;
  definition caching except for parameterized pages).
- **Security:** 100% of console mutations admin-scoped and audited upstream;
  zero staff authorization logic in the client.
- **Maintainability:** zero per-service page code for RFW-rendered sections —
  services ship capabilities without console changes.
- **Coverage:** every ledger/payments/fdx admin capability reachable from one
  console URL.

## 8. Dependencies & Reliance on Other Services

| Dependency | Why |
|---|---|
| Sentin8:Auth | Staff sign-in |
| Sentin8:BFF | Staff session, token attach, scope gating, proxy |
| Bank8:Ledger | Ledger admin data + RFW definitions + health |
| Bank8:Payments | Payments admin data + RFW definitions + health |
| Bank8:FDX | FDX admin data + RFW definitions + health |
| Sentin8:Sys | Service enablement per environment |
| Sentin8:App | Instance provisioning, runtime context, listing |
| Sentin8:TLS | Hostname → instance resolution, TLS termination |

## 9. Acceptance Criteria

1. Staff sign into the console and see service health for the vertical
   immediately.
2. Staff can enable/disable vertical services for an environment and the
   change takes effect through Sentin8:Sys (audited).
3. Staff can create ledger products and administer the listed ledger,
   payments, and FDX surfaces without leaving the console.
4. Services' RFW admin pages render and submit correctly through the console.
5. Every console mutation is admin-scoped and audited upstream; a scope gap
   yields a rendered permission error, never a bypass.
6. E2E: the staff console journey (sign-in → product creation) runs through
   the browser like a real staff member.
7. A new service admin capability (RFW definition + scope) is usable in the
   console without a console code change.

## 10. Open Business Questions

- When do the placeholder sections (reconcile, csdf, dashboards) land as
  full capabilities — via RFW definitions or dedicated admin APIs?
- Should cross-service workflows (operations spanning ledger + payments)
  get a purpose-built console view once correlated state is available?

---

**Design attribution:** bank8:admin and its underlying concepts were designed by Hamid Jahanzad <Hamid@Jahanzad.com>.
