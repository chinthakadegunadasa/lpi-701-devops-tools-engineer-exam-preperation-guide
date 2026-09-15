# Chapter 2: 701.2 Source Code & Version Control Systems (Git)
## 1. Objective Architecture & Theoretical Foundations
Source code versioning is the foundational pillar of modern DevOps pipelines. This section covers advanced Git architecture, repository maintenance strategies, branching strategies, and programmatic hook automation required for the LPIC DevOps Tools Engineer (Exam 701) certification.
![Git Workflows](img/lpi-ex701-ch2-git-workflows.png)
```

### Advanced Git Workflows
 * **Trunk-Based Development:** Developers merge small, frequent updates directly into a core single branch (main or trunk). Requires robust automated CI test gates, short-lived feature branches, and feature flags to decouple deployment from release.
 * **GitFlow Strategy:** Uses strict branching conventions: explicit long-lived branches (main, develop) alongside temporary supporting branches (feature/*, release/*, hotfix/*). Best suited for scheduled, versioned software releases.
 * **Rebase vs. Merge:**
   * git merge: Combines divergent histories by creating a 3-way merge commit. Preserves exact historical topology but can clutter commit logs.
   * git rebase: Replaces upstream commits under feature commits, rewriting history to produce a linear timeline. *Rule:* Never rebase public or shared commits.
### Deep Internal Inspection & Recovery
 * **Git Reflog (git reflog):** Tracks every reference update made to local branch heads (commits, checkouts, resets, rebasing). Serves as a recovery engine for lost commits, detached HEAD states, or accidental destructive resets (git reset --hard).
 * **Git Bisect (git bisect):** Uses binary search algorithms across commit histories to locate the exact commit that introduced a regression or bug.
 * **Git Worktree (git worktree):** Enables mounting multiple working trees connected to the same repository database. Allows developers to check out and test multiple branches simultaneously without stashing or switching branches.
### Repository Component Modularization
 * **Git Submodules:** Links external Git repositories inside a parent repository at a specific commit hash pointer stored in .gitmodules. Submodules require explicit git submodule update commands to fetch contents.
 * **Git Subtree:** Merges sub-projects directly into the main repository's tree structure as standard directories. Eliminates external dependency fetching steps for end users at the expense of an enlarged main repository history.
### Hook Automation Lifecycle
 * **Client-Side Hooks:** Executed on local developer machines before actions like commits or pushes occur (e.g., pre-commit, prepare-commit-msg, pre-push). Often bypassed via --no-verify.
 * **Server-Side Hooks:** Executed on central server endpoints (e.g., pre-receive, update, post-receive). Enforce non-bypassable policies such as authorization, branch protection rules, commit formatting, secret detection, and automated trigger payloads.
## 2. Real-World Production Scenario
### System Under Outage
A critical memory leak and credential leak have reached the main branch of an enterprise microservices engine across a history spanning over 500+ commits. Simultaneously, multiple developer teams report severe branch drift and conflicting release topologies during an emergency hotfix deployment.
```
[ Compromised Linear Topology & History Drift ]
... C100 ---> C101 ---> [ Secret Leaked! ] ---> C350 ---> [ Bug Introduced ] ---> C500 (HEAD)
                                                                |
                                                                +---> Hotfix Drift Failure!

                                      |
                                      |  REMEDIATION & RECOVERY PIPELINE
                                      v

[ Cleaned & Rescued Repository State ]
1. Run `git bisect`      ==> Isolate the bug commit automatically.
2. Run `git reflog`      ==> Recover accidentally lost commits.
3. Install Hooks         ==> Block secrets at `pre-receive` / `pre-commit`.
4. Run `git rebase -i`   ==> Purge secret commits & squash history linear trace.

```
### Architectural Objectives
 1. Use git bisect with automated regression scripts to find the breaking commit across 500+ updates.
 2. Recover accidentally dropped production hotfix commits using git reflog.
 3. Scrub sensitive API tokens from historical commits using interactive rebasing (git rebase -i).
 4. Implement client-side and server-side Git hooks to block secrets and prevent syntax errors before code reaches central repositories.
## 3. Hands-On Step-by-Step Implementation Lab
### Lab Environment Setup
Initialize a clean local workspace:
```bash
mkdir -p devops-701-git-lab && cd devops-701-git-lab
git init .
git config user.name "DevOps Engineer"
git config user.email "devops@example.com"

```
### Step 1: Setting Up Pre-Commit & Server-Side Security Hooks
Create a client-side pre-commit hook (.git/hooks/pre-commit) to block hardcoded API keys and syntax errors:
```bash
#!/bin/bash
# Client-side pre-commit hook: Block secrets and syntax errors

# Check for AWS/Generic Secret Key Patterns
if git diff --cached | grep -E -q 'AWS_SECRET_ACCESS_KEY|SECRET_KEY\s*=\s*"[A-Za-z0-9/+=]{10,}"'; then
    echo "ERROR: Hardcoded secret detected in staged files!"
    echo "Commit rejected by pre-commit hook."
    exit 1
fi

# Check Python Syntax Errors
staged_py_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$')
if [ -n "$staged_py_files" ]; then
    for file in $staged_py_files; do
        if [ -f "$file" ]; then
            python3 -m py_compile "$file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "ERROR: Syntax error detected in $file"
                exit 1
            fi
        fi
    done
fi

exit 0

```
Make the hook executable:
```bash
chmod +x .git/hooks/pre-commit

```
### Step 2: Simulating Historic Commits & Isolate Bugs with git bisect
Create a test repository script to generate commit history and simulate a regression bug:
```bash
# Create base script
cat << 'EOF' > app.py
def process_data():
    return "OK"

