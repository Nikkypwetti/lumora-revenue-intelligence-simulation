# Security & Governance

> AI interprets intent. Deterministic controls authorize execution. PostgreSQL permissions enforce the final security boundary.

## Runtime Roles
- **Source RO** — read operational source records.
- **Ingestion RW** — approved raw and ingestion-control writes.
- **Transform RW** — read plus execution of the fixed reporting refresh procedure.
- **Reporting RO** — read approved reporting tables.
- **Control RW** — governance, audit, query-template, and dead-letter operations.

## Controls
- No admin database credential in n8n runtime workflows.
- No arbitrary SQL or dynamic table identifiers from the LLM.
- Secrets remain in n8n Credentials/protected local files and are excluded from Git.
- Checkpoints advance only after verified persistence.
- Failure recovery is run-owner aware and never rewinds a verified cursor.
- Original Revenue Intelligence database remains isolated from the Lumora simulation.
