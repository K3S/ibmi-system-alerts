---
title: 3. Try the five checks
layout: default
nav_order: 4
---

# Explore your system in ACS

Run these statements individually in **ACS → Run SQL Scripts**. They are read-only and do not send alerts, reply to messages, or change jobs. A successful query returning zero rows is different from a failed query.

The examples target IBM i 7.5 with suitable Db2 group PTFs. If a service or column is unavailable, capture the exact error and check compatibility. Do not treat the failure as an empty result.

## 1. Jobs in MSGW

Each row is a current MSGW job. No rows means none were reported at that moment. This detects job status; retrieving the specific inquiry text is a separate enhancement.

```sql
-- Read-only: current MSGW jobs.
SELECT JOB_NAME, SUBSYSTEM, JOB_STATUS, FUNCTION
FROM TABLE(QSYS2.ACTIVE_JOB_INFO()) AS J
WHERE JOB_STATUS = 'MSGW'
ORDER BY SUBSYSTEM, JOB_NAME;
```

[Download SQL]({{ '/examples/sql/01-msgw.sql' | relative_url }})

## 2. Required jobs missing

Replace the example job/user/subsystem identities before using the results. Each returned row is a missing required job. Operating windows, minimum instance counts, and maintenance exceptions belong in the adapted monitor. Absence does not prove an abnormal end.

```sql
-- Replace these example identities before interpreting the results.
WITH REQUIRED_JOBS
     (EXPECTED_JOB, EXPECTED_USER, EXPECTED_SUBSYSTEM) AS
(
    VALUES ('MYJOB1', 'MYUSER', 'MYSBS'),
           ('MYJOB2', 'MYUSER', 'MYSBS')
),
ACTIVE_JOBS AS
(
    SELECT JOB_NAME_SHORT, JOB_USER, SUBSYSTEM
    FROM TABLE(QSYS2.ACTIVE_JOB_INFO()) AS J
)
SELECT R.EXPECTED_JOB, R.EXPECTED_USER, R.EXPECTED_SUBSYSTEM,
       'REQUIRED JOB IS NOT ACTIVE' AS ALERT
FROM REQUIRED_JOBS AS R
WHERE NOT EXISTS
(
    SELECT 1 FROM ACTIVE_JOBS AS A
    WHERE A.JOB_NAME_SHORT = R.EXPECTED_JOB
      AND A.JOB_USER = R.EXPECTED_USER
      AND A.SUBSYSTEM = R.EXPECTED_SUBSYSTEM
);
```

[Download SQL]({{ '/examples/sql/02-missing-jobs.sql' | relative_url }})

## 3. Low storage

These 80% and 90% thresholds are examples. This reports ASP capacity, not every possible system limit. Unknown or unavailable capacities are excluded by this teaching query; track them explicitly in a production implementation. Free-space thresholds and growth rates can be useful additions.

```sql
-- Example thresholds, not universal recommendations.
-- NULL/unknown capacities are excluded; production must track unknown too.
WITH STORAGE AS
(
    SELECT ASP_NUMBER,
           TOTAL_CAPACITY AS CAPACITY_MB,
           TOTAL_CAPACITY_AVAILABLE AS FREE_MB,
           DECIMAL(100.0 * (TOTAL_CAPACITY - TOTAL_CAPACITY_AVAILABLE)
                   / NULLIF(TOTAL_CAPACITY, 0), 7, 2) AS PERCENT_USED
    FROM QSYS2.ASP_INFO
    WHERE TOTAL_CAPACITY > 0
      AND TOTAL_CAPACITY_AVAILABLE >= 0
)
SELECT ASP_NUMBER, CAPACITY_MB, FREE_MB, PERCENT_USED,
       CASE WHEN PERCENT_USED >= 90 THEN 'CRITICAL'
            ELSE 'WARNING' END AS ALERT_LEVEL
FROM STORAGE
WHERE PERCENT_USED >= 80
ORDER BY PERCENT_USED DESC;
```

[Download SQL]({{ '/examples/sql/03-storage.sql' | relative_url }})

