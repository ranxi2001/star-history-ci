# Star History CI

[English](README.md)

一个自包含的 Star History 自动化方案：GitHub Actions 生成 SVG，把文件名固定成 `star-history-light.svg` / `star-history-dark.svg`，再发布到 `output` 分支。README 只引用稳定的 `raw.githubusercontent.com` URL，不需要反复改主分支。

渲染器和 `output` 分支发布脚本都直接放在当前仓库中，运行时不再调用第三方的渲染或发布 Action。

## 工作方式

```text
定时或手动触发 workflow
  -> 安装锁定版本的渲染依赖
  -> 在本地生成稳定文件名的亮色/暗色 SVG
  -> 用仓库内的 git 脚本发布到 output 分支
  -> README 引用 raw SVG URL
```

## 快速使用

先创建名为 `STAR_HISTORY_TOKEN` 的仓库 Secret。它应保存属于该仓库管理员或
协作者的 PAT。优先使用仅授权当前仓库、只有只读 Metadata 权限的 fine-grained
PAT；classic PAT 需要 `public_repo` scope。

在目标仓库创建 `.github/workflows/star-history.yml`：

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

然后在 README 中引用 `output` 分支的稳定 SVG：

```html
## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-light.svg">
</picture>
```

把 `<owner>/<repo>` 替换成你的仓库名，例如 `ranxi2001/zero2Agent`。

## 输入参数

| Name | Default | Description |
| --- | --- | --- |
| `repos` | `${{ github.repository }}` | 要生成图表的仓库，支持逗号分隔的 `owner/repo` 列表。 |
| `token` | 必填 | 属于仓库管理员或协作者、用于读取 stargazer 数据的 PAT。 |
| `github-token` | `${{ github.token }}` | 推送生成 SVG 到输出分支的 token。 |
| `output-dir` | `star-history` | 发布前存放 SVG 的临时目录。 |
| `publish-branch` | `output` | 承载生成 SVG 的分支。 |
| `file-prefix` | `star-history` | 稳定 SVG 文件名前缀。 |
| `type` | `Date` | 传给渲染器的图表模式，通常是 `Date` 或 `Timeline`。 |
| `themes` | `light,dark` | 要渲染的主题，逗号分隔。 |
| `width` | `800` | SVG 宽度，单位像素。 |
| `force-orphan` | `true` | 是否把输出分支发布为 orphan 分支。 |

## 输出参数

| Name | Description |
| --- | --- |
| `light` | 稳定亮色 SVG 的相对路径。 |
| `dark` | 稳定暗色 SVG 的相对路径。 |
| `light_url` | 稳定亮色 SVG 的 GitHub raw URL。 |
| `dark_url` | 稳定暗色 SVG 的 GitHub raw URL。 |
| `files` | 稳定 SVG 路径列表，以换行分隔。 |

## 发布版本

把这个项目推到 GitHub 后，需要创建一个主版本 tag，这样用户才能用 `@v1` 引用：

```bash
git tag v1
git push origin v1
```

之后如果是兼容更新，可以在 release commit 后移动 `v1` tag：

```bash
git tag -f v1
git push -f origin v1
```

## 权限说明

workflow 需要写入仓库内容的权限：

```yaml
permissions:
  contents: write
```

从 2026 年 7 月起，GitHub 把 stargazer 列表接口限制为仅仓库管理员和协作者可读。
自动注入的 `${{ github.token }}` 是 App token，不是用户 token，已无法满足这个身份
检查。请通过仓库 Secret 传入属于管理员或协作者的 PAT：

```yaml
- uses: ranxi2001/star-history-ci@v1
  with:
    repos: owner/repo
    token: ${{ secrets.STAR_HISTORY_TOKEN }}
```

PAT 只用于读取 stargazer 数据。发布生成文件仍通过单独的 `github-token` 参数使用
自动注入的 `${{ github.token }}`。

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/ranxi2001/star-history-ci/output/star-history-light.svg">
</picture>

## Contributing

欢迎 PR 和 Issue。内容补充、错误修正、新模块建议均可。

提 Issue 前请先检查是否已有相关讨论。PR 建议一个 PR 只做一件事。

## License

MIT。复刻的渲染器和字体许可证保留在 [`renderer/`](renderer/NOTICE.md) 中。
