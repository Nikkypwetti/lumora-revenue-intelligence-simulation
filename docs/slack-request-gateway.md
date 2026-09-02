# LUMORA-REVINT-05 — Slack Request Gateway

## Purpose

`LUMORA-REVINT-05 | Slack Request Gateway` adds governed Slack request intake to the Lumora Revenue Intelligence simulation.

The gateway does not implement reporting logic itself. It converts a trusted Slack `app_mention` event into the standard Revenue Intelligence request envelope and invokes `LUMORA-REVINT-01 | Manager Request Orchestrator`.

```text
Slack app mention
  -> trusted channel enforcement
  -> normalize Slack request
  -> LUMORA-REVINT-01
  -> deterministic KPI/query governance
  -> read-only PostgreSQL reporting
  -> result validation
  -> trusted Slack destination resolution
  -> Slack manager report
  -> delivery audit
```

## Trusted development channel

- Channel name: `lumora-revint-reports-dev`
- Channel ID: `C0BUK581XRN`
- Trigger event: `app_mention`

The inbound trigger is scoped to the trusted development reporting channel. The normalization node also enforces `C0BUK581XRN` before handoff, providing a second deterministic channel boundary. The manager message cannot choose a database query or external delivery destination.

## Import

Import:

`n8n/LUMORA-REVINT-05 _ Slack Request Gateway.json`

The repository export is intentionally inactive and contains no Slack credential binding, signing secret, access token, local n8n instance ID, workflow version ID, or local error-workflow ID.

After import:

1. Open `INT | Slack Manager Request`.
2. Select the existing Lumora Slack API credential.
3. Keep Event = `app_mention`.
4. Keep Channel = `C0BUK581XRN` / `lumora-revint-reports-dev`.
5. Keep Resolve IDs = false.
6. Confirm `INT | Submit Governed Slack Request` points to `LUMORA-REVINT-01 | Manager Request Orchestrator`.
7. If the environment uses the Lumora error workflow, reselect it in workflow settings after import rather than relying on an instance-specific exported workflow ID.
8. Keep the gateway inactive until the local simulated test and Slack Request URL verification pass.

Slack credentials, tokens, and signing secrets must remain in n8n Credentials and are not stored in the workflow export.

## Test 1 — local simulated request

This test does not require Slack to reach the local n8n instance.

1. Open the imported gateway.
2. Run `INT | Test Slack Request`.
3. `CTX | Build Simulated Slack Event` creates a simulated `app_mention` event for:

```text
Show me closed won revenue this month
```

4. `CTX | Normalize Slack Request` should produce a standard request envelope with:

```json
{
  "channel": "slack",
  "requester_id": "portfolio_manager_001",
  "requester_name": "portfolio_manager_001",
  "question": "Show me closed won revenue this month",
  "source": "slack_app_mention",
  "environment": "development",
  "status": "received"
}
```

5. The normalization node must reject a payload whose `event.channel` is not `C0BUK581XRN`.
6. `INT | Submit Governed Slack Request` should invoke `LUMORA-REVINT-01`.
7. REVINT-01 must still apply the existing KPI catalogue, approved query resolution, runtime parameter validation, read-only PostgreSQL access, result validation, presentation controls, trusted Slack destination resolution, delivery validation, and audit controls.

## Test 2 — real Slack app mention

Slack Events API delivery requires Slack to reach the trigger endpoint. A localhost-only n8n URL cannot receive Slack HTTP Events API callbacks directly.

For the verified development setup:

1. n8n was exposed through a temporary HTTPS Cloudflare Quick Tunnel for testing.
2. `N8N_WEBHOOK_URL` was set to the public HTTPS tunnel origin and `N8N_PROXY_HOPS=1` was configured.
3. The Slack app used for inbound events was the actual `Revenue Intelligence Reporter` app, not the separate n8n-related Slack app.
4. Socket Mode was disabled so Events API delivery used the HTTP Request URL.
5. Event Subscriptions was enabled and the Slack Trigger production webhook URL was verified.
6. The bot subscribed to `app_mention` and had the required `app_mentions:read` scope.
7. The app was installed in `lumora-revint-reports-dev`.
8. The Slack signing secret remained in the n8n Slack credential.
9. `LUMORA-REVINT-05` was published only after URL verification.

The Cloudflare Quick Tunnel is a temporary development mechanism. Its hostname can change after restart and should not be treated as a permanent production endpoint.

A verified live request was sent in the trusted channel:

```text
@Revenue Intelligence Reporter Show me closed won revenue this month
```

The Slack mention markup was removed before the request entered REVINT-01.

## Live verification result — 2026-09-02

The final restricted-channel test completed end-to-end with a real Slack `app_mention` event.

Verified output included:

```text
channel = slack
source = slack_app_mention
validation_status = valid
workflow_stage = slack_delivery_succeeded
external_delivery = true
delivery_status = sent
expected_channel_id = C0BUK581XRN
actual_channel_id = C0BUK581XRN
sent_text_matches_payload = true
event_type = slack_delivery_succeeded
event_status = recorded
```

The live request used a real Slack requester ID and returned the governed report through the trusted Slack channel. n8n appended its standard attribution line after the approved payload; the delivery validator recorded this as `SLACK_N8N_ATTRIBUTION_APPENDED` while still confirming `sent_text_matches_payload = true`.

## Troubleshooting lesson from live verification

The initial live mentions produced no REVINT-05 execution even though the Request URL verified successfully. The root cause was that Event Subscriptions had been configured on a different Slack app. The bot actually being mentioned was `Revenue Intelligence Reporter`.

A useful diagnostic sequence is:

```text
real Slack mention exists
-> confirm correct Slack app owns the mentioned bot
-> confirm Socket Mode is OFF for HTTP Events API delivery
-> confirm Event Subscriptions uses the Slack Trigger production URL
-> confirm app_mention + app_mentions:read
-> confirm workflow is active
-> only then inspect downstream REVINT-01
```

If REVINT-05 never starts, the downstream Revenue Intelligence orchestrator is not yet involved.

## Security boundary

- Slack is an intake channel, not an authorization layer.
- The Slack Trigger is restricted to `C0BUK581XRN`.
- The normalization node independently rejects any event whose channel is not `C0BUK581XRN`.
- Bot-generated Slack messages are rejected to reduce loop risk.
- AI interprets intent only; it does not generate executable SQL or authorize queries.
- Approved deterministic controls decide which KPI/query contract can run.
- PostgreSQL read-only permissions remain the final reporting-data access boundary.
- Slack destination identifiers are resolved from trusted configuration inside REVINT-01, not from manager text or AI output.
- The gateway does not contain Slack tokens, signing secrets, database credentials, SQL templates, or unrestricted destination IDs.

## Verification status

- Workflow export built: yes
- Local simulated gateway path: verified
- Real Slack Request URL verification: verified
- Real Slack `app_mention` intake: verified
- Trusted-channel enforcement: verified
- REVINT-05 -> REVINT-01 handoff: verified
- Governed reporting execution: verified
- Real external Slack delivery: verified
- Expected vs actual Slack destination validation: verified
- Delivery success audit: verified
- Live verification date: 2026-09-02
