# Ensemble

A Rails application for managing student work plans, skills progression tracking, and competency-based learning in primary schools. Currently in production and used by teachers in France.

Developed by [VRoad Studio](https://www.vroadstudio.fr)

## Tech Stack

- **Backend**: Ruby on Rails 7.1
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5
- **JavaScript**: esbuild
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq + Redis
- **PDF Generation**: Ferrum, connected over CDP to a browserless Chrome service
- **File Storage**: Cloudinary (Active Storage)
- **Payments**: Stripe
- **Deployment**: OVH VPS managed by Coolify v4 (Docker)
- **Testing**: RSpec

## Installation

### Prerequisites
- Ruby 3.3.10 (see `.ruby-version`)
- PostgreSQL
- Redis
- Node.js **v20.17.0** — `package.json` pins the exact version, so another patch
  release makes `yarn` refuse to run. Use `yarn --ignore-engines <cmd>` to bypass.
- Yarn 1.22.19+
- Chrome or Chromium (PDF generation, screenshots)

### Setup

```bash
git clone git@github.com:bensouc/ensemble.git
cd ensemble

# Install dependencies
bundle install
yarn install

# Setup database
rails db:create db:migrate db:seed

# Start the server
bin/dev
```

### Environment Variables
Create a `.env` file with:
```
DOMAIN=...
CLOUDINARY_URL=...
REDIS_URL=...

# Stripe — the price and pricing-table ids belong to ONE mode. A live `price_…`
# is unknown in test mode, and Checkout breaks. See `rake stripe:clone_to_test`.
STRIPE_API_KEY=...
STRIPE_PUBLISHABLE_KEY=...
STRIPE_WEBHOOK_SECRET_KEY=...
STRIPE_PRICE_MONTHLY=...
STRIPE_PRICE_ANNUALY=...
STRIPE_SCHOOL_PRICING_ID=...

# Mail — Gmail SMTP, despite the GANDI_ prefix kept for historical reasons
GANDI_MAIL_NAME=...
GANDI_MAIL_PSWORD=...

# Monitoring & anti-spam
BUGSNAG_API_KEY=...
PAPERTRAIL_API_TOKEN=...
SLACK_NOTIF_WEBHOOK_URL=...
RECAPTCHA_SITE_KEY=...
RECAPTCHA_SECRET_KEY=...
```

Two more, read only where they matter:

- `CHROME_URL=ws://chrome:3000?token=...` — **production only**, points Ferrum at
  the browserless service. Left unset, Ferrum spawns a local Chrome, which is
  what happens in development. `CHROME_PATH` overrides where it looks for that
  local binary.
- `RAILS_MASTER_KEY` — production, to decrypt the credentials.

And three that only the Rake tasks read, never the app: `STRIPE_TEST_API_KEY`
(clone target), `STRIPE_AUDIT_API_KEY` (the VAT tasks, so you can point them at
production without touching `.env`), and `MAIL_REEL` (below).

### Mail in development

Mail is **not sent** in development: `letter_opener_web` collects it and serves
it at <http://localhost:3000/letter_opener>, also reachable from the account menu
under *Mails (dev)*. The route is mounted only under `Rails.env.development?`.

`MAIL_REEL=true bin/dev` falls back to the real SMTP, for the day you need to
check that a message actually leaves.

## Tests

Run the test suite with RSpec:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/student_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

## Processes

The app runs as **two Rails processes** — a web server and a background worker —
plus a JavaScript watcher in development. They are started very differently on
each side.

### In development

`bin/dev` installs `foreman` if missing, then runs `Procfile.dev`:

| Process | Command | Role |
| --- | --- | --- |
| `web` | `puma -C config/puma.rb -p 3000` | Serves HTTP |
| `sidekiq` | `sidekiq -C config/sidekiq.yml` | Background jobs |
| `js` | `yarn build:watch` | Rebuilds the esbuild bundle on save |

The `js` process matters more than it looks: without it, `app/assets/builds/application.js`
goes stale and the page silently loses every Stimulus controller. Running
`rails server` alone is not equivalent to `bin/dev`.

### In production

Coolify has **no "Start Command" for Dockerfile apps**, so a single image serves
both roles and `bin/docker-entrypoint` picks one from the `PROCESS_TYPE`
environment variable:

- `PROCESS_TYPE=worker` → `bundle exec sidekiq -C config/sidekiq.yml`
- anything else → the Dockerfile `CMD`, i.e. `bundle exec puma -C config/puma.rb`

Concretely there are two Coolify applications built from the same repository and
the same image, sharing the same environment except that the worker adds
`PROCESS_TYPE=worker`, exposes no domain, and has its healthcheck disabled.

The entrypoint sits behind `tini` (PID 1) so orphaned Chrome children get reaped
instead of piling up as zombies.

**Migrations do not run in the entrypoint.** They run as a Coolify pre-deploy
command on the *web* app only — otherwise both processes would race to migrate
the same database on every deploy.

### Concurrency

Puma declares no `workers`, so it runs in **single mode**: one process, threads
only. `RAILS_MAX_THREADS` (default 5) sets the thread count *and* the
ActiveRecord pool size — `config/database.yml` reads the same variable, which is
what keeps them from drifting apart. Sidekiq runs a concurrency of 5 on a single
`default` queue.

Chrome is not a Rails process: in production it is a separate browserless
container reached over CDP at `CHROME_URL`.

## Further documentation

Deep dives live in `docs/`, in French:

- [`actiontext_editor.md`](docs/actiontext_editor.md) — the rich editor: Trix
  configuration, custom toolbar, block attributes and their constraints
- [`challenges_tables.md`](docs/challenges_tables.md) — how tables inside
  exercises are stored and edited
- [`recuperation_images.md`](docs/recuperation_images.md) — recovering exercise
  images lost from Cloudinary
- [`abonnement_sur_facture.md`](docs/abonnement_sur_facture.md) — schools that pay
  by invoice (*mandat administratif*): creating the Stripe subscription, matching
  an already-paid period, and what **not** to do

## Rake tasks

```bash
bundle exec rake -T          # full list with descriptions
```

| Task | What it does |
| --- | --- |
| `captures:doc` | Screenshots for the Notion tutorials, written to `tmp/captures`. **Development only** — see below. |
| `challenge:reassign_owner[from,to]` | Reassigns every exercise of one author to another. Asks for confirmation; `DRY_RUN=true` simulates. |
| `challenge:check_broken_images` | Finds exercises whose Action Text content points at a dead image URL. |
| `clean:empty_challenges` | Deletes exercises still holding the blank template and attached to no work plan. |
| `belts:clean_double` | Removes duplicate belts. |
| `conversations:school_update` | Rebuilds the school-wide conversation membership. |
| `result:update` / `result:update_all` | Recomputes results from the most recently updated work plan skills. |
| `stripe:audit_tva` | **Read-only.** Reports Stripe Tax status, active tax registrations, prices with an explicit tax behaviour, subscriptions carrying `automatic_tax`, and invoices actually bearing a tax. |
| `stripe:desactiver_tva` | Turns `automatic_tax` off and stamps the VAT-exemption notice. Reports only by default; `APPLIQUER=1` writes. |
| `stripe:clone_to_test` | Recreates the product and its prices in test mode, so development never touches live data. |

Point the first two at production without editing `.env`:

```bash
STRIPE_AUDIT_API_KEY=sk_live_… bin/rails stripe:audit_tva
```

`stripe:clone_to_test` reads the live product through `STRIPE_API_KEY`, so it has
to run **before** you switch that key to test mode. It refuses to run when the
target key is not a test key, when both keys are equal, and when the source
product is unreachable — the last one is exactly the wrong-order case.

### Documentation screenshots

The tutorials live in Notion, and the in-app help button links to them from
`ApplicationHelper::TUTO_LINKS`. **Those URLs are hardcoded: renaming a Notion
page changes its slug and breaks the link.** Prefer the bare-id URL form for any
page added to that table.

To refresh the screenshots, start the server and run:

```bash
CHALLENGE_ID=3025 TABLE_ID=5735 WORK_PLAN_ID=6644 bundle exec rails captures:doc
```

Files land in `tmp/captures` at device scale 2 (retina). The screen list is a
constant at the top of `lib/tasks/captures.rake`; each entry can carry a `js`
snippet to unfold a folder or open a menu before the shot, and a `selector` to
frame the capture on one element.

Authentication goes through `DevSessionsController` — a passwordless login whose
route is declared only under `Rails.env.development?`, so it does not exist
anywhere else. Point `USER_ID` at a demo account: screenshots must never show
real pupil names.

## Features History

### 2026

<details>
<summary><strong>August 2026 - Editor rework & exercise management</strong></summary>

- Action Text editor rebuilt: text alignment, line height, colour palettes with a
  free colour picker, and a keyboard-only link (Ctrl/Cmd + K)
- Editable tables with per-cell text colour, and a confirmation before deleting a
  row or a column
- Explicit ordering of the exercises of a skill — this drives which exercise the
  auto-generation serves next
- Cloning an exercise straight from the list
- `Charger` / `Créer` when a work plan skill has no exercise left to serve,
  instead of silently creating a blank one
- Transferring a pupil to another class of the same grade
- User impersonation for support — including the subscription pages, so an admin
  can walk a school through payment under its own identity
- **Inviting a colleague by email** instead of picking their password for them:
  the account is attached to the school on send, the invitee only chooses a
  password. Link valid 15 days (`config.invite_for`). The old path mailed the
  password in clear text and is gone.
- **School code** generated automatically, unique, and renewable by the group
  owner — the column had existed since March 2024 without anything ever filling it
- Class quota enforced server-side: it used to only hide the button, and ignored
  whether the subscription was still active
- Every outgoing email rebuilt on one shared shell (logo, typography, responsive
  card); three of them still addressed the reader in English
</details>

<details>
<summary><strong>June-July 2026 - Scalingo to OVH migration</strong></summary>

- Production moved from Scalingo to an OVH VPS managed by Coolify v4 (Docker)
- Multi-stage Dockerfile, PostgreSQL 16 and Redis as Coolify resources, Sidekiq
  worker split out via a `PROCESS_TYPE` environment variable
- PDF generation fixed by connecting Ferrum to a **browserless** Chrome service
  over CDP: spawning Chromium inside the Rails container hung on startup
- Active Storage variants switched to `:vips`, dropping the ImageMagick dependency
- Daily PostgreSQL backups, Let's Encrypt certificate, Scalingo decommissioned
</details>

<details>
<summary><strong>January 2026 - PDF, esbuild & stack upgrade</strong></summary>

- **PDF Generation Migration**: Migrated from WickedPdf to Ferrum (Chrome headless) for better rendering
- **Student Results PDF**: Enhanced with belt validation icons and improved layout
- **Work Plan PDF**: Added footer with pagination, student info, and page break optimization
- **esbuild Migration**: Removed Webpacker, now using esbuild for JavaScript bundling
- **Scalingo Deployment**: Optimized with Chrome buildpack for PDF generation *(superseded by the June 2026 migration)*
- **Stack Upgrade**: Ruby 3.1.2 → 3.3.6, Rails 7.0 → 7.1.6, Puma 4 → 6 (performance et sécurité)
</details>

### 2024 Features
<details>
<summary><strong>December 2024 - Error Notifications & Monitoring</strong></summary>

- Slack notifications for application errors
- Email alerts for critical issues
- Cloudinary storage configuration updates
</details>

<details>
<summary><strong>October-November 2024 - Results & Belt Management</strong></summary>

- Classroom results by domain view
- Belt validation workflow improvements
- Results acknowledgment system rebuild
</details>

<details>
<summary><strong>July-September 2024 - Challenge Customization</strong></summary>

- Color customization for challenges (pen colors)
- Auto-generation with results integration
- Special domains handling improvements
</details>

<details>
<summary><strong>May-June 2024 - Mobile & Testing</strong></summary>

- Mobile views for student results
- RSpec test coverage pushed up substantially *(the "100%" claimed at the time was
  never reached — `bundle exec rspec` reports 83.7% line coverage today)*
- Student results page refactored with full Turbo Streams
</details>

<details>
<summary><strong>March-April 2024 - Skills & Subscriptions</strong></summary>

- Skills upload via Excel (XLSX)
- Subscription system with Stripe (coupons, quantity modifications)
- Captcha on contact forms
- Action Text editor enhancements (colors, underline)
</details>

### 2023 Features
<details>
<summary><strong>July 2023 - Core Features</strong></summary>

- Stripe subscription integration
- Grade skill management table with Turbo Frame
- Classroom students progression tracking
- XLSX export for skills and progression data
</details>

<details>
<summary><strong>February 2023 - Demo System</strong></summary>

- Demo account creation for visitors
- Subscription upgrade workflow (Annual ⇔ Monthly)
</details>

## Original Team - December 2021

> [Erika](https://github.com/97190), [Thomas](https://github.com/ThomasC222) & [Guenolé](https://github.com/Guedeloni) from Batch #756 [Le Wagon Nantes](https://www.lewagon.com/fr/nantes) built the first version.

[First demo video (December 2021)](https://youtu.be/Ngbj4YA7SgM?t=1992)

## License

Proprietary - All rights reserved
