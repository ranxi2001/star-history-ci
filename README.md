# Star History CI

[简体中文](README.zh-CN.md)

A tiny GitHub Action wrapper for keeping star-history SVGs alive in your README.

It renders the charts in CI, renames the generated SVGs to stable filenames, and publishes them to an `output` branch. Your README can then reference stable `raw.githubusercontent.com` URLs instead of committing generated images back to the default branch.

This project is intentionally small. It is a CI recipe packaged as a reusable action, plus a standalone workflow for users who prefer copy-paste setup.

## How It Works

```text
scheduled or manual workflow
  -> render light/dark star-history SVGs
  -> rename timestamped files to stable filenames
  -> publish files to the output branch
  -> embed the raw SVG URLs in README
```

## Quick Start

Create `.github/workflows/star-history.yml` in your repository:

```yaml
name: Star History

on:
  schedule:
    - cron: "0 0 * * *"
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: star-history
  cancel-in-progress: false

jobs:
  star-history:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ranxi2001/star-history-ci@v1
        with:
          repos: ${{ github.repository }}
```

Then embed the stable SVGs in your README:

```html
## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-light.svg">
</picture>
```

Replace `<owner>/<repo>` with your repository name, for example `ranxi2001/zero2Agent`.

## Inputs

| Name | Default | Description |
| --- | --- | --- |
| `repos` | `${{ github.repository }}` | Repository list to render, using comma-separated `owner/repo` values. |
| `token` | `${{ github.token }}` | Token used by the renderer to read stargazer data. Use a PAT for private repos or cross-org repos. |
| `github-token` | `${{ github.token }}` | Token used to publish generated SVGs to the output branch. |
| `output-dir` | `star-history` | Temporary directory for rendered SVGs before publishing. |
| `publish-branch` | `output` | Branch that hosts the generated SVG files. |
| `file-prefix` | `star-history` | Stable SVG filename prefix. |
| `type` | `Date` | Chart mode passed to the renderer. Usually `Date` or `Timeline`. |
| `themes` | `light,dark` | Comma-separated themes to render. |
| `width` | `800` | SVG width in pixels. |
| `force-orphan` | `true` | Publish the output branch as an orphan branch. |

## Outputs

| Name | Description |
| --- | --- |
| `light` | Relative path to the stable light SVG. |
| `dark` | Relative path to the stable dark SVG. |
| `light_url` | Raw GitHub URL for the stable light SVG. |
| `dark_url` | Raw GitHub URL for the stable dark SVG. |
| `files` | Newline-separated list of stable SVG paths. |

## Standalone Workflow

If you do not want to depend on this wrapper action, copy [examples/standalone-workflow.yml](examples/standalone-workflow.yml). It uses the same underlying idea:

1. Render SVGs with `narayann7/star-history-action@v1`.
2. Rename timestamped files to stable filenames.
3. Publish the directory to the `output` branch with `peaceiris/actions-gh-pages@v4`.

## Releasing

After pushing this project to GitHub, create a major version tag so users can reference `@v1`:

```bash
git tag v1
git push origin v1
```

For later compatible updates, move the `v1` tag after creating the release commit:

```bash
git tag -f v1
git push -f origin v1
```

## Permissions

The workflow needs write access to repository contents:

```yaml
permissions:
  contents: write
```

The default `${{ github.token }}` is usually enough for the current repository. For private repositories, organization repositories, or charts generated from another repository, pass a PAT:

```yaml
- uses: ranxi2001/star-history-ci@v1
  with:
    repos: owner/repo
    token: ${{ secrets.STAR_HISTORY_TOKEN }}
```

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-light.svg">
</picture>

## Contributing

Issues and pull requests are welcome. Please keep each PR focused on one change.

## License

MIT