print(process_data())
EOF
git add app.py
git commit -m "feat: initial working version"

# Generate 20 passing commits
for i in $(seq 1 20); do
    echo "# Comment pass $i" >> app.py
    git commit -am "chore: stability update $i"
done

# Introduce a regression bug at commit #21
cat << 'EOF' > app.py
def process_data():
    # REGRESSION BUG: Memory leak introduced here
    raise RuntimeError("Memory Leak Bug Introduced")

print(process_data())
EOF
git commit -am "feat(core): update data processor logic"

# Generate 10 more commits after the bug
for i in $(seq 22 30); do
    echo "# Post bug update $i" >> app.py
    git commit -am "docs: update documentation $i"
done

```
Automate isolation of the breaking commit using git bisect:
```bash
# Create automated tester script
cat << 'EOF' > test_script.sh
#!/bin/bash
python3 app.py > /dev/null 2>&1
EOF
chmod +x test_script.sh

# Start automated bisecting run
git bisect start
git bisect bad HEAD
git bisect good HEAD~25
git bisect run ./test_script.sh
git bisect reset

```
### Step 3: Recovering Lost Commits using git reflog
Simulate an accidental hard reset that drops commits:
```bash
# Accidentally wipe out recent history
git reset --hard HEAD~5

# Check current state (commits appear lost)
git log --oneline -n 3

# Inspect reference logs to identify lost commit hash
git reflog

```
Locate the target commit hash prior to the reset (e.g., HEAD@{1}) and restore history:
```bash
# Recover lost commits targeting the reflog identifier
git reset --hard HEAD@{1}

```
### Step 4: Purging Historical Secrets via Interactive Rebase
Simulate leaking a secret, then purge it from repository history:
```bash
# Create file containing a secret
echo 'AWS_SECRET_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"' > credentials.txt
git add credentials.txt
git commit -m "config: add default credentials file"

# Add more commits after the leak
echo "print('App running')" >> app.py
git commit -am "feat: refine application launcher"

# Purge the leaked secret commit interactively
# Target parent of secret leak commit
git rebase -i HEAD~2

```
In the interactive rebase interface editor:
 1. Change pick to drop (or d) on the secret commit line.
 2. Save and exit the editor.
 3. Remove the untracked secrets file if present:
```bash
rm -f credentials.txt

```
## 4. Verification & Validation Steps
### 1. Test Client Pre-Commit Secret Scanner
Attempt to stage and commit a hardcoded secret to test the pre-commit hook:
```bash
echo 'SECRET_KEY = "SuperSecretUnsafeTokenVal"' >> bad_code.py
git add bad_code.py
git commit -m "test: commit unsafe secret"

```
*Expected Output:*
```text
ERROR: Hardcoded secret detected in staged files!
Commit rejected by pre-commit hook.

```
### 2. Verify git bisect Automated Execution
Verify that git bisect run cleanly pinpoints the bad commit:
*Expected Output:*
```text
...
f3a1b2c3d4e5 is the first bad commit
commit f3a1b2c3d4e5
Author: DevOps Engineer <devops@example.com>
    feat(core): update data processor logic

```
### 3. Verify git reflog Recovery
Confirm that dropped commit references are restored:
```bash
git log --oneline -n 1

```
*Expected Output:* Shows the restored commit message.
## 5. Command & Tool Quick Reference
| Command / Flag | Purpose / Objective | Example Usage |
|---|---|---|
| git rebase -i <commit-ish> | Interactively modify, squash, reorder, or drop commit history. | git rebase -i HEAD~5 |
| git reflog | Display local reference logs to trace and recover lost commits. | git reflog |
| git bisect start/run | Automate binary search troubleshooting across commit history. | git bisect run ./test.sh |
| git worktree add | Mount a separate working directory linked to the main repository. | git worktree add ../hotfix main |
| git submodule update --init | Fetch and update nested submodule dependencies. | git submodule update --init --recursive |
## 6. Exam-Style Self-Assessment Questions
### Question 1
A DevOps engineer needs to find which commit introduced a performance regression across a history of 400 commits. An automated test script (test.sh) returns 0 for good commits and 1 for bad commits. Which set of Git commands automates this search?
A. git bisect start -> git bisect bad HEAD -> git bisect good HEAD~400 -> git bisect run ./test.sh
B. git rebase -i HEAD~400 -> execute ./test.sh on every squashed commit.
C. git log --grep="bug" -> git checkout each matched commit to run ./test.sh.
D. git reflog -> git reset --hard HEAD~400 -> execute ./test.sh.
### Question 2
A developer accidentally executed git reset --hard HEAD~3 on their local branch, removing three commits needed for a release. The changes were not pushed to a remote repository. How can these commits be recovered?
A. Run git checkout -b restore-branch origin/main to pull remote state.
B. Use git reflog to locate the commit hash prior to the reset, then run git reset --hard <commit-hash>.
C. Run git revert HEAD~3..HEAD to undo the hard reset.
D. Restore the lost commits using git submodule update --force.
### Answer Key & Explanations
#### Question 1
 * **Correct Answer:** **A**
 * **Explanation:** git bisect uses a binary search algorithm to locate breaking commits. Combining git bisect start, defining the bad and good boundary commits, and running git bisect run <script> automates searching without manually inspecting commits.
#### Question 2
 * **Correct Answer:** **B**
 * **Explanation:** git reflog records local head movements, including resets and branch checkouts. Locating the pre-reset commit hash in the reflog and targeting it with git reset --hard <hash> restores the lost working tree state. git revert (Choice C) creates inverse commits for existing commits rather than recovering dropped local commits.
 
