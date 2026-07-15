# Star History CI

[简体中文](README.zh-CN.md)

A self-contained GitHub Action for keeping star-history SVGs alive in your README.

It renders the charts in CI, renames the generated SVGs to stable filenames, and publishes them to an `output` branch. Your README can then reference stable `raw.githubusercontent.com` URLs instead of committing generated images back to the default branch.

The renderer and output-branch publisher run from source in this repository. No
third-party rendering or publishing Action is invoked at runtime.

## How It Works

```text
scheduled or manual workflow
  -> install locked renderer dependencies
  -> render stable light/dark SVGs locally
  -> publish with the repository's local git script
  -> embed the raw SVG URLs in README
```

## Quick Start

Create a repository secret named `STAR_HISTORY_TOKEN` from a PAT owned by an
admin or collaborator of the repository. Prefer a fine-grained PAT limited to
this repository with read-only metadata access; a classic PAT needs the
`public_repo` scope.

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
          token: ${{ secrets.STAR_HISTORY_TOKEN }}
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
| `token` | Required | PAT owned by a repository admin or collaborator and used to read stargazer data. |
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

Since July 2026, GitHub limits the stargazer listing endpoints to repository
admins and collaborators. The automatic `${{ github.token }}` is an app token,
not a user token, and no longer satisfies that identity check. Pass a PAT owned
by an admin or collaborator through a repository secret:

```yaml
- uses: ranxi2001/star-history-ci@v1
  with:
    repos: owner/repo
    token: ${{ secrets.STAR_HISTORY_TOKEN }}
```

The PAT is used only to read stargazer data. Publishing the generated files
continues to use the automatic `${{ github.token }}` through the separate
`github-token` input.

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-light.svg">
</picture>

## Contributing

Issues and pull requests are welcome. Please keep each PR focused on one change.

## License

MIT. The vendored renderer and fonts retain their original notices in
[`renderer/`](renderer/NOTICE.md).
