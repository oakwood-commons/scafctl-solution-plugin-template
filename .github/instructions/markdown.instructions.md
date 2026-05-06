---
description: "Markdown formatting rules: tilde fences for nested backticks, ASCII-only characters, heading hierarchy, link formatting, and more. Use when writing or editing markdown."
applyTo: "**/*.md"
---

# Markdown Authoring Rules

## Code Blocks

When a markdown code block contains backticks (Go raw strings, heredocs, shell, template literals), use tilde fences instead of backtick fences to avoid delimiter collisions.

If tilde fences are not suitable, use 4+ backtick fences as the outer delimiter.

~~~markdown
# Correct: tilde fences for code with backticks
~~~bash
echo "message with `backtick` inside"
~~~

# Incorrect: backtick fences create ambiguity
```bash
echo "message with `backtick` inside"
```
~~~

## Characters

Use only ASCII characters in markdown files:

- Use `--` instead of em dashes
- Use `---` for horizontal rules (on its own line)
- Use straight quotes (`"`, `'`) instead of curly/smart quotes
- Use `...` instead of ellipsis characters
- Use standard hyphens (`-`) instead of en dashes

## Heading Structure

### Hierarchy
- Start with a single H1 (`#`) at the top of the document
- Increase heading levels sequentially: H1 -> H2 -> H3 (no H1 -> H3 jumps)
- Don't use more than 3-4 levels in a document

### Style
- Use ATX-style headings (`# Heading`) -- never underlined (Setext) style
- No trailing punctuation in headings (avoid `# Heading:` or `# Heading?`)
- Capitalize heading titles consistently

## Lists

- Use `-` for unordered lists (not `*` or `+`)
- Use `1.`, `2.`, etc. for ordered lists
- Consistent indentation: 2 spaces per nesting level
- Keep blank lines between top-level list items for readability
- Use continuation indentation for multi-paragraph items:

~~~markdown
- Item one

  Continuation paragraph (indented 2 spaces)

- Item two
~~~

## Links & URLs

- Use markdown link syntax: `[link text](url)` -- not bare URLs
- Link text should be descriptive (avoid "click here", "link", "more")
- For external links that users should see the full URL, use: `<https://example.com>`
- Keep URLs on one line (no line breaks inside link syntax)

~~~markdown
# Good
For details, see the [configuration guide](./docs/config.md).

# Less good
For details, see the [documentation](./docs/config.md).

# Bare URL -- only use when displaying the actual URL is the point
Visit <https://docs.ford.com/gcp> for platform docs.
~~~

## Emphasis

- Use `**bold**` for strong emphasis (not `__bold__`)
- Use `*italic*` for emphasis (not `_italic_`)
- Don't use emphasis for headings -- use proper heading levels instead

## Inline Code vs Code Blocks

- Use backticks (`` ` ``) for inline code snippets: `` `variableName`, `./my-file.ts` ``
- Use code fences (`` ``` `` or `~~~`) for multi-line code blocks
- Always specify the language after the opening fence: `` ```bash ``, `` ```yaml ``, etc.
- For languages that syntax highlighting doesn't matter much, use no language specifier

## Images

- Always include alt text for accessibility: `![alt text](image.png)`
- Alt text should describe the image content, not "image" or "screenshot"
- Use relative paths for images in the repo

## Blockquotes

- Use `>` for blockquotes on every line
- For multi-paragraph blockquotes, use blank lines with `>` continuation:

~~~markdown
> Paragraph one.
>
> Paragraph two.
~~~

## Whitespace

- **No trailing spaces** at end of lines
- Use spaces, not hard tabs (Tab character is discouraged)
- 1-2 blank lines between major sections
- 1 blank line between list items in longer lists
- No multiple consecutive blank lines (max 2)

## Common Mistakes to Avoid

- Multiple H1 headings in one document -- only one top-level heading
- Inconsistent list markers or indentation
- Mixing backtick fences with tilde fences unnecessarily
- "Smart quotes" or curly quotes instead of straight ASCII quotes
- Heading levels that skip (H1 -> H3 instead of H1 -> H2 -> H3)
- Trailing punctuation in headings
- Bare URLs without markdown link syntax or angle brackets
- Non-ASCII dashes, ellipsis, or other special characters
- Hard tabs instead of spaces for indentation

## Examples

### Good Markdown Structure

~~~markdown
# Solution Repository

Introduction paragraph.

## Getting Started

Steps go here.

### Prerequisites

List prerequisites:

- Item 1
- Item 2

### Installation

For details, see the [installation guide](./docs/install.md).

## Configuration

More content.
~~~

### Referencing Code

~~~markdown
Set the `environment` variable to `prod` or `dev`.

For complex examples, use a code block:

```bash
scafctl run solution -r env=prod
```
~~~
