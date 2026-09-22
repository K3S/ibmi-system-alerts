---
title: 5. Choose your checks and delivery
layout: default
nav_order: 6
---

# Roll your own alerts

The five checks and Slack webhook are starting examples. Keep the monitor, full-alert data queue, and sender pattern; tailor **what you detect, when you check, what matters, and where the alert goes**.

The settings below describe the configuration interface your implementation should provide. They are templates, not switches in a bundled application. Ask your implementer to load and validate them outside compiled code, so routine changes do not require recompiling RPG.

## Find other checks

Start with a plain-language condition, such as “work is backing up in the order job queue.” Explore [IBM i Services](https://www.ibm.com/docs/ssw_ibm_i_74/rzajq/rzajqservicessys.htm) and the [release/PTF availability catalog](https://www.ibm.com/support/pages/node/1119123). Services include views, table functions, and procedures; use read-only operations when exploring a detector.

| You want to investigate | Services or data to explore | Rule you still need to define |
|:--|:--|:--|
| Job queue backlog | `QSYS2.JOB_QUEUE_INFO`, `QSYS2.JOB_INFO` | Expected queue, count, age, and operating hours. |
| Printing backlog | `QSYS2.OUTPUT_QUEUE_INFO`, `QSYS2.OUTPUT_QUEUE_ENTRIES` | Ready work waiting too long, stopped writers, expected activity. |
| Lock waits | `QSYS2.OBJECT_LOCK_INFO`, `QSYS2.JOB_LOCK_INFO` | Which waiters matter and how long is too long. |
| Temporary storage growth | `QSYS2.SYSTMPSTG`, `QSYS2.ACTIVE_JOB_INFO` | Size, growth across samples, and responsible jobs. |
| Historical events | `QSYS2.HISTORY_LOG_INFO` | Relevant IDs, durable processing position, and retention. |
| User profile conditions | `QSYS2.USER_INFO` | Relevant profiles and the specific disabled/expiration condition. |
| Application-specific issues | Your application tables or a documented health query | What business outcome should have occurred by now. |

These are discovery leads, not ready-made alarms. Verify the service's columns, authorities, scope, and release requirements in IBM documentation. A service may not supply every fact your rule needs; elapsed duration often requires saved observations.

1. Write the condition and who should respond.
2. Find the service and inspect a small, relevant result in ACS.
3. Define a stable incident identity, threshold, persistence period, and recovery rule.
4. Distinguish a successful empty result from a failed or unauthorized query.
5. Emit the existing event format and use the same data queue.

**Prompt: add a check**

```text
Using this guide, add a check for [CONDITION] on IBM i 7.5 with Db2 PTF
[LEVEL]. First find the appropriate IBM-documented service and verify its
columns, authorities, and availability. Give me a read-only ACS query and
explain what it proves and misses. My scope is [JOBS/QUEUES/OBJECTS].
Trigger after [THRESHOLD/DURATION], recover when [RULE], and use [HOURS].
Add configuration, incident identity, unknown/error handling, and tests.
Emit the existing full JSON event to the existing data queue. Do not add
a separate sender or assume this service can directly measure duration.
```

## Send the alert somewhere else

The sender has a replaceable **delivery adapter**: a small piece of code that translates an alert into the destination's expected format and reports whether it was accepted. Detection code does not need to know whether the final destination is Slack, email, or something internal.

```text
Checks → Full JSON alert → Data queue → Sender → Your chosen adapter
                                               ├─ Slack webhook
                                               ├─ Another HTTPS API
                                               ├─ Email
                                               ├─ IBM i message queue
                                               └─ Named local handler
```

The branches illustrate alternatives; broadcasting to all of them is a separate enhancement.

| Destination | What the adapter needs | What counts as success |
|:--|:--|:--|
| Another Slack webhook | Protected URL and Slack payload | Slack's documented acceptance response. |
| Generic webhook or ticket API | Endpoint, authentication, request format | Documented response, possibly a ticket/receipt ID. |
| Email | Your supported mail service, recipients, subject/body | Mail service accepted the message; not proof someone read it. |
| IBM i message queue | Configured library/queue and message format | Successful enqueue through the selected IBM-supported interface. |
| Local log or named program | Approved path or configured program interface | A documented successful write or return status. |

Choose one destination first. Store the real webhook URL or credentials in protected local configuration, referenced by name. For example, replace the `delivery` object in the worksheet:

```json
{
  "delivery": {
    "adapter": "email",
    "settings_reference": "LOCAL_PROTECTED_MAIL_SETTINGS"
  }
}
```

This example requests an email adapter; it does not implement mail delivery. The implementation should reject an unsupported adapter rather than silently discard the alert. Changing from one configured Slack endpoint to another should only require a settings change; introducing a new transport needs an adapter first.

**Prompt: change delivery**

```text
Adapt this guide's sender to deliver via [EMAIL / API / MESSAGE QUEUE /
NAMED LOCAL HANDLER]. Here is the destination documentation and desired
format: [DETAILS]. Keep the full-alert data queue and single-consumer
design. Put destination settings in protected local configuration.
Implement an adapter with explicit success, retryable failure, and
permanent failure outcomes. Preserve the event until acceptance and
document what acceptance proves. Add a synthetic-event test, timeout/
failure tests, and a configuration example without real credentials.
Keep destination logic out of the detection queries.
```

For a local handler, configure the program name and parameter contract yourself. Do not interpret message text or queue payloads as CL commands. If the desired action changes jobs or system state, define that specific action, its permissions, and repeat-execution behavior explicitly; the default design only notifies.

### What if different alerts go to different places?

A routing rule could send warnings to one destination and critical incidents to another. Keep the route and event ID stable across retries. Start with one destination per event and define a default route for unmatched events.

Sending one event to several destinations needs more design: track each destination's acceptance durably, or use dedicated destination queues and define the fan-out failure behavior. Never remove the original merely because the first destination accepted it. A single shared queue with competing consumers is not a broadcast mechanism.

**Prompt: add routing**

```text
Add routing to this sender: [CHECK/PRIORITY] goes to [DESTINATION], with
[DESTINATION] as the default. Choose one destination per event initially.
Persist or embed the selected route so retries do not change it. Show the
configuration, unmatched-route handling, recovery routing, and tests.
If I later request multiple destinations per event, explain and implement
per-destination acceptance tracking before enabling fan-out.
```

## Change when it checks

Polling frequency, operating hours, persistence before alerting, and reminder frequency are separate controls.

| Control | Example | Meaning |
|:--|:--|:--|
| Check interval | 60 seconds | How often the monitor looks. |
| Operating window | Monday–Friday, 06:00–20:00 | When a particular job is expected to exist. |
| Persistence/grace period | 120 seconds | How long a condition must remain observed before notifying. |
| Reminder interval | 30 minutes | How often to repeat an already-open incident. |
| Maintenance window | Planned Sunday IPL | A defined exception; specify whether checks continue or notifications pause. |

In the [configuration worksheet]({{ '/examples/config.example.json' | relative_url }}), change a check interval from `60` to `300` for five-minute polling:

```json
{
  "check_intervals_seconds": {
    "msgw": 60,
    "missing_jobs": 60,
    "system_messages": 60,
    "storage": 300,
    "disk_health": 300
  },
  "reminder_minutes": 30
}
```

Five-minute polling can take nearly five minutes to notice a new condition, plus check runtime and delivery delay. A grace period adds further delay. Conditions that begin and end between samples can be missed. A persistence period means “observed at consecutive successful checks”; it does not prove continuous state between observations.

**Prompt: change scheduling**

```text
Make intervals, operating windows, grace periods, maintenance windows,
and reminders configurable without recompiling. Use [TIME ZONE]. Check
[CHECK] every [SECONDS], active during [DAYS/HOURS], and alert only after
[DURATION]. Define overnight windows and daylight-saving behavior.
Validate positive intervals, prevent overlapping runs, and explain whether
settings reload each cycle or require a controlled restart. Invalid new
settings must preserve the last valid configuration and surface an error.
Define whether maintenance suppresses delivery or suspends checks, how
incidents reconcile afterward, and test all boundary cases.
```

## Change severity and thresholds

There are three different decisions:

1. **IBM message severity:** a source-message property, filtered by `message_min_severity` plus include/exclude IDs.
2. **Check thresholds:** your rule, such as ASP percent used or how long a job is missing.
3. **Alert priority:** your own INFO/WARNING/CRITICAL classification, used for delivery or routing.

For example, changing `message_min_severity` from `70` to `80` narrows the message filter. It does not change IBM's message definitions, storage rules, or MSGW detection. Some important low-severity message IDs still need explicit inclusion.

```json
{
  "message_min_severity": 80,
  "message_include_ids": [],
  "message_exclude_ids": [],
  "message_rule_precedence": "exclude, then include, then severity",
  "storage_warning_percent": 85,
  "storage_critical_percent": 92
}
```

These are example values, not recommended capacity limits. With the illustrated precedence, an excluded ID is ignored even if its severity is high; an included ID passes regardless of the threshold. The remaining messages use the severity threshold. Review exclusions carefully and test the exact IDs you choose.

Avoid noisy threshold crossings by defining a separate recovery threshold—for example, a warning opens at 85% but clears below 82%. Define escalation from warning to critical, downgrades, and reminders explicitly. IBM severity 99 can describe routine operator action; your priority mapping should account for message meaning and business impact.

**Prompt: change severity policy**

```text
Make message severity, include/exclude IDs, metric thresholds, recovery
thresholds, and operational priority mapping configurable. My policy is
[RULES]. Preserve the distinction between IBM message severity and our
alert priority. Use exclusion before inclusion before severity unless I
specify otherwise. Show before/after example events, validate threshold
ordering, and test escalation, recovery, duplicate suppression, and
configuration reload while an incident is already open. Do not change
IBM message descriptions or silently suppress other types of checks.
```

Next: [assemble your implementation brief]({% link guide/tailor.md %}).
