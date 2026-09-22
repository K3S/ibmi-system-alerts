---
title: 7. Test and operate
layout: default
nav_order: 8
---

# Prove the behavior before relying on it

Use a dedicated test library, queue, and destination. Feed synthetic check results to an adapted monitor; do not fill an ASP, fail a disk, or interrupt production merely to test alerts.

## Acceptance scenarios

| Scenario | Expected result |
|:--|:--|
| All five checks succeed with no findings | No problem alerts; completed-check timestamps advance. |
| Same MSGW job appears for ten cycles | One initial event; reminders only according to policy. |
| MSGW clears, then returns | Recovery if enabled, then a new incident occurrence. |
| Required job absent during scheduled runtime | Missing-job alert after configured grace period. |
| Job absent outside its operating window | No false missing-job alert. |
| ASP crosses warning, then critical | Alert follows configured escalation policy. |
| Disk state unavailable or query denied | Unknown/check failure, never a healthy assertion. |
| Message survives several polling windows | No repeated initial delivery from repeated reads. |
| Check fails after returning partial results | Existing incidents remain open; failure is visible. |
| Sender cannot connect or receives HTTP 429/500 | Entry remains queued; bounded, delayed retry. |
| HTTP 400 rejects an event | Preserve and flag it; apply pause/quarantine policy. |
| Sender stops after webhook acceptance | A duplicate is possible; no silent loss claimed. |
| Monitor stops after enqueue before state update | Restart may duplicate, but must not silently suppress the event. |
| Queue fills or enqueue authority is removed | Local failure; incident not marked reported. |
| Payload contains quotes, newlines, non-ASCII text | Valid JSON and intact UTF-8 at the receiver. |
| Event exceeds the agreed byte limit | Explicit handling; never truncate JSON into invalid data. |
| Second sender starts | Refused by single-instance protection. |
| Delivery adapter changes | Same event schema reaches the new test destination; unsupported adapters fail visibly. |
| Schedule changes during operation | Valid settings apply at the documented reload/restart boundary; no overlapping checks. |
| New configuration is invalid | Last valid settings remain in effect and an error is visible. |
| Message ID is both included and excluded | Documented precedence is applied consistently. |
| Warning crosses critical and recovery thresholds | Defined escalation/recovery behavior without notification flapping. |
| One of several required destinations fails | Event is not treated as fully delivered; completed destinations are tracked. |
| Monitor or entire IBM i stops | External monitoring detects the missing check-in. |

## Plan the logs and heartbeat

Record check name, start/end time, success/failure, event ID, incident key, and delivery outcome. Keep webhook secrets out of logs. Define retention for local logs, state, and any quarantine queue.

A loop-start timestamp proves very little. Record a successful completion timestamp for each check, and distinguish a cycle that finished with errors from one where all enabled checks succeeded. External monitoring should also observe queue backlog and the last sender success if delivery health matters.

An HMC support heartbeat is not proof that this monitor or its sender is working. If an existing application-monitoring service can independently detect missed check-ins, consider reusing it; confirm its actual capabilities rather than assuming them.

## Keep message polling honest

Only messages still present in a queue can be read by the queue SQL service. If another process removes a message before a poll, this monitor may never see it. Do not clear production queues from this utility. If that gap is unacceptable, evaluate message watches or an event source with appropriate retention.

## Operating instructions your adaptation must include

Document how to start and stop both jobs, where they run, how to see the queue depth, how to disable a check, and how to inspect a failed delivery without consuming it. Configure restart after IPL explicitly. Starting a second copy is not a recovery strategy.

Tune filters from observed events. A message severity is not a business-impact score: 99 can mean routine manual action; a lower-severity message can still matter to your operation.

## Verification record for this starter

| Component | Status |
|:--|:--|
| Five detection-query shapes | Reported working by the originating user, including the corrected message query. |
| Downloadable SQL and RPG examples | Reference source; not executed/compiled on IBM i in this workspace. |
| Full production monitor/sender | Deliberately left for environment-specific implementation. |
| Documentation site | See repository validation and build checks; publishing is a separate step. |

Contribute exact release/PTF details and reproducible results when sharing a successful adaptation.
