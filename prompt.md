# Agent Prompt: Add Star History CI

Use this document to let a coding agent add Star History CI to an existing
GitHub repository and verify the result end to end.

## Before Running the Prompt

Create a personal access token owned by a GitHub user who is an admin or
collaborator of the target repository:

- [Fine-grained token](https://github.com/settings/personal-access-tokens/new):
  select the target repository and keep `Metadata: Read-only` enabled.
- [Classic token](https://github.com/settings/tokens/new): for public
  repositories, enable only `public_repo`.

Add the token as a **repository Actions secret** named
`STAR_HISTORY_TOKEN` in the repository that will run the workflow:

```text
https://github.com/<owner>/<repo>/settings/secrets/actions/new
```

Do not paste the token into an agent prompt, workflow file, repository
variable, commit, issue, or chat message. The prompts below tell the agent to
check only whether the secret name exists; secret values cannot and should not
be read back.

## 中文 Prompt

把下面整段复制给已打开目标仓库的编码 Agent：

````text
请在当前 GitHub 仓库中完整接入 Star History CI，并完成实际运行验证。

目标：
- 每天和手动触发时生成当前仓库的 Star History。
- 使用 ranxi2001/star-history-ci@v2 自行渲染并发布到 output 分支。
- README 使用稳定的亮色/暗色 SVG 地址。

执行要求：
1. 先检查 git 状态、默认分支、origin 的 owner/repo、现有 workflows、README 和远端 output 分支的用途。保留用户已有修改，不改动无关 workflow；现有 Pages workflow 也不要删除或重写。如果 output 分支包含非 Star History 的人工维护内容，或分支规则禁止强制更新，不要覆盖它；改用专用发布分支，并让 workflow 的 publish-branch 和 README URL 保持一致。
2. 检查目标仓库是否存在名为 STAR_HISTORY_TOKEN 的 Repository Actions secret，只检查名称，不读取、打印或索要 Secret 值。如果当前身份无权列出 Secret 名称，请让我确认，不要推断它不存在。如果没有得到“Secret 已配置”的明确确认，只完成本地修改和验证，不要 push 或触发 workflow。如果确认不存在，告诉我在下面地址创建：
   https://github.com/<owner>/<repo>/settings/secrets/actions/new
   不要建议把 token 发到聊天中。这个 Prompt 预期使用 Repository secret；如果实际使用 Environment secret，必须先确认 environment 名称并在 job 中显式声明。
3. 创建或更新 .github/workflows/star-history.yml。若已有旧的 Star History workflow、第三方渲染 Action、重命名步骤或单独的 output 发布 Action，替换它们，不要再创建一份重复的定时任务。下面的 cron 使用 UTC，每天 00:00 UTC 运行。工作流使用以下内容：

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

4. 在主要 README 的合适位置添加或更新下面的区块。把 <owner>/<repo> 替换成从 origin 确认的真实仓库名。如果 README 已引用相同的 output 分支稳定文件名，不要重复添加。

```markdown
## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-light.svg">
</picture>
```

5. 验证 YAML，运行 git diff --check，检查完整 diff，并运行仓库已有且与改动相关的检查。不要把 token 写入日志或任何文件。
6. 若 Secret 已确认且当前凭据允许，先记录发布分支当前 commit，提交并推送到默认分支，然后手动触发 Star History workflow。记录本次 run ID/URL，等待它结束，并确认 conclusion 是 success、head SHA 是刚推送的 commit。不能只确认 workflow 已创建，也不能复用旧 run 的结果。
7. 成功后确认发布分支 commit 已改变，且发布 commit 对应本次 source commit。验证 star-history-light.svg 和 star-history-dark.svg 在该 commit 中都非空且包含 <svg。公开仓库还要确认两个稳定 raw URL 返回 HTTP 200、SVG Content-Type 和实际 SVG 正文；私有仓库使用不会泄露 token 的认证请求验证，不要声称图片可被公众访问。若失败，读取失败步骤日志，仅修复本次任务范围内的仓库文件。常见问题包括 Secret 建错仓库/建成未绑定的 Environment secret、PAT 用户不是仓库管理员或协作者、output 分支受保护，以及仓库或组织禁止 GITHUB_TOKEN 写入 contents。
8. 不得自行创建、读取或修改 Secret，也不得修改仓库/组织设置、Actions 权限、Environment、ruleset 或分支保护；这些操作必须单独获得用户明确授权。若失败需要这类修改，报告准确阻塞原因和用户应检查的位置。
9. 最后报告改动文件、source commit SHA、Actions run URL、发布分支 commit 和两个图片 URL。若因权限无法推送或触发，明确说明已完成到哪一步和准确的阻塞原因，不要声称已经成功。
````

## English Prompt

Paste the entire block below into a coding agent opened in the target
repository:

````text
Add Star History CI to the current GitHub repository and verify it with a real workflow run.

Goals:
- Generate this repository's Star History on a daily schedule and on demand.
- Use ranxi2001/star-history-ci@v2 to render and publish the files to the output branch.
- Embed stable light and dark SVG URLs in the README.

Requirements:
1. Inspect the git status, default branch, owner/repo from origin, existing workflows, README, and the purpose of any remote output branch first. Preserve existing user changes and leave unrelated workflows untouched. Do not remove or rewrite an existing Pages workflow. If the output branch contains user-maintained content unrelated to Star History, or branch rules prohibit force updates, do not overwrite it. Use a dedicated publishing branch and keep the workflow's publish-branch input and README URLs consistent.
2. Check whether the target repository has a Repository Actions secret named STAR_HISTORY_TOKEN. Check only the name; never read, print, or ask me to paste the secret value. If the current identity cannot list secret names, ask me to confirm instead of assuming the secret is missing. Without explicit confirmation that the secret is configured, make and validate only local changes; do not push or dispatch the workflow. If the secret is confirmed missing, direct me to:
   https://github.com/<owner>/<repo>/settings/secrets/actions/new
   Do not suggest sending a token through chat. This prompt expects a repository secret. If an Environment secret is being used instead, first confirm the environment name and explicitly bind that environment to the job.
3. Create or update .github/workflows/star-history.yml. If a legacy Star History workflow, third-party renderer, filename-renaming step, or separate output-branch publishing Action already exists, replace it instead of creating a duplicate scheduled workflow. The cron below uses UTC and runs daily at 00:00 UTC. Use this workflow:

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

4. Add or update the following section in the primary README at a sensible location. Replace <owner>/<repo> with the repository name confirmed from origin. Do not add a duplicate if the README already references the same stable files on the output branch.

```markdown
## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-dark.svg">
  <img alt="Star History" src="https://raw.githubusercontent.com/<owner>/<repo>/output/star-history-light.svg">
</picture>
```

5. Validate the YAML, run git diff --check, inspect the complete diff, and run existing checks relevant to the change. Never write the token to logs or files.
6. If the secret is confirmed and the current credentials allow it, record the current publishing-branch commit, commit and push to the default branch, and manually dispatch the Star History workflow. Capture this run's ID/URL, wait for it to finish, and confirm that its conclusion is success and its head SHA is the commit just pushed. Do not stop after confirming that the workflow exists, and do not reuse an older run as evidence.
7. After a successful run, verify that the publishing-branch commit changed and that the deployment commit corresponds to this source commit. Confirm that star-history-light.svg and star-history-dark.svg are non-empty at that commit and contain <svg. For a public repository, also require both stable raw URLs to return HTTP 200, an SVG Content-Type, and actual SVG bodies. For a private repository, use an authenticated request that does not expose the token and do not claim the images are publicly accessible. If the run fails, inspect the failed step and fix only repository files within this task's scope. Common causes include creating the secret in the wrong repository or as an unbound Environment secret, using a PAT whose owner is not an admin or collaborator, protecting the output branch, and repository or organization policy preventing GITHUB_TOKEN from writing contents.
8. Do not create, read, or modify secrets. Do not change repository or organization settings, Actions permissions, environments, rulesets, or branch protection without separate explicit user authorization. If the failure requires one of those changes, report the exact blocker and where the user should inspect it.
9. Report the changed files, source commit SHA, Actions run URL, publishing-branch commit, and both image URLs. If authentication prevents a push or workflow dispatch, state exactly what was completed and what is blocked; do not claim success.
````
