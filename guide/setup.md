---
title: 2. Before you build
layout: default
nav_order: 3
---

# Prepare your IBM i environment

The target is **IBM i 7.5**. Service availability also depends on installed Db2 group PTFs, authorities, and the columns used. Test the five queries first; a release number alone is not a compatibility test.

## Bring these tools

- ACS Run SQL Scripts for exploring the checks.
- An IBM i development environment with the ILE RPG compiler and SQL precompiler for the SQLRPGLE exercise.
- A way to upload UTF-8 stream files to the IFS, such as your existing Code for IBM i workflow.
- A dedicated test library and queue, plus permission to create and use them.
- For actual delivery: a webhook endpoint, outbound HTTPS, and correctly configured certificate trust.

You do not need PHP, Node.js, or Python on IBM i for this design. The sender could use another language if your team already operates it, but the examples use native SQL services and SQLRPGLE.

## Confirm the SQL services

Run the [five detection examples]({% link guide/checks.md %}) individually before combining them. An SQL0204 object-not-found error and an SQL0206 column-not-found error require investigation, not suppression. Record the IBM i version, Db2 group PTF level, query, and exact error for your implementer.

The sender design uses `QSYS2.HTTP_POST_VERBOSE`. The queue exercise uses `QSYS2.SEND_DATA_QUEUE_UTF8` and `QSYS2.RECEIVE_DATA_QUEUE`. Confirm those services on the target partition too. The `headers` HTTP option requires IBM i 7.5 Db2 group SF99950 level 3 or later; do not assume an unpatched base installation has every option used here.

## Decide what is in scope

Write down the required jobs, their starting users and subsystems, and when they should exist. Start with jobs you can identify reliably. Do not use only a job name if the same name is used by several unrelated users.

List the message queues you already monitor. `QSYSOPR` is the initial example. If `QSYS/QSYSMSG` exists, evaluate it too. Creating QSYSMSG changes routing for certain messages, so creating it is an operational decision, not a prerequisite for this starter.

Hardware status here covers reported disk conditions visible to IBM i. Retain HMC/IBM call home and storage-platform monitoring for broader hardware coverage. Keep application monitoring separate when it already checks business outcomes.

## Start without a live webhook

The first exercise sends a synthetic event to a test queue and reads it without removing it. It does not contact Slack. After that works, test the destination adapter separately with a harmless message in a test destination. Never put a real webhook URL in a public repository or in an AI prompt; provide a configuration placeholder.

Runtime profiles should receive the permissions their selected checks and queue operations need. Avoid distributing an example that requires unrestricted authority merely for convenience. Use the IBM documentation linked in [references]({% link guide/reference.md %}) when assigning access.

Next: [try the five checks]({% link guide/checks.md %}).
