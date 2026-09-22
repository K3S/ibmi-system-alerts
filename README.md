# IBM i System Alerts via Webhooks

An open-source guide and starter template for IBM i 7.5: understand the five
checks, put full JSON alerts on a data queue, and tailor a polling monitor and
webhook sender with your IBM i knowledge and an AI coding assistant.

**Status: reference design, not a finished monitoring product.** The repository
includes five SQL checks, a small SQLRPGLE queue producer, architecture and
failure-handling templates, configuration worksheet, AI prompt, and acceptance
scenarios. No production monitor or webhook sender is bundled. RPG source has
not been compiled in the authoring environment.

## Read the guide

Start at [index.md](index.md). The site uses GitHub Pages, Jekyll, and Just the
Docs, following [K3S/rpg-tutorial](https://github.com/K3S/rpg-tutorial).

## Contents

- `guide/`: design, setup, five checks, data queue, tailoring, operations.
- `examples/sql/`: ACS detection queries and non-destructive queue inspection.
- `examples/rpg/ALRTDEMO.sqlrpgle`: single synthetic-event producer.
- `examples/*.json`: event and configuration examples.
- `examples/*.pseudocode.txt`: monitor/sender behavior templates.
- `.github/workflows/`: documentation validation and GitHub Pages build/deploy.

## Local documentation build

Use a current Ruby with Bundler (CI uses Ruby 3.3):

```sh
bundle install
bundle exec jekyll serve
```

For a repository Pages URL set `url` and `baseurl` in `_config.yml`. Deployment
instructions are in `guide/reference.md`. The Pages workflow runs only for a
push to `main` or explicit manual dispatch; enable Pages via Actions first.

## Validation

```sh
python3 tools/validate.py
```

This checks local documentation links, JSON examples, source line lengths, and
that displayed detection SQL matches downloadable SQL. It does not compile RPG
or execute Db2 for i queries. Use the guide's acceptance scenarios on your IBM i.

## License

MIT. See [LICENSE](LICENSE). Contributions should state what was tested and on
which IBM i release/PTF level.
