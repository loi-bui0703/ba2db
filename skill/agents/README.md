# Installing this skill into an agent

The skill is Markdown and shell — no runtime, no dependencies, no vendor lock-in.
Any agent that can read a file can run it. What differs between hosts is only
**where the files live** and **how the host is told to load them**.

The easy path is the CLI:

```bash
npx ba2db install              # detects your agent and asks where to put it
npx ba2db install --host claude-code --project --yes   # non-interactive
npx ba2db doctor               # verify the installation is complete
npx ba2db list                 # show everywhere it is installed
```

This page is for doing it by hand, or for a host the CLI does not know yet.

## Supported hosts

| Host | Where the skill goes | How the host is told | Scopes |
|---|---|---|---|
| Claude Code | `~/.claude/skills/ba2db` (global) or `.claude/skills/ba2db` (project) | discovered automatically | global · project |
| Cursor | `.ba2db/` + rule at `.cursor/rules/ba2db.mdc` | rule file points at the skill | global · project |
| Codex / AGENTS.md | `.ba2db/` + a marked block appended to `AGENTS.md` | block points at the skill | project |
| GitHub Copilot | `.ba2db/` + block in `.github/copilot-instructions.md` | `#file:.ba2db/SKILL.md` | project |
| OpenCode | `.ba2db/` + rule at `.opencode/rules/ba2db.md` | rule file points at the skill | project |
| Anything else | anywhere | `npx ba2db prompt` prints a copy-paste prompt | — |

**Rule files always point at the skill; they never copy it.** One source of
truth, so a host cannot drift out of sync with the rest.

## Manual install

Copy the `skill/` directory to where the host looks, keeping its internal
structure intact:

```
SKILL.md            entry point — the agent reads this first
skills/             one directory per stage, 00 through 05
references/         eight reference documents, loaded only when relevant
templates/          the artifacts each stage fills in
scripts/            init-workspace.sh, validate-ddl.sh, check-structure.sh
agents/             this file
```

Then point the host at `SKILL.md`. For a host with no skill mechanism at all,
paste the output of `npx ba2db prompt` into the conversation.

Verify with `bash scripts/check-structure.sh` — it lists any file the skill
expects and cannot find.

## Adding a host

A host is one entry in `src/hosts.mjs`:

```js
{
  id: 'my-agent',
  label: 'My Agent',
  kind: 'copy',                        // 'copy' | 'rule' | 'manual'
  detect: [join(homedir(), '.myagent')],
  target: {
    global:  join(homedir(), '.myagent', 'skills', SKILL_NAME),
    project: join('.myagent', 'skills', SKILL_NAME),
  },
  verify: 'Ask: "design a database from the BA docs in docs/ba/"',
}
```

`kind: 'copy'` for hosts with a real skill directory; `kind: 'rule'` for hosts
that need a pointer file (add the rule body to `src/rules.mjs`); `kind: 'manual'`
for everything else. Nothing else in the CLI changes.

## What the agent does once it loads

It reads `SKILL.md`, runs Stage 0, and **stops at a gate** — it will summarise
what it found and wait for your confirmation before modelling anything. That
pause is the point of the skill, not a limitation: mistakes are cheap to fix at
the intake report and expensive to fix in the DDL.

If it skips a gate, or jumps straight to SQL, the skill is not loaded — check
`npx ba2db doctor`.

## Chạy lượt đọc đối kháng bằng một agent riêng (Stage 5, nhóm 9)

Cùng một agent vừa thiết kế vừa review có **trần năng lực đã biết**: nó bảo vệ
lựa chọn của chính mình. Trong lần thử nghiệm thực tế trên `notificationb2b`,
tự review bỏ sót hai lỗi mà việc đếm bằng máy bắt được — một con số requirement
tự khai sai, và một bảng mã hoá vòng đời hai lần không có ràng buộc nào buộc hai
cách biểu diễn khớp nhau.

Nếu host hỗ trợ subagent, hãy chạy nhóm 9 của `references/review-checklist.md`
bằng một agent riêng, và **giữ context của nó mỏng có chủ ý**:

| Đưa cho nó | Không đưa |
|---|---|
| `04-schema.sql` | `03-logical-schema.md` (chứa lý giải denormalize) |
| `01-data-requirements.md` | `02-conceptual-erd.md` (chứa lý giải quyết định) |
| `04-migration-notes.md §7` (danh sách job) | `05-review-report.md` (kết luận của lượt review trước) |

**Vì sao giữ context mỏng:** phần biện minh là thứ làm người đọc chấp nhận thiết
kế. Bỏ nó đi thì agent chỉ còn schema và yêu cầu, và nó buộc phải tự hỏi *"schema
này cho phép dữ liệu sai nào?"* thay vì *"lý do đã viết có hợp lý không?"*.

Prompt gợi ý:

```
Đây là một schema và bộ yêu cầu dữ liệu. Đừng tóm tắt, đừng đánh giá tổng thể.
Tìm ít nhất 3 cách làm dữ liệu SAI mà schema này vẫn CHẤP NHẬN, và với mỗi cách
viết ra đúng câu INSERT/UPDATE làm được điều đó. Đặc biệt xem:
  * cùng một sự thật được lưu ở hai nơi mà không có gì buộc chúng khớp nhau
  * rule áp dụng đúng câu chữ nhưng cho kết quả vô nghĩa với một nhóm dữ liệu
  * hai tiến trình đồng thời
  * điều gì xảy ra nếu một job định kỳ không chạy
Nếu tìm không ra, nói rõ đã thử những hướng nào.
```

Finding của nó đi thẳng vào `05-review-report.md` như finding bình thường — kể
cả khi nó trái với kết luận của lượt review trước. Đặc biệt là khi nó trái.
