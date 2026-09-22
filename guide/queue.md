---
title: 4. Build the queue handoff
layout: default
nav_order: 5
---

# Put the actual alert on a data queue

This exercise creates a test queue, compiles a small producer, and inspects a synthetic JSON event. It does not start a monitoring loop or send a webhook.

## 1. Create test objects

Run these CL commands in your IBM i command environment, using a new dedicated library. Do not run the create-library command over an existing installation.

```cl
CRTLIB LIB(ALERTDEMO) TEXT('System alerts learning examples') AUT(*EXCLUDE)
CRTDTAQ DTAQ(ALERTDEMO/ALERTQ) TYPE(*STD) MAXLEN(8192) SEQ(*FIFO) FORCE(*YES) AUT(*EXCLUDE)
```

The 8,192-byte queue limit is a template choice. The producer and receiver must agree on it and on UTF-8 encoding. `FORCE(*YES)` writes queue changes to auxiliary storage during send/receive operations, with additional overhead; it does not provide exactly-once external delivery or a complete backup strategy.

Use the creator profile for the exercise, or grant the intended profiles the necessary library and queue access. Do not grant public access to operational message contents merely to resolve an authority error.

## 2. Upload and compile the producer

Download [ALRTDEMO.sqlrpgle]({{ '/examples/rpg/ALRTDEMO.sqlrpgle' | relative_url }}) and upload it as a UTF-8 stream file to `/home/YOURUSER/ibmi-system-alerts/examples/rpg/ALRTDEMO.sqlrpgle`. Replace YOURUSER with your own directory.

```cl
CRTSQLRPGI OBJ(ALERTDEMO/ALRTDEMO) SRCSTMF('/home/YOURUSER/ibmi-system-alerts/examples/rpg/ALRTDEMO.sqlrpgle') OBJTYPE(*PGM) COMMIT(*NONE) DBGVIEW(*SOURCE)
CALL PGM(ALERTDEMO/ALRTDEMO)
```

The source uses free-format RPG and embedded SQL. SQL constructs the JSON and `QSYS2.SEND_DATA_QUEUE_UTF8` places the whole payload on the queue. The program displays whether enqueue succeeded. Inspect the compiler listing/job log if compilation or a service call fails.

This small producer is reference source and has not been compiled in the authoring workspace. A successful local documentation build is not an IBM i compilation result.

## 3. Inspect without consuming

Run this in ACS. Repeating it should show the same head event because `REMOVE` is `NO`.

```sql
SELECT MESSAGE_DATA_UTF8
FROM TABLE(
    QSYS2.RECEIVE_DATA_QUEUE(
        DATA_QUEUE => 'ALERTQ',
        DATA_QUEUE_LIBRARY => 'ALERTDEMO',
        REMOVE => 'NO',
        WAIT_TIME => 0
    )
) AS Q;
```

After inspecting the synthetic event, you may change `REMOVE` to `YES` to consume **one test entry**. Do this only on the dedicated test queue with no sender running. A production sender removes an entry only after delivery is accepted.

## 4. Agree on the event format

Download [event.example.json]({{ '/examples/event.example.json' | relative_url }}). Keep the queue event independent of Slack formatting so another sender adapter can consume the same design.

| Field | Purpose |
|:--|:--|
| `schema_version` | Reject or explicitly handle unsupported formats. |
| `event_id` | Identify this notification attempt across retries. |
| `incident_key` | Match repeated observations to the same condition. |
| `system`, `check` | Identify where and how it was detected. |
| `transition` | OPEN, REMINDER, RECOVERY, or EVENT, according to check type. |
| `priority` | Your operational priority, separate from IBM message severity. |
| `observed_at`, `time_basis` | An unambiguous observation time; use UTC or an offset in production. |
| `summary`, `details` | Human-readable text and structured supporting facts. |

The tiny producer labels its timestamp as IBM i job-local time for demonstration. Your adaptation should emit an explicit UTC or offset timestamp. Proper JSON serialization handles quotes and line breaks; do not concatenate raw message text into JSON.

## 5. Add a destination adapter

A Slack incoming webhook expects a Slack payload, not the entire event schema. Its adapter might serialize:

```json
{
  "text": "[PROD1] MSGW: 123456/APPUSER/ORDERJOB is waiting for a reply"
}
```

Another webhook may accept the full event. Document that endpoint's payload and acceptance contract. For Slack, verify the expected successful HTTP response and body; for a generic receiver, use its documented contract.

The native SQL sender can call `QSYS2.HTTP_POST_VERBOSE` and inspect its response header/body. Configure content type, JSON response-header formatting, connection timeout, and I/O timeout. Preserve certificate verification and check your installed HTTP options before compiling.

```json
{
  "headers": {"Content-Type": "application/json; charset=utf-8"},
  "verboseResponseHeaderFormat": "json",
  "connectTimeout": "10",
  "ioTimeout": "30"
}
```

Keep the real URL in protected local configuration, not source or a command parameter that might be recorded in a job log. A webhook call that times out may already have been accepted; retrying can duplicate it.

## 6. Build the loop around it

Use the [monitor flow template]({{ '/examples/monitor.pseudocode.txt' | relative_url }}) and [sender flow template]({{ '/examples/sender.pseudocode.txt' | relative_url }}). These are intentionally labeled pseudocode. They specify behavior for the implementation you or your AI assistant will create.

A sender should wait on an empty queue rather than repeatedly query it. With one FIFO consumer it can peek, deliver, and then remove. A permanently failing head entry blocks later events until handled. Choose a pause-and-alert policy or a separate quarantine queue; persist/quarantine before removing, and account for duplicate possibilities across crashes.

Webhooks are one adapter choice. For email, an IBM i message queue, or a named local handler, define what successful delivery means and retain the same peek/deliver/remove contract.

Next: [choose your checks and delivery]({% link guide/customize.md %}).
