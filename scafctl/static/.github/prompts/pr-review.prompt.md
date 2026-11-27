---
description: "Fetch and triage PR review comments and CI failures for the current branch. Presents findings for approval before handing off to fixes."
agent: "pr-reviewer"
argument-hint: "Optional: PR number or leave blank to use current branch"
---
Triage unresolved PR review comments and CI failures. Use `gh` CLI and the **GitHub GraphQL API (v4)** to fetch review threads -- the REST API does not expose the `isResolved` field.

Follow these phases **in order** -- do not skip ahead:

1. **Fetch**: Fetch all review threads via GraphQL, paginating with `pageInfo { hasNextPage endCursor }` and `after: $cursor` until every page is examined; **skip comments that are already resolved**. Include **outdated but unresolved** threads -- these still need a response and resolution even if the code has moved
2. **Pipeline check**: Run `gh pr checks <PR_NUMBER>` to see CI status. If any checks are failing, run `gh run view <RUN_ID> --log-failed` to get failure logs. Include pipeline failures in the triage summary alongside review comments -- they may overlap with reviewer feedback or reveal additional issues
3. **Coverage check**: Assess patch coverage against the **70% target** (see `codecov.yml`):
   - Resolve the repo slug: `gh repo view --json owner,name --jq '.owner.login + "/" + .name'`
   - Look for a Codecov report on the PR: `gh pr view <PR_NUMBER> --json comments --jq '.comments[] | select(.body | contains("Codecov")) | .body'`
   - If Codecov has not reported yet (common on a fresh repo), fall back to Go-aware local patch coverage across all packages by running `task test:cover` and intersecting `cover/cover.out` with changed executable Go source tokens (`go/parser` + `go/scanner`, excluding comments, blank lines, braces, and `const`/`type` declarations) against the PR merge base (including uncommitted fixes and untracked `.go` files):
     ~~~bash
     if ! task test:cover; then
       echo "PATCH_COVERAGE=unknown (task test:cover failed)"
     else
       MODULE="$(go list -m 2>/dev/null || true)"
       BASE="$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || true)"
       if [ -z "$MODULE" ] || [ -z "$BASE" ] || [ ! -s cover/cover.out ]; then
         echo "PATCH_COVERAGE=unknown (missing module, merge-base, or cover/cover.out)"
       else
         (
           TMP_COV_DIR="$(mktemp -d "${TMPDIR:-/tmp}/patchcov.XXXXXX")" || {
             echo "PATCH_COVERAGE=unknown (mktemp failed)"
             exit 0
           }
           trap 'rm -rf "$TMP_COV_DIR"' EXIT
           cat >"$TMP_COV_DIR/main.go" <<'EOF'
     package main

     import (
     	"bufio"
     	"bytes"
     	"fmt"
     	"go/ast"
     	"go/parser"
     	"go/scanner"
     	"go/token"
     	"os"
     	"regexp"
     	"sort"
     	"strconv"
     	"strings"
     )

     type blockKey struct {
     	file                    string
     	sLine, sCol, eLine, eCol int
     }

     type posSpan struct{ start, end token.Pos }

     func hasExecutableFuncs(path string) (bool, error) {
     	src, err := os.ReadFile(path)
     	if err != nil {
     		return false, err
     	}
     	fset := token.NewFileSet()
     	af, err := parser.ParseFile(fset, path, src, 0)
     	if err != nil {
     		return false, err
     	}
     	found := false
     	ast.Inspect(af, func(n ast.Node) bool {
     		if found {
     			return false
     		}
     		switch fn := n.(type) {
     		case *ast.FuncDecl:
     			if fn.Body != nil {
     				found = true
     				return false
     			}
     		case *ast.FuncLit:
     			found = true
     			return false
     		}
     		return true
     	})
     	return found, nil
     }

     func main() {
     	mod := strings.TrimSuffix(os.Args[1], "/") + "/"
     	inputPath := os.Args[2]
     	coverPath := os.Args[3]
     	inf, err := os.Open(inputPath)
     	if err != nil {
     		os.Exit(1)
     	}
     	defer inf.Close()
     	compiled := map[string]bool{}
     	files := map[string]bool{}
     	changed := map[string]map[int]bool{}
     	hunkRe := regexp.MustCompile("^@@ -[0-9]+(?:,[0-9]+)? \\+([0-9]+)(?:,([0-9]+))? @@")
     	var curFile string
     	in := bufio.NewScanner(inf)
     	in.Buffer(make([]byte, 0, 64*1024), 10*1024*1024)
     	for in.Scan() {
     		line := in.Text()
     		if strings.HasPrefix(line, "COMPILED\t") {
     			compiled[strings.TrimPrefix(line[len("COMPILED\t"):], mod)] = true
     			continue
     		}
     		if strings.HasPrefix(line, "+++ b/") {
     			curFile = line[6:]
     			continue
     		}
     		if strings.HasPrefix(line, "+++ ") {
     			curFile = ""
     			continue
     		}
     		if curFile != "" {
     			if m := hunkRe.FindStringSubmatch(line); m != nil {
     				start, _ := strconv.Atoi(m[1])
     				cnt := 1
     				if m[2] != "" {
     					cnt, _ = strconv.Atoi(m[2])
     				}
     				if cnt > 0 {
     					files[curFile] = true
     					if changed[curFile] == nil {
     						changed[curFile] = map[int]bool{}
     					}
     					for l := start; l < start+cnt; l++ {
     						changed[curFile][l] = true
     					}
     				}
     			}
     		}
     	}
     	if err := in.Err(); err != nil {
     		os.Exit(1)
     	}
     	cf, err := os.Open(coverPath)
     	if err != nil {
     		os.Exit(1)
     	}
     	defer cf.Close()
     	seenInCover := map[string]bool{}
     	blocks := map[blockKey]int{}
     	cs := bufio.NewScanner(cf)
     	cs.Buffer(make([]byte, 0, 64*1024), 10*1024*1024)
     	first := true
     	for cs.Scan() {
     		if first {
     			first = false
     			continue
     		}
     		fields := strings.Fields(cs.Text())
     		if len(fields) != 3 {
     			continue
     		}
     		colon := strings.LastIndexByte(fields[0], ':')
     		if colon < 0 {
     			continue
     		}
     		f := strings.TrimPrefix(fields[0][:colon], mod)
     		if !files[f] {
     			continue
     		}
     		seenInCover[f] = true
     		stmts, err1 := strconv.Atoi(fields[1])
     		cnt, err2 := strconv.Atoi(fields[2])
     		if err1 != nil || err2 != nil || stmts <= 0 {
     			continue
     		}
     		rng := strings.Split(fields[0][colon+1:], ",")
     		if len(rng) != 2 {
     			continue
     		}
     		sp := strings.Split(rng[0], ".")
     		ep := strings.Split(rng[1], ".")
     		if len(sp) != 2 || len(ep) != 2 {
     			continue
     		}
     		sl, _ := strconv.Atoi(sp[0])
     		sc, _ := strconv.Atoi(sp[1])
     		el, _ := strconv.Atoi(ep[0])
     		ec, _ := strconv.Atoi(ep[1])
     		blocks[blockKey{f, sl, sc, el, ec}] += cnt
     	}
     	if err := cs.Err(); err != nil {
     		os.Exit(1)
     	}
     	for f := range files {
     		if !seenInCover[f] {
     			if !compiled[f] {
     				fmt.Println("PATCH_COVERAGE=unknown (changed Go file missing from cover/cover.out)")
     				return
     			}
     			hasFn, err := hasExecutableFuncs(f)
     			if err != nil {
     				os.Exit(1)
     			}
     			if hasFn {
     				fmt.Println("PATCH_COVERAGE=unknown (changed Go file with functions missing from cover/cover.out)")
     				return
     			}
     		}
     	}
     	byFile := map[string][]struct {
     		k   blockKey
     		cnt int
     	}{}
     	for k, cnt := range blocks {
     		byFile[k.file] = append(byFile[k.file], struct {
     			k   blockKey
     			cnt int
     		}{k, cnt})
     	}
     	type row struct {
     		file string
     		miss int
     		pct  float64
     	}
     	var rows []row
     	totalExec, totalCov := 0, 0
     	for f, fblocks := range byFile {
     		src, err := os.ReadFile(f)
     		if err != nil {
     			os.Exit(1)
     		}
     		fset := token.NewFileSet()
     		af, err := parser.ParseFile(fset, f, src, 0)
     		if err != nil {
     			os.Exit(1)
     		}
     		var skip []posSpan
     		ast.Inspect(af, func(n ast.Node) bool {
     			if gd, ok := n.(*ast.GenDecl); ok && (gd.Tok == token.CONST || gd.Tok == token.TYPE) {
     				skip = append(skip, posSpan{gd.Pos(), gd.End()})
     				return false
     			}
     			return true
     		})
     		tf := fset.File(af.Pos())
     		var sc scanner.Scanner
     		sc.Init(tf, src, nil, 0)
     		hit := map[int]bool{}
     		miss := map[int]bool{}
     		execLines := map[int]bool{}
     		for {
     			pos, tok, _ := sc.Scan()
     			if tok == token.EOF {
     				break
     			}
     			if tok == token.SEMICOLON || tok == token.LBRACE || tok == token.RBRACE {
     				continue
     			}
     			skipped := false
     			for _, sp := range skip {
     				if pos >= sp.start && pos < sp.end {
     					skipped = true
     					break
     				}
     			}
     			if skipped {
     				continue
     			}
     			p := tf.PositionFor(pos, false)
     			endLine := p.Line
     			if tok == token.STRING {
     				startOff := tf.Offset(pos)
     				if startOff < len(src) && src[startOff] == 96 {
     					if relEnd := bytes.IndexByte(src[startOff+1:], 96); relEnd >= 0 {
     						endLine = tf.PositionFor(tf.Pos(startOff+1+relEnd), false).Line
     					}
     				}
     			}
     			hasChangedLine := false
     			for l := p.Line; l <= endLine; l++ {
     				if changed[f][l] {
     					hasChangedLine = true
     					break
     				}
     			}
     			if !hasChangedLine {
     				continue
     			}
     			for _, b := range fblocks {
     				inStart := p.Line > b.k.sLine || (p.Line == b.k.sLine && p.Column >= b.k.sCol)
     				inEnd := p.Line < b.k.eLine || (p.Line == b.k.eLine && p.Column <= b.k.eCol)
     				if inStart && inEnd {
     					for l := p.Line; l <= endLine; l++ {
     						if changed[f][l] {
     							execLines[l] = true
     							if b.cnt > 0 {
     								hit[l] = true
     							} else {
     								miss[l] = true
     							}
     						}
     					}
     				}
     			}
     		}
     		fExec, fCov, fMiss := 0, 0, 0
     		for l := range execLines {
     			fExec++
     			totalExec++
     			if hit[l] && !miss[l] {
     				fCov++
     				totalCov++
     			} else {
     				fMiss++
     			}
     		}
     		if fMiss > 0 {
     			rows = append(rows, row{f, fMiss, float64(fCov) * 100.0 / float64(fExec)})
     		}
     	}
     	if totalExec == 0 {
     		fmt.Println("PATCH_COVERAGE=N/A (0 changed executable lines)")
     		return
     	}
     	sort.Slice(rows, func(i, j int) bool {
     		if rows[i].miss != rows[j].miss {
     			return rows[i].miss > rows[j].miss
     		}
     		return rows[i].file < rows[j].file
     	})
     	for _, r := range rows {
     		fmt.Printf("%s\t%d\t%.1f%%\n", r.file, r.miss, r.pct)
     	}
     	fmt.Printf("PATCH_COVERAGE=%.1f%% (%d/%d executable lines)\n", float64(totalCov)*100.0/float64(totalExec), totalCov, totalExec)
     }
     EOF
           if ! go list -f '{{$d := .ImportPath}}{{range .GoFiles}}COMPILED	{{$d}}/{{.}}{{"\n"}}{{end}}{{range .CgoFiles}}COMPILED	{{$d}}/{{.}}{{"\n"}}{{end}}' ./... >"$TMP_COV_DIR/input.txt" 2>/dev/null \
             || ! git -c core.quotepath=false diff --no-ext-diff --src-prefix=a/ --dst-prefix=b/ -U0 "$BASE" -- '*.go' ':!*_test.go' >>"$TMP_COV_DIR/input.txt"; then
             echo "PATCH_COVERAGE=unknown (git diff or go list failed)"
           else
             while IFS= read -r f; do
               [ -n "$f" ] || continue
               lines="$(awk 'END { print NR }' "$f")"
               [ "$lines" -gt 0 ] && printf '+++ b/%s\n@@ -0,0 +1,%s @@\n' "$f" "$lines" >>"$TMP_COV_DIR/input.txt"
             done <<EOF_UNTRACKED
     $(git -c core.quotepath=false ls-files --others --exclude-standard -- '*.go' ':!*_test.go')
     EOF_UNTRACKED
             if ! GO111MODULE=off go run "$TMP_COV_DIR/main.go" "$MODULE" "$TMP_COV_DIR/input.txt" cover/cover.out; then
               echo "PATCH_COVERAGE=unknown (coverage parser failed)"
             fi
           fi
         )
       fi
     fi
     ~~~
   - If patch coverage cannot be calculated (`PATCH_COVERAGE=unknown`), report coverage as **unknown** -- do **not** treat `unknown` as meeting the 70% target
   - Present a **sorted table** of files with missed lines > 0: file path, missed lines, patch %
   - Flag any files with **0% patch coverage** -- these are the highest priority
   - Note the overall **patch coverage %** (or `N/A` when there are 0 changed executable Go lines, or `unknown`) and whether it meets the **70% target**; if below, list the files where adding tests has the most impact (most missed lines)
4. **Early exit**: If there are **zero unresolved threads**, **all checks are passing**, and patch coverage is **known** (`>= 70%`, or `N/A` with 0 changed executable Go lines -- never `unknown`), report that and stop
5. **Triage**: For each unresolved comment, pipeline failure, and coverage gap, assess whether it's a legit problem with the code. Present the triage summary with recommendations and **stop here** -- wait for the user's approval before applying any fixes

Include thread IDs in the triage output so fixes can be linked to resolved threads afterward.
