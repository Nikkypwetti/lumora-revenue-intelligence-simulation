# LUMORA-REVINT-05 — Slack Request Gateway

## Purpose

`LUMORA-REVINT-05 | Slack Request Gateway` adds governed Slack request intake to the Lumora Revenue Intelligence simulation.

The gateway does not implement reporting logic itself. It converts a trusted Slack `app_mention` event into the standard Revenue Intelligence request envelope and invokes `LUMORA-REVINT-01 | Manager Request Orchestrator`.

```text
Slack app mention
  -> Normalize Slack request
  -> LUMORA-REVINT-01
  -> deterministic KPI/query governance
  -> read-only PostgreSQL reporting
  -> result validation
  -> trusted Slack destination resolution
  -> Slack manager report
```

## Trusted development channel

- Channel name: `lumora-revint-reports-dev`
- Channel ID: `C0BUK581XRN`
- Trigger event: `app_mention`

The inbound trigger is intentionally scoped to the trusted development reporting channel. The manager message cannot choose a database query or external delivery destination.

## Import

Import:

`n8n/LUMORA-REVINT-05 _ Slack Request Gateway.json`

After import:

1. Open `INT | Slack Manager Request`.
2. Select the existing Lumora Slack API credential.
3. Keep Event = `app_mention`.
4. Keep Channel = `C0BUK581XRN` / `lumora-revint-reports-dev`.
5. Confirm `INT | Submit Governed Slack Request` points to `LUMORA-REVINT-01 | Manager Request Orchestrator`.
6. Keep the gateway inactive until the local simulated test passes.

Slack credentials, tokens, and signing secrets must remain in n8n Credentials and are not stored in this workflow export.

## Test 1 — local simulated request

This test does not require Slack to reach the local n8n instance.

1. Open the imported gateway.
2. Run `INT | Test Slack Request`.
3. `CTX | Build Simulated Slack Event` creates a simulated `app_mention` event.
4. `CTX | Normalize Slack Request` should output:

```json
{
  "channel": "slack",
  "requester_id": "portfolio_manager_001",
  "requester_name": "portfolio_manager_001",
  "question": "Show me open pipeline",
  "source": "slack_app_mention",
  "environment": "development",
  "status": "received"
}
```

5. `INT | Submit Governed Slack Request` should invoke `LUMORA-REVINT-01`.
6. REVINT-01 must still apply the existing KPI catalogue, approved query resolution, runtime parameter validation, read-only PostgreSQL access, result validation, presentation controls, trusted Slack destination resolution, delivery validation, and audit controls.

## Test 2 — real Slack app mention

Slack Events API delivery requires Slack to be able to reach the trigger endpoint. A localhost-only n8n URL cannot receive Slack HTTP Events API callbacks directly.

Before the real test:

1. Provide n8n with a publicly reachable HTTPS webhook endpoint or deploy the workflow behind an approved HTTPS reverse proxy/host.
2. Do not expose the n8n editor or port `5678` directly to the public internet merely to receive Slack events.
3. In the Slack app configuration, enable Event Subscriptions and use the production webhook URL provided by the Slack Trigger node as the Request URL.
4. Subscribe the bot to the `app_mention` event.
5. Ensure the Slack app is installed in `lumora-revint-reports-dev`.
6. Keep a Slack signing secret configured in the n8n Slack credential so inbound Slack requests can be authenticated.
7. Activate/publish `LUMORA-REVINT-05` only after the Request URL is verified.

Then send a message in the trusted channel such as:

```text
@Lumora Revenue Intelligence Show me open pipeline
```

The Slack mention markup is removed before the request enters REVINT-01.

## Security boundary

- Slack is an intake channel, not an authorization layer.
- Bot-generated Slack messages are rejected by the normalization node to reduce loop risk.
- AI interprets intent only; it does not generate executable SQL or authorize queries.
- Approved deterministic controls decide which KPI/query contract can run.
- PostgreSQL read-only permissions remain the final reporting-data access boundary.
- Slack destination identifiers are resolved from trusted configuration inside REVINT-01, not from manager text or AI output.
- The gateway does not contain Slack tokens, signing secrets, database credentials, SQL templates, or unrestricted destination IDs.

## Verification status

- Workflow export built: yes
- Local simulated gateway path: ready for verification after import
- Real Slack app-mention path: requires reachable HTTPS Slack Events API endpoint and live verification
