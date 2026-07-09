# Star History CI

[English](README.md)

一个很小的 Star History 自动化方案：GitHub Actions 生成 SVG，把文件名固定成 `star-history-light.svg` / `star-history-dark.svg`，再发布到 `output` 分支。README 只引用稳定的 `raw.githubusercontent.com` URL，不需要反复改主分支。

这个项目刻意保持简单：它把一个优雅的 CI 用法封装成可复用 action，同时保留一份可直接复制的 standalone workflow。

## 工作方式

```text
定时或手动触发 workflow
  -> 生成亮色/暗色 star-history SVG
  -> 把带时间戳的文件改成稳定文件名
  -> 发布到 output 分支
  -> README 引用 raw SVG URL
```

## 快速使用

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
| `token` | `${{ github.token }}` | 读取 stargazer 数据的 token。私有仓库或跨组织仓库可传 PAT。 |
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

## 不使用封装 action

如果你只想复制原始思路，可以直接使用 [examples/standalone-workflow.yml](examples/standalone-workflow.yml)。它等价于：

1. 调用 `narayann7/star-history-action@v1` 生成 SVG。
2. 把带时间戳的文件改名成稳定文件名。
3. 用 `peaceiris/actions-gh-pages@v4` 发布到 `output` 分支。

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

默认的 `${{ github.token }}` 对当前仓库通常够用。生成其他仓库、组织仓库或私有仓库图表时，建议传入 PAT：

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

欢迎 PR 和 Issue。内容补充、错误修正、新模块建议均可。

提 Issue 前请先检查是否已有相关讨论。PR 建议一个 PR 只做一件事。

## License

MIT
