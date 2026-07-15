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

Prefer to let a coding agent handle the repository changes and verification?
Use the ready-to-paste [Agent setup prompt](prompt.md).

### 1. Create a personal access token

Open [New fine-grained personal access token](https://github.com/settings/personal-access-tokens/new)
and configure it as follows:

- `Resource owner`: the account or organization that owns the target repository.
- `Repository access`: `Only select repositories`, then select every repository listed in `repos`.
- `Repository permissions`: `Metadata: Read-only` (normally added automatically); leave other permissions disabled.

The GitHub user creating the token must be an admin or collaborator of every
target repository. As a fallback, a [classic token](https://github.com/settings/tokens/new)
works with only the `public_repo` scope for public repositories.

### 2. Add the token to the target repository

The secret belongs in the repository that **runs this workflow**, not in the
`star-history-ci` repository. Open the target repository, then go to
`Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`.
The direct URL follows this exact pattern:

```text
https://github.com/<owner>/<repo>/settings/secrets/actions/new
```

Set `Name` to `STAR_HISTORY_TOKEN`, paste the new token into `Secret`, and click
`Add secret`. Repository secrets are not shared automatically, so repeat this
step for every project that uses the Action. Do not put the token in workflow
YAML, repository variables, commits, issues, or chat messages.

### 3. Add the workflow

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

      - uses: ranxi2001/star-history-ci@v2
        with:
          repos: ${{ github.repository }}
          token: ${{ secrets.STAR_HISTORY_TOKEN }}
```

### 4. Embed the chart

Embed the stable SVGs in your README:

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

Version 2 requires an admin or collaborator PAT. Create an immutable release tag
and a moving major tag so users can reference `@v2`:

```bash
git tag v2.0.0
git tag v2
git push origin v2.0.0 v2
```

For later compatible updates, move the `v2` tag after creating the release commit:

```bash
git tag -f v2
git push -f origin v2
```

## Permissions

The workflow needs write access to repository contents:

```yaml
permissions:
  contents: write
```

Since July 2026, GitHub limits the stargazer listing endpoints to repository
admins and collaborators. The automatic `${{ github.token }}` is an app token,
not a user token, and no longer satisfies that identity check. Configure
`STAR_HISTORY_TOKEN` in the repository that runs the workflow as described in
[Quick Start](#quick-start), then pass it through the `token` input:

```yaml
- uses: ranxi2001/star-history-ci@v2
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