## 4. Reported disk problems

This checks configured disk units visible through IBM i, not fans, power supplies, all serviceable events, or underlying SAN hardware. A rebuild is a condition to review rather than proof of a new failure. NULL or unknown status is not evidence of good health. Some columns require newer Db2 PTFs.

```sql
-- Reported disk conditions only, not comprehensive hardware monitoring.
SELECT ASP_NUMBER, UNIT_NUMBER, RESOURCE_NAME,
       HARDWARE_STATUS, PROTECTION_STATUS
FROM QSYS2.SYSDISKSTAT
WHERE UNIT_NUMBER > 0
  AND
  (
      HARDWARE_STATUS IN
      ('DEGRADED', 'FAILED', 'HARDWARE FAILURE', 'NOT READY',
       'POWER LOSS', 'UNPROTECTED', 'READ WRITE PROTECTED',
       'WRITE PROTECTED', 'PARITY REBUILD')
      OR
      PROTECTION_STATUS IN
      ('DEGRADED', 'FAILED', 'HARDWARE FAILURE', 'NOT READY',
       'POWER LOSS', 'UNPROTECTED', 'READ WRITE PROTECTED',
       'WRITE PROTECTED', 'PARITY REBUILD', 'SUSPEND', 'RESUME PENDING')
  )
ORDER BY ASP_NUMBER, UNIT_NUMBER;
```

[Download SQL]({{ '/examples/sql/04-disk-health.sql' | relative_url }})

## 5. Important system messages

Severity 70 is an initial review filter, not a complete operational policy. Include important message IDs even below the threshold and exclude known routine ones. This deliberately does not include every inquiry message. Change both QSYSOPR literals to QSYSMSG to inspect that queue if it already exists. For production replace the rolling hour with persistent checkpoints, overlap, and deduplication; polling can miss messages removed before a read.

```sql
-- Starting filter: tune message IDs after observing your system.
-- Labels are literals because not all function levels return queue columns.
SELECT MESSAGE_TIMESTAMP,
       'QSYS' AS MESSAGE_QUEUE_LIBRARY,
       'QSYSOPR' AS MESSAGE_QUEUE_NAME,
       HEX(MESSAGE_KEY) AS MESSAGE_KEY_HEX,
       MESSAGE_ID, MESSAGE_TYPE, SEVERITY, FROM_JOB, MESSAGE_TEXT
FROM TABLE
(
    QSYS2.MESSAGE_QUEUE_INFO(
        QUEUE_LIBRARY => 'QSYS',
        QUEUE_NAME => 'QSYSOPR'
    )
) AS M
WHERE MESSAGE_TIMESTAMP >= CURRENT TIMESTAMP - 1 HOUR
  AND SEVERITY >= 70
ORDER BY MESSAGE_TIMESTAMP DESC;
```

[Download SQL]({{ '/examples/sql/05-system-messages.sql' | relative_url }})

## Read severity in context

| Severity | General IBM meaning |
|:--|:--|
| 40 | Procedure/function ended abnormally; may include cancellation. |
| 50 | Job ended abnormally or did not start. |
| 60 | System/device/subsystem status or warning. |
| 70 | Device malfunction or loss of operation. |
| 80 | System alert; also used for immediate messages. |
| 90 | System/subsystem inoperative condition. |
| 99 | Manual action; sometimes routine rather than urgent. |

A higher number alone does not decide who should be paged. Tune severity and message IDs alongside the separate MSGW, missing-job, and storage checks. See [IBM's definitions](https://www.ibm.com/docs/en/i/7.6.0?topic=file-assigning-severity-code).

## Turn rows into events

For state checks, pick a stable incident key: qualified job identity for MSGW, configured expected-job identity for absence, ASP number for storage, and disk resource plus condition for disk status. Keep a separate event ID for each initial/reminder/recovery notification.

For messages, combine the system, queue, timestamp, and message key for duplicate tracking. Queue keys alone should not be treated as globally unique forever. Do not announce recovery simply because a message leaves the query window.

Next: [build the queue handoff]({% link guide/queue.md %}).
