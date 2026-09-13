# Security Policy

[← Project README](README.md) · [Contributing](CONTRIBUTING.md) · [Documentation hub](docs/README.md)

Security reporting, supported versions, and operating boundaries for European Tech Opportunities 2027.

## Reporting a vulnerability

Do not disclose security vulnerabilities in a public issue, discussion, pull request, or listing suggestion.

| Channel | Contact |
|---|---|
| GitHub private vulnerability reporting | [Open a private security advisory](https://github.com/simonesiega/european-tech-opportunities-2027/security/advisories/new) |
| Email | [simonesiega1@gmail.com](mailto:simonesiega1@gmail.com) |

For email reports, use the subject `[SECURITY] Brief vulnerability summary`.

Please include:

- a concise summary and potential impact;
- the affected command, workflow, website surface, or trust boundary;
- a minimal deterministic reproduction using synthetic or redacted data;
- required configuration, permissions, and attacker access;
- OS, runtime, project version or commit, and execution path;
- a suggested mitigation, if available.

Do not send credentials, cookies, sessions, private HTML, complete environment files, production databases, SQLite sidecars, or unredacted private paths and headers.

### What to expect

The maintainer will make a reasonable effort to acknowledge complete reports, reproduce the issue, assess affected versions, coordinate a fix and regression tests, and agree on disclosure timing.

Response time depends on severity and reproducibility; no service-level agreement is provided. Avoid public disclosure until remediation or coordinated disclosure.

## Supported versions

Security fixes target `main` and, when practical, the latest published release. Older releases and commits receive best-effort support only.

## Security boundaries

| Surface | Security contract |
|---|---|
| Source access | Authorized public LinkedIn guest HTML only |
| Authentication | No LinkedIn credentials, sessions, cookies, account tokens, or browser storage |
| Transport | Fixed HTTPS hosts, disabled redirects, and bounded pacing, concurrency, retries, timeouts, and response sizes |
| Processing | Local deterministic parsing and classification with sanitized errors |
| Persistence | Canonical SQLite writes through repository transactions and Alembic migrations |
| Website | Read-only SQLite, validated links, no mutation API, and defensive production headers |
| README | Bounded generated projection with atomic replacement |
| Automation | Offline validation separated from authorized collection, with verified durable snapshots and atomic deployment |
| Containers | Unprivileged processes, explicit mounts, pinned images, and reduced runtime tooling |

Detailed behavior is documented in [Architecture](docs/guides/development/architecture.md), [Configuration](docs/guides/getting-started/configuration.md), [Database](docs/guides/operations/database.md), [Automation](docs/guides/operations/automation.md), and [Docker](docs/guides/operations/docker.md).

### Collection boundary

LinkedIn requests remain blocked unless the relevant authorization interlock is enabled. The interlock records an operator decision; it does not grant permission.

Operators must obtain and retain express authorization and follow applicable policies, terms, laws, and project limits.

The project does not implement or accept:

- LinkedIn credentials, sessions, cookies, authentication headers, or account tokens;
- logged-in or browser-based collection;
- CAPTCHA solving, challenge bypass, proxy rotation, or fingerprint evasion;
- private or internal APIs;
- redirect-based endpoint discovery;
- collection from unrelated providers.

Never weaken or default-enable an authorization gate. An upstream block or challenge is a stop condition.

### Data and website boundary

`data/opportunities.db` contains public listing metadata and sensitive operational history. It must never contain credentials, sessions, or authenticated HTML.

The website must not:

- run collection, migrations, or lifecycle writes;
- expose mutation endpoints;
- expose database paths, environment values, stack traces, or server configuration;
- render database values as untrusted raw HTML;
- emit external links outside validated public HTTPS listing URLs.

Authentication, forms, user content, saved applications, write APIs, or administration interfaces require explicit architecture and security review.

## What to report

Report issues that could:

- bypass source authorization or request bounds;
- expose credentials, private state, paths, headers, or environment values;
- request unexpected hosts or follow unsafe redirects;
- cause code execution, injection, path traversal, arbitrary file access, or unsafe filesystem writes;
- let malformed source data corrupt lifecycle state or public output;
- let failed searches close or mutate listings;
- corrupt or silently discard canonical state during migration, backup, restore, or deployment;
- publish private state through logs, caches, artifacts, images, or workflows;
- compromise dependencies, Actions, containers, snapshots, or deployment credentials;
- make the website write SQLite, expose internal data, or omit required browser protections.

### Usually not a security issue

The following normally belong in a sanitized public issue unless they cross a security boundary:

- missed or misclassified listings;
- distinct duplicate IDs;
- source markup changes;
- stale generated projections;
- conservative delayed closure;
- ordinary `403`, `429`, timeout, or challenge responses.

## Secrets and release security

Never commit or publish:

- `.env` contents or tokens;
- LinkedIn credentials, cookies, sessions, or browser storage;
- GitHub, package, deployment, or SSH credentials;
- private proxy or host configuration;
- authenticated HTML;
- production databases or sidecars.

Use synthetic placeholders and minimal sanitized fixtures.

If a secret is exposed, revoke or rotate it immediately, remove it from current files and repository history where appropriate, and review logs, artifacts, caches, and deployments. A later deletion commit is not sufficient.

For dependencies and releases:

- commit `uv.lock` and `site/bun.lock`, and use frozen installs;
- pin Actions and CI tool images to immutable revisions where practical;
- review weekly Dependabot updates for Python, website, Actions, and Docker inputs;
- lint workflows and Dockerfiles, reject fixable high or critical image vulnerabilities, and verify production security headers in CI;
- keep version references synchronized across metadata, lockfiles, images, user agents, and documentation;
- publish only from a clean, validated tree;
- protect deployment keys, artifacts, caches, snapshots, backups, and package credentials with least privilege.

## Responsible disclosure

Test only systems and data you own or are explicitly authorized to test.

Minimize requests and data access, prefer local fixtures, avoid affecting other users or availability, and stop after demonstrating the issue.

This policy does not authorize testing against LinkedIn, GitHub, the production VPS, or any third party. Never use a vulnerability to bypass access controls. Coordinate disclosure with the maintainer.
