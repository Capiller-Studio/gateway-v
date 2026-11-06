# Capiller Rely Gateway

The high-performance, enterprise-grade API gateway for Capiller Rely. Built with **Rails 8 (API-only mode)** and **Grape**.

## Architecture & Performance
- **Grape API**: Provides a robust, DSL-based routing layer that is faster and more lightweight than standard Rails controllers.
- **Blueprinter Serialization**: We use Blueprinter for data transformation. It is optimized for performance and handles complex associations with minimal overhead.
- **Oj JSON**: Configured as the default JSON engine for maximum throughput.
- **Stateless Design**: Optimized for horizontal scalability.

---

## Directory Structure

- `app/api/base.rb`: The main router mounting all versions.
- `app/api/defaults.rb`: Shared Grape configuration (rescues, formatters).
- `app/api/v1/root.rb`: V1 entry point.
- `app/api/v1/entities/`: Blueprinter serializers.
- `app/api/v1/helpers/`: Auth and pagination helpers.
- `app/api/v1/resources/`: Organized API endpoints.

---

## Authentication

The Gateway supports dual authentication strategies:

1. **JWT (JSON Web Token)**:
   - Header: `Authorization: Bearer <token>`
   - Purpose: Short-lived sessions for interactive users (Dashboards, Mobile Apps).
2. **API Key**:
   - Header: `X-Api-Key: <token>`
   - Purpose: Long-lived programmatic access for developers and external integrations (uses `AccessToken` model).

---

## Setup & Running

1. **Install Dependencies**:
   ```bash
   bundle install
   ```

2. **Database**:
   Shared with the other Capiller Rely apps. Ensure `core` migrations are up to date.

3. **Run Server**:
   ```bash
   # Run on port 3004 by default
   PORT=3004 bin/rails server
   ```

---

## Development Guidelines

- **Always Version**: All new endpoints must be placed under a versioned namespace (e.g., `V1`).
- **Use Entities**: Never return raw ActiveRecord objects. Always wrap them in a Blueprinter Entity.
- **Validate Parameters**: Use Grape's built-in `params` block to enforce strong typing and presence.

---

## License
Techbolic Solutions (Private) Limited. All rights reserved.
