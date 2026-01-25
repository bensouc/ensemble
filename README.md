# Ensemble

A Rails application for managing student work plans, skills progression tracking, and competency-based learning in primary schools. Currently in production and used by teachers in France.

Developed by [VRoad Studio](https://www.vroadstudio.fr)

## Tech Stack

- **Backend**: Ruby on Rails 7.1
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5
- **JavaScript**: esbuild
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq + Redis
- **PDF Generation**: Ferrum (Chrome headless)
- **File Storage**: Cloudinary (Active Storage)
- **Payments**: Stripe
- **Deployment**: Scalingo
- **Testing**: RSpec

## Installation

### Prerequisites
- Ruby 3.3.6+
- PostgreSQL
- Redis
- Node.js 18+
- Yarn
- Chrome (for PDF generation)

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
CLOUDINARY_URL=...
STRIPE_PUBLISHABLE_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
REDIS_URL=...
```

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

## Features History

### January 2026
- **PDF Generation Migration**: Migrated from WickedPdf to Ferrum (Chrome headless) for better rendering
- **Student Results PDF**: Enhanced with belt validation icons and improved layout
- **Work Plan PDF**: Added footer with pagination, student info, and page break optimization
- **esbuild Migration**: Removed Webpacker, now using esbuild for JavaScript bundling
- **Scalingo Deployment**: Optimized with Chrome buildpack for PDF generation
- **Stack Upgrade**: Ruby 3.1.2 → 3.3.6, Rails 7.0 → 7.1.6, Puma 4 → 6 (performance et sécurité)

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
- RSpec test coverage to 100%
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
