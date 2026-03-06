# ARCAkit Docs

Documentation site for [ARCAkit](https://arcakit.dev), built with Ruby on Rails. Renders Markdown guides from a GitHub repository with no database required.

## How it works

Guides are Markdown files stored in `app/content/guides/` — either locally or in a GitHub repository. The app fetches and renders them at request time, with caching.

Each guide is a `.md` file with YAML frontmatter:

```markdown
---
title: Getting Started
description: A brief description shown in the index.
section: Introduction
position: 1
---

Your content here.
```

- `section` — groups guides in the index dropdown
- `position` — sort order within the section

## Requirements

- Ruby 4.0.1
- Rails 8.1

## Local development

```bash
bundle install
bin/rails server
```

Add `.md` files to `app/content/guides/` and they'll appear automatically.

## GitHub integration

Set `GITHUB_REPO` to load guides from a GitHub repository instead of local files:

```bash
GITHUB_REPO=arcakit/arcakit-docs bin/rails server
```

The app reads from `app/content/guides/` in that repo. For private repos, also set `GITHUB_TOKEN`.

Guide content is cached for 5 minutes by default. Override with `GUIDE_CACHE_TTL` (in seconds).

## Deployment

Deployed via [Kamal](https://kamal-deploy.org) to `guides.arcakit.dev`.

```bash
kamal deploy
```
