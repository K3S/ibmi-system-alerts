---
title: Home
layout: default
nav_order: 1
permalink: /
---

# IBM i System Alerts via Webhooks

**Understand the design. Try the checks. Build the version your system needs.**

An open-source guide and starter template for IBM i 7.5. Learn how a polling job can detect problems, write alerts to a data queue, and let a separate sender deliver them to Slack or another webhook destination.

[See how it works]({% link guide/design.md %}){: .btn .btn-primary .mr-2 }
[Try the five checks]({% link guide/checks.md %}){: .btn }

## What you can build

| Watch for | Example alert |
|:--|:--|
| Jobs in MSGW | A batch job is waiting for a reply. |
| Missing required jobs | The overnight interface should be running, but is absent. |
| Low storage | An ASP has crossed your warning threshold. |
| Reported disk problems | A disk reports failure or degraded protection. |
| Important system messages | A selected operator message needs attention. |

```text
One polling monitor → Data queue carrying alerts → Sender → Webhook
```

The queue contains the actual alert, not a pointer to a delivery table. A small, optional persistent state store remembers which incidents have already been reported. It does not replace the queue.

## Who this is for

You know your IBM i environment, can run SQL in ACS, and can compile or work with someone who compiles RPGLE. You want a design you can understand and maintain. A capable AI coding assistant can help adapt the examples, but your environment and operating rules drive the implementation.

## Start here

1. **[Understand the design]({% link guide/design.md %}).** Follow one incident from detection through delivery and recovery.
2. **[Prepare your environment]({% link guide/setup.md %}).** Confirm the services, permissions, tools, and scope.
3. **[Try the five checks]({% link guide/checks.md %}).** Run the read-only SQL and inspect your own results.
4. **[Build the queue handoff]({% link guide/queue.md %}).** Compile a small producer and inspect its test alert.
5. **[Choose your checks and delivery]({% link guide/customize.md %}).** Add checks, choose another destination, and adjust schedules, thresholds, and severity.
6. **[Build it with AI]({% link guide/tailor.md %}).** Fill in your decisions and give your AI assistant a specific implementation brief.
7. **[Test and operate it]({% link guide/operations.md %}).** Exercise retries, restarts, recovery, and the monitoring heartbeat.

## What this starter includes

- Five SQL detection examples and a data-queue exercise.
- A small SQLRPGLE producer, with compile instructions.
- Monitor and sender flow templates, an event format, and a configuration worksheet.
- A reusable AI implementation prompt and an acceptance checklist.
- Focused customization prompts for new checks, email or other destinations, routing, schedules, and severity rules.

**This is a reference design, not a finished monitoring product.** The five detection queries were reported to work on the originating user's system after the message-query correction. The downloadable RPG exercise and a complete adapted monitor still need compilation and testing on your own IBM i. There is no bundled production monitor or production webhook sender.

## Keep the scope honest

A running job can still be stuck. Disk status does not cover every hardware failure. An IBM i cannot report its own total outage through a job running on that same system. Keep application monitoring, hardware call home, and an external availability check where they already serve you well.

## Open source

The source and documentation use the MIT License. The site follows the approachable, step-by-step structure of the [K3S RPG Tutorial](https://github.com/K3S/rpg-tutorial), using the same Just the Docs theme. See [references and contributing]({% link guide/reference.md %}) to improve or publish your own version.
