---
title: 6. Build it with AI
layout: default
nav_order: 7
---

# Make this your own

A useful AI implementation brief combines a concrete design with facts about your environment. Start by answering the worksheet below, then give the prompt and this repository to your coding assistant.

For specific changes, start with [choose your checks and delivery]({% link guide/customize.md %}): it includes focused prompts for additional checks, other delivery methods, routing, schedules, and severity.

## Configuration worksheet

| Decision | Your answer |
|:--|:--|
| IBM i release and Db2 group PTF | 7.5; record installed SF99950 level |
| Install library and IFS source directory | Example: ALERTDEMO; choose production names separately |
| Required jobs | Job, starting user, subsystem, minimum count |
| Operating windows | Days, times, time zone, overnight schedules, maintenance rules |
| MSGW scope | All jobs or selected subsystems/users? How long before notifying? |
| Storage thresholds | Per ASP warning/critical percentages and minimum free space |
| Disk states | Which reported conditions are actionable? What does HMC already cover? |
| Message queues and rules | Severity baseline, include IDs, exclude IDs; which rule wins? |
| Intervals | 60 seconds for jobs/messages; 300 for storage/disk as a starting point |
| Incident memory | Persistent state table or accept repeated alerts after restart? |
| Repeats and recovery | Initial only? Reminder interval? Recovery notice? |
| Destination | Slack, generic API, email, IBM i message queue, or named local handler |
| Failed delivery | Timeouts, retry schedule, maximum delay, pause/quarantine policy |
| Queue behavior | Single sender, capacity limit, UTF-8 payload size, backlog alert |
| Startup and shutdown | Subsystem/job queue, IPL startup, controlled stop |
| External heartbeat | Which external service notices missed completed-cycle check-ins? |

Download the [example configuration]({{ '/examples/config.example.json' | relative_url }}). It is an implementation worksheet in JSON form, **not configuration consumed by a supplied monitor**.

## Copy this implementation prompt

```text
Build an IBM i 7.5 system-alert utility using the attached starter guide.

My environment and completed configuration worksheet:
[PASTE ANSWERS; use placeholders for webhook credentials]

Architecture requirements:
- One SQLRPGLE polling monitor runs five configurable checks: MSGW,
  missing required jobs, ASP storage, reported disk conditions, and
  selected system messages. A CL wrapper may manage startup and timing.
- Put the complete versioned JSON alert on a FIFO data queue.
  Do not replace queue delivery with an outbox table or queue only an ID.
- Exactly one sender reads the queue without removing an entry, delivers
  to the destination, then removes that same head entry after acceptance.
- An optional incident-state table remembers open conditions, reminders,
  recovery state, and processed-message checkpoints. It is not an outbox.
- Handle the enqueue/state crash window explicitly; prefer a duplicate
  over losing an alert. Do not claim exactly-once webhook delivery.

Start by checking the supplied SQL against my release, PTFs, authorities,
and actual results. Do not invent IBM i columns, APIs, or compile success.

Implement:
1. Configuration outside compiled detection logic, with validation.
2. Per-check scheduling and failure isolation. Only a completed successful
   check can close incidents. Distinguish unknown from healthy.
3. Incident keys, unique event IDs, duplicate suppression, optional
   reminders, and recovery events for state checks.
4. Message checkpoints that advance only after selected events have been
   successfully handled, with overlap and deduplication. Define first-run
   history, retention, queue-clear behavior, and backlog limits.
5. Proper JSON serialization, UTF-8 bytes, and checked queue entry size.
6. A replaceable delivery adapter for my chosen destination. Use Slack or
   a generic JSON webhook as the initial example, or implement the email,
   message queue, or named handler I select. Define destination acceptance
   explicitly. For HTTPS set timeouts and keep TLS verification enabled.
   Load secrets from protected local config; never execute message text.
   Keep routing separate from detection; multi-destination fan-out needs
   durable per-destination acceptance tracking or dedicated queues.
7. Delayed retries respecting rate limits; no tight retry loop. Keep failed
   entries. Explain head-of-line blocking and implement the selected
   pause/quarantine policy without silently dropping events.
8. Queue-depth and sender-health visibility, local logs, controlled stop,
   single-instance protection, restart behavior, and completed-check
   heartbeat state for an external observer.
9. Source, object list, compile/install steps, least-required authorities,
   start/stop commands, upgrade notes, and a removal procedure that does
   not destroy incident history without an explicit operator choice.
10. Tests for the acceptance scenarios in this guide. Separate what was
    statically reviewed, locally tested, and actually run on IBM i.

Implement incrementally: synthetic queue event; one detector; sender in a
test destination; incident state/recovery; remaining detectors; failures
and restarts. Ask only for missing environment decisions. Keep the result
understandable to an RPG/CL maintainer. Do not automatically reply to
inquiries, end jobs, restart jobs, or clear system message queues.
```

## Review what the AI gives you

Ask it to show one incident through every transition and identify the exact point an entry is removed. Check that a timeout preserves the alert, a failed query cannot announce recovery, and a normal job shutdown inside a maintenance window is not a false alarm.

Inspect generated commands before running them. Compile on a test IBM i and record the actual job-log output. A GitHub check can validate documentation and source conventions; it cannot prove RPG compiles without an IBM i compiler.

Next: [test and operate it]({% link guide/operations.md %}).
