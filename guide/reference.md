---
title: References and contributing
layout: default
nav_order: 9
---

# References and contributing

## IBM documentation

- [IBM i Services overview](https://www.ibm.com/docs/ssw_ibm_i_74/rzajq/rzajqservicessys.htm) and [release/PTF catalog](https://www.ibm.com/support/pages/node/1119123): discover additional checks.

- [ACTIVE_JOB_INFO](https://www.ibm.com/docs/en/i/7.5.0?topic=services-active-job-info-table-function): active jobs, identity, and status.
- [ASP_INFO](https://www.ibm.com/docs/en/i/7.5.0?topic=services-asp-info-view): storage capacity and authority requirements.
- [SYSDISKSTAT](https://www.ibm.com/docs/en/i/7.5.0?topic=services-sysdiskstat-view): reported disk and protection status.
- [MESSAGE_QUEUE_INFO](https://www.ibm.com/docs/en/i/7.5.0?topic=services-message-queue-info-table-function): reading a selected message queue.
- [Message severity definitions](https://www.ibm.com/docs/en/i/7.6.0?topic=file-assigning-severity-code): severity is only part of an alert policy.
- [Data queue SQL services](https://www.ibm.com/support/pages/qsys2senddataqueue-qsys2senddataqueuebinary-and-qsys2senddataqueueutf8): send operations and related documentation.
- [CRTDTAQ](https://www.ibm.com/docs/en/i/7.4.0?topic=ssw_ibm_i_74%2Fcl%2Fcrtdtaq.html) and [FORCE behavior](https://www.ibm.com/support/pages/force-parameter-crtdtaq-command).
- [QRCVDTAQ](https://www.ibm.com/docs/en/i/7.4.0?topic=ssw_ibm_i_74%2Fapis%2Fqrcvdtaq.htm): receive and removal semantics.
- [CRTSQLRPGI](https://www.ibm.com/docs/en/i/7.4.0?topic=ssw_ibm_i_74%2Fcl%2Fcrtsqlrpgi.htm): compiling embedded-SQL RPG from stream files.
- [QSYS2 HTTP availability](https://www.ibm.com/support/pages/new-http-functions-based-qsys2) and [HTTP options](https://www.ibm.com/docs/en/i/7.5.0?topic=functions-http-get-http-get-blob).
- [HMC support heartbeat](https://www.ibm.com/support/pages/how-schedule-sending-service-data-hmc-heartbeat-vpd-etc): distinguish support reporting from checking your monitor.
- [Slack incoming webhooks](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks): destination payloads and responses.

## Contribute an adaptation

Share a focused change with its purpose, IBM i release/PTF level, and test results. Remove credentials, production message text, and private job identities from examples. Clearly distinguish proposed source from code compiled and exercised on an IBM i.

Useful contributions include a tested sender, a complete monitor implementing this design, configuration tooling, capability checks, and real failure/recovery tests. Preserve the full-alert data-queue architecture unless a proposed alternative is explicitly labeled and explained.

## Publish your own guide

This repository uses Jekyll with the Just the Docs theme, like the [K3S RPG Tutorial](https://github.com/K3S/rpg-tutorial). The documentation and downloadable examples are in the same repository.

1. Create a repository and upload the project contents.
2. In `_config.yml`, set `url` to your Pages origin and `baseurl` to your repository path, or use an empty baseurl with a custom domain.
3. Set the Pages source to GitHub Actions and enable the included Pages workflow.
4. Once the repository exists, add its URL to the navigation/footer and enable edit links if desired.
5. Verify internal links, downloads, and the mobile layout on the deployed site.

No repository URL, custom domain, analytics identifier, or deployment is assumed by this starter.

## License and credit

MIT licensed. Documentation structure and theme configuration are adapted from the MIT-licensed K3S RPG Tutorial, copyright 2026 King III Solutions, Inc. IBM and Slack documentation inform the technical references. No IBM affiliation or certification is implied.
