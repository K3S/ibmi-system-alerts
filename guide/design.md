---
title: 1. How it works
layout: default
nav_order: 2
---

# One monitor, one queue, one sender

Five checks do not require five independent applications. One polling program runs the checks when they are due and writes new alerts to an IBM i data queue. One sender waits for queue entries and delivers them.

```text
MSGW ──────────────────────┐
Missing required jobs ─────┤
Low storage ───────────────┼─ One monitor ─ ALERTQ ─ One sender ─ HTTPS webhook
Disk health ───────────────┤       │
Important messages ────────┘       └─ Incident state / message checkpoint

External monitoring observes the monitor's completed-cycle heartbeat.
```

## Follow one incident

At 10:01, a required job is missing. The monitor creates a stable incident key from the check and job identity. It gives this particular alert a unique event ID, builds a JSON event, and enqueues it. After the enqueue succeeds, it records that the incident was reported.

The sender reads the head of the FIFO queue **without removing it**, validates the event, and formats a payload for its destination. After confirmed acceptance, it receives the same head entry with removal enabled. This design assumes exactly one consumer and no other process clearing or consuming the queue.

At 10:02, the job is still missing. The monitor recognizes the active incident and does not enqueue the same initial alert again. At 10:06, the job is back. A successful check can produce a recovery event and close the incident.

## Choose the polling interval

| Check | Suggested starting interval | Why |
|:--|:--|:--|
| MSGW | 60 seconds | Someone may be waiting to continue processing. |
| Required jobs | 60 seconds | Detect absence promptly. |
| Messages | 60 seconds | Pick up new operational events. |
| Storage | 300 seconds | Begin with a lower sampling frequency; shorten if growth demands it. |
| Disk status | 300 seconds | Complement existing hardware alerts. |

These are design defaults, not guarantees. Measure query duration on your system. A simple loop that sleeps 60 seconds after work has a cycle longer than 60 seconds. An implementation should schedule the next due time explicitly and avoid overlapping cycles when a check runs slowly.

## Keep detection and delivery separate

The monitor should not wait on a slow HTTPS request. Its job is to detect, classify, and enqueue. The sender owns destination formatting, timeouts, response interpretation, retries, and delivery failures.

The full event is in the data queue. A state table, if used, only holds incident state and message checkpoints. A separate delivery log is optional for audit and troubleshooting; it is not the delivery mechanism.

## Know the failure windows

| What happens | Intended behavior |
|:--|:--|
| A query fails | Record a failed check; do not interpret an empty or partial result as recovery. |
| Enqueue fails or queue is full | Do not mark the incident reported. Log locally and retry on a later cycle. |
| Monitor stops after enqueue but before saving state | A duplicate may occur after restart. Keep the same incident identity. |
| Webhook rejects or times out | Keep the queue entry; retry with a delay. |
| Destination accepts but sender stops before removal | The event may be delivered again. Event IDs help investigation or receiver-side deduplication. |
| A bad event stays at the queue head | Pause and flag it, or quarantine it using a documented, tested policy. |
| Entire system stops | An external service detects a missed check-in. |

There is no atomic transaction spanning a normal data queue, incident state, and an external webhook. Do not promise exactly-once delivery. Prefer a possible duplicate over silently discarding an alert.

## State alerts versus event alerts

MSGW, missing jobs, low storage, and disk conditions are ongoing states. They can open, remain active, and recover. A queue message is an event: its disappearance does not mean its underlying problem recovered. Message handling needs a processed-event checkpoint and duplicate tracking, not automatic recovery when a message ages out.

Next: [prepare your environment]({% link guide/setup.md %}).
