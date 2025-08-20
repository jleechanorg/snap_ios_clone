# /fixpr Command - Intelligent PR Fix Analysis

**Usage**: `/fixpr <PR_NUMBER> [--auto-apply]`

**Purpose**: Make GitHub PRs mergeable by analyzing and fixing CI failures, merge conflicts, and bot feedback - without merging. **NEW**: Automatically uses `/redgreen` methodology when GitHub CI fails but local tests pass.

## 🚨 FUNDAMENTAL PRINCIPLE: GITHUB IS THE AUTHORITATIVE SOURCE

**CRITICAL RULE**: GitHub PR status is the ONLY source of truth. Local conditions (tests, conflicts, etc.) may differ from GitHub's reality.

**MANDATORY APPROACH**:
- ✅ **ALWAYS start by fetching fresh GitHub PR status**
- ✅ **ALWAYS display GitHub status inline for transparency**
- ✅ **ALWAYS verify fixes against GitHub, not local assumptions**
- ❌ **NEVER assume local tests/conflicts match what GitHub sees**
- ❌ **NEVER fix local issues without confirming they block the GitHub PR**

**WHY THIS MATTERS**: GitHub uses different CI environments, merge algorithms, and caching than local development. A PR may be mergeable locally but blocked on GitHub, or vice versa.

## Description

The `/fixpr` command leverages Claude's natural language understanding to analyze PR blockers and fix them. The goal is to get the PR into a mergeable state (all checks passing, no conflicts) but **never actually merge it**. It orchestrates GitHub tools and git commands through intent-based descriptions rather than explicit syntax.

**🆕 Enhanced with `/redgreen` Integration**: When GitHub CI shows test failures that don't reproduce locally, `/fixpr` automatically triggers the Red-Green-Refactor methodology to create failing tests locally, fix the environment-specific issues, and verify the solution works in both environments.

## 🚀 Enhanced Execution

**Enhanced Universal Composition**: `/fixpr` now uses `/e` (execute) for intelligent optimization while preserving its core universal composition architecture.

### Execution Strategy

**Default Mode**: Uses `/e` to determine optimal approach
- **Trigger**: Simple PRs with ≤10 issues or straightforward CI failures
- **Behavior**: Standard universal composition approach with direct Claude analysis
- **Benefits**: Fast execution, minimal overhead, reliable for common cases

**Parallel Mode** (Enhanced):
- **Trigger**: Complex PRs with >10 distinct issues, multiple conflict types, or extensive CI failures
- **Behavior**: Spawn specialized analysis agents while Claude orchestrates integration
- **Benefits**: Faster processing of complex scenarios, parallel issue resolution

### Agent Types for PR Analysis

1. **CI-Analysis-Agent**: Specializes in GitHub CI failure analysis and fix recommendations
2. **Conflict-Resolution-Agent**: Focuses on merge conflict analysis and safe resolution strategies
3. **Bot-Feedback-Agent**: Processes automated bot comments and implements applicable suggestions
4. **Verification-Agent**: Validates fix effectiveness and re-checks mergeability status

**Coordination Protocol**: Claude maintains overall workflow control, orchestrating agent results through natural language understanding integration.

## Workflow

### Step 1: Gather Repository Context

Dynamically detect repository information from the git environment:
- Extract the repository owner and name from git remote (handling both HTTPS and SSH URL formats)
- Determine the default branch without assuming it's 'main' (could be 'master', 'develop', etc.)
- Validate the extraction succeeded before proceeding
- Store these values for reuse throughout the workflow

💡 **Implementation hints**:
- Repository URLs come in formats like `https://github.com/owner/repo.git` or `git@github.com:owner/repo.git`
- Default branch detection should have fallbacks for fresh clones
- Always quote variables in bash to handle spaces safely

### Step 2: Fetch Critical GitHub PR Data - **GITHUB IS THE AUTHORITATIVE SOURCE**

🚨 **CRITICAL PRINCIPLE**: GitHub PR status is the ONLY authoritative source of truth. NEVER assume local conditions match GitHub reality.

**MANDATORY GITHUB FIRST APPROACH**:
- ✅ **ALWAYS fetch fresh GitHub status** before any analysis or fixes
- ✅ **NEVER assume local tests/conflicts match GitHub**
- ✅ **ALWAYS print GitHub status inline** for full transparency
- ❌ **NEVER fix local issues without confirming they exist on GitHub**
- ❌ **NEVER trust cached or stale GitHub data**

🚨 **DEFENSIVE PROGRAMMING FOR GITHUB API RESPONSES**:
- ✅ **ALWAYS handle both list and dict responses** from GitHub API
- ✅ **NEVER use .get() on variables that might be lists**
- ✅ **Use isinstance() checks** before accessing dict methods
- ❌ **NEVER assume GitHub API response structure**

**SAFE DATA ACCESS PATTERN**:
```python
# When processing GitHub API responses like statusCheckRollup, reviews, or comments
if isinstance(data, dict):
    value = data.get('key', default)
elif isinstance(data, list) and len(data) > 0:
    # Handle list responses (checks, comments, reviews)
    value = data[0].get('key', default) if isinstance(data[0], dict) else default  # Default if data[0] is not a dict
else:
    value = default  # Default if data is neither a dict nor a non-empty list
```

**EXPLICIT GITHUB STATUS FETCHING** - Fetch these specific items from GitHub to understand what's blocking mergeability:

1. **CI State & Test Failures** (GitHub Authoritative):
   - **MANDATORY**: `gh pr view <PR> --json statusCheckRollup` - Get ALL CI check results
   - **DEFENSIVE**: statusCheckRollup is often a LIST of checks, not a single object
   - **SAFE ACCESS**: Use list iteration, never .get() on the rollup array
   - **DISPLAY INLINE**: Print exact GitHub CI status: `❌ FAILING: test-unit (exit code 1)`
   - **FETCH LOGS (Primary)**: Use statusCheckRollup descriptions for failing checks (authoritative and fast):
     ```bash
     gh pr view "$PR_NUMBER" --json statusCheckRollup --jq \
       '.statusCheckRollup[] | select(.state == "FAILURE") | "\(.context): \(.description)"'
     ```
   - **Roadmap (non-executable)**: Future enhancements will include workflow/job log retrieval via the Actions API for deeper analysis (job logs, step-level errors, artifact links).
   - **VERIFY AUTHORITY**: Cross-check GitHub vs local - local is NEVER authoritative
   - **SAFE PROCESSING PATTERN**:
     ```
     # When processing statusCheckRollup (which is a list):
     for check in statusCheckRollup:  # DON'T use .get() on statusCheckRollup itself
         status = check.get('state', 'unknown')  # OK - check is a dict
         name = check.get('context', 'unknown')
     ```
   - **EXAMPLE OUTPUT**:
     ```
     🔍 GITHUB CI STATUS (Authoritative):
     ❌ test-unit: FAILING (required) - TypeError: Cannot read property 'id' of undefined
     ✅ test-lint: PASSING (required)
     ⏳ test-integration: PENDING (required)
     ```

2. **Merge Conflicts** (GitHub Authoritative):
   - **MANDATORY**: `gh pr view <PR> --json mergeable,mergeableState` - Get GitHub merge status
   - **DISPLAY INLINE**: Print exact GitHub merge state: `❌ CONFLICTING: 3 files have conflicts`
   - **FETCH DETAILS**: `gh pr diff <PR>` - Get actual conflict content from GitHub
   - **NEVER ASSUME LOCAL**: Local git status may not match GitHub's merge analysis
   - **EXAMPLE OUTPUT**:
     ```
     🔍 GITHUB MERGE STATUS (Authoritative):
     ❌ mergeable: false
     ❌ mergeableState: CONFLICTING
     📄 Conflicting files: src/main.py, tests/test_main.py, README.md
     ```

3. **Bot Feedback & Review Comments** (GitHub Authoritative):
   - **MANDATORY**: `gh pr view <PR> --json reviews,comments` - Get ALL review data from GitHub
   - **DEFENSIVE**: reviews and comments are LISTS, not single objects
   - **SAFE ACCESS**: Iterate through lists, never .get() on the arrays themselves
   - **DISPLAY INLINE**: Print blocking reviews: `❌ CHANGES_REQUESTED by @reviewer`
   - **FETCH COMMENTS**: Get all bot and human feedback directly from GitHub API
   - **SAFE PROCESSING PATTERN**:
     ```
     # When processing reviews (which is a list):
     for review in reviews:  # DON'T use .get() on reviews itself
         state = review.get('state', 'unknown')  # OK - review is a dict
         user = review.get('user', {}).get('login', 'unknown')

     # When processing comments (which is a list):
     for comment in comments:  # DON'T use .get() on comments itself
         body = comment.get('body', '')  # OK - comment is a dict
         author = comment.get('user', {}).get('login', 'unknown')
     ```
   - **EXAMPLE OUTPUT**:
     ```
     🔍 GITHUB REVIEW STATUS (Authoritative):
     ❌ @coderabbit: CHANGES_REQUESTED - Fix security vulnerability in auth.py
     ✅ @teammate: APPROVED
     ⏳ @senior-dev: REVIEW_REQUESTED
     ```

4. **PR Metadata & Protection Rules** (GitHub Authoritative):
   - **MANDATORY**: `gh pr view <PR> --json state,mergeable,requiredStatusChecks` - Get current GitHub PR state
   - **DISPLAY INLINE**: Print exact GitHub merge button status and blocking factors
   - **FETCH PROTECTION**: Get branch protection rules that may prevent merging
   - **EXAMPLE OUTPUT**:
     ```
     🔍 GITHUB PR METADATA (Authoritative):
     📄 State: OPEN | Mergeable: false
     🛡️ Required checks: [test-unit, test-lint, security-scan]
     🚫 Blocking factors: 1 failing check, 1 requested change
     ```

🎯 **THE GOAL**: Gather everything that GitHub shows as preventing the green "Merge" button from being available - NEVER assume, ALWAYS verify with fresh GitHub data.

### Step 3: Analyze Issues with Intelligence & Pattern Detection

🚨 **CRITICAL BUG PREVENTION**: Before analyzing any GitHub API data, ALWAYS verify data structure to prevent "'list' object has no attribute 'get'" errors.

**MANDATORY DATA STRUCTURE VERIFICATION**:
- ✅ **Check if data is list or dict** before using .get() methods
- ✅ **Use isinstance(data, dict)** before accessing dict methods
- ✅ **Iterate through lists** rather than treating them as single objects
- ❌ **NEVER assume API response structure**

🚀 **NEW: PATTERN DETECTION ENGINE** - Automatically scan for similar issues across the codebase

**FIRESTORE MOCKING PATTERN DETECTION** (High Priority):
```bash
# Detect mismatched Firestore mocking patterns that cause MagicMock JSON serialization errors
# Pattern: Tests patching firebase_admin.firestore.client but code calling firestore_service.get_db()

# 1. Scan for problematic mocking patterns
grep -r "@patch.*firebase_admin\.firestore\.client" . --include="*.py" || echo "No firebase_admin.firestore.client patterns found"

# 2. Cross-reference with actual service calls
grep -r "firestore_service\.get_db" . --include="*.py" || echo "No firestore_service.get_db calls found"

# 3. Report mismatch pattern for bulk fixing
echo "🔍 PATTERN DETECTION: Firestore mocking mismatch"
echo "❌ Problem: Tests patch 'firebase_admin.firestore.client'"  
echo "✅ Solution: Should patch 'firestore_service.get_db'"
echo "📊 Impact: Prevents MagicMock JSON serialization errors"
```

**MAGICMOCK SERIALIZATION PATTERN DETECTION**:
```bash
# Detect other patterns that cause "Object of type MagicMock is not JSON serializable" errors

# 1. Scan for MagicMock usage in tests that interact with JSON APIs
grep -r "MagicMock" . --include="test_*.py" -A 5 -B 5 | grep -E "(json\.|\.json|JSON)" || echo "No MagicMock+JSON patterns found"

# 2. Look for patch decorators that don't return proper fake objects
grep -r "@patch" . --include="test_*.py" -A 10 | grep -E "(return_value.*MagicMock|side_effect.*MagicMock)" || echo "No problematic MagicMock return patterns found"
```

**SCOPE FLAGS FOR PATTERN DETECTION**:
- **Default Behavior**: Fix only immediate blockers (existing behavior preserved)
- **`--scope=pattern`**: Fix detected issues + apply same fix to similar patterns across codebase
- **`--scope=comprehensive`**: Fix all related test infrastructure issues

Examine the collected data to understand what needs fixing:

**CI Status Analysis**:
- **SAFE APPROACH**: Remember statusCheckRollup is a list - iterate through checks
- **DETAILED LOG ANALYSIS**: Parse GitHub Actions logs to extract specific failures:
  ```bash
  set -o pipefail
  # Extract specific failing tests and error messages (pytest + Python errors)
  gh api "repos/$OWNER/$REPO/actions/jobs/$job_id/logs" | \
    grep -Ei \
      -e '^FAILURES?' \
      -e '^=+ FAILURES =+' \
      -e 'collected [0-9]+ items' \
      -e '===+ [0-9]+ (failed|errors?|x?failed|x?passed)' \
      -e 'E\s+AssertionError' \
      -e 'Traceback \(most recent call last\):' \
      -e 'ModuleNotFoundError:' \
      -e 'ImportError:' \
      -e 'NameError:' \
      -e 'TypeError:' \
      -e '\.py[:,]?\d+(:\d+)?' \
    -A 3 -B 3
  
  # Common patterns to identify:
  # - ModuleNotFoundError: Missing imports or dependencies
  # - AssertionError: Test logic failures with specific expectations  
  # - NameError: Undefined variables or missing imports
  # - ImportError: Module loading issues
  # - TypeError: Type mismatches in function calls
  # - Orchestration failures: Redis/tmux dependency issues
  # - File permission or path issues in CI environment
  ```
- Distinguish between flaky tests (timeouts, network issues) and real failures
- Identify patterns in failures (missing imports, assertion errors, environment issues)
- Compare GitHub CI results with local test runs to spot environment-specific problems

**Merge Conflict Analysis**:
- Assess conflict complexity - are they simple formatting issues or complex logic changes?
- Categorize conflicts by risk level (low risk: comments/formatting, high risk: business logic)
- Determine which conflicts can be safely auto-resolved vs requiring human review

**Bot Feedback Processing**:
- **SAFE APPROACH**: Remember reviews and comments are lists - iterate through them
- Extract actionable suggestions from automated code reviews
- Prioritize fixes by impact and safety
- Identify quick wins vs changes requiring careful consideration

### Step 4: Detect CI Environment Discrepancies

🚨 **CRITICAL DETECTION**: Before applying fixes, detect if GitHub CI failures are environment-specific.

**GitHub CI vs Local Test Discrepancy Detection**:
- **MANDATORY CHECK**: Run local tests first: `./run_tests.sh`
- **DISCREPANCY INDICATOR**: Local tests pass (✅) but GitHub CI shows failures (❌)
- **COMMON CAUSES**:
  - Different Python versions between local and CI
  - Missing environment variables in CI
  - Different package versions or dependencies
  - Race conditions that only manifest in CI environment
  - Time zone or locale differences
  - File system case sensitivity (CI often Linux, local might be macOS/Windows)

**When Discrepancy Detected, Trigger `/redgreen` Workflow**:
```bash
# 1. Verify local tests pass
./run_tests.sh
# ✅ All tests pass locally

# 2. Check GitHub CI status
gh pr view <PR> --json statusCheckRollup
# ❌ test-unit: FAILING - AssertionError: Expected 'foo' but got 'FOO'

# 3. AUTO-TRIGGER /redgreen methodology for this specific failure
# This should be handled by the enhanced fixpr logic
```

### Step 5: Apply Fixes Intelligently

🎯 **FOCUSED APPROACH**: Apply fixes to the immediate issues identified in the current PR

Based on the analysis, apply appropriate fixes:

**For CI Failures**:
- **Environment issues**: Update dependencies, fix missing environment variables, adjust timeouts
- **Code issues**: Correct import statements, fix failing assertions, add type annotations
- **Test issues**: Update test expectations, fix race conditions, handle edge cases
- **🚨 GitHub CI vs Local Discrepancy**: When GitHub CI fails but local tests pass, use `/redgreen` methodology:
  - **RED PHASE**: Create failing tests that reproduce the GitHub CI failure locally
  - **GREEN PHASE**: Fix the code to make both local and GitHub tests pass
  - **REFACTOR PHASE**: Clean up the solution while maintaining test coverage
  - **Trigger**: GitHub shows failing tests but `./run_tests.sh` passes locally
  - **Process**: Extract GitHub CI error → Write failing test → Implement fix → Verify both environments

### 🚨 Integrated `/redgreen` Workflow for CI Discrepancies

**AUTOMATIC ACTIVATION**: When GitHub CI fails but local tests pass, `/fixpr` automatically implements this workflow:

#### RED PHASE: Reproduce GitHub Failure Locally
```bash
# 1. Extract specific GitHub CI failure details
gh pr view <PR> --json statusCheckRollup | jq '.[] | select(.state == "FAILURE")'
# Example: "AssertionError: Expected 'foo' but got 'FOO' in test_case_sensitivity"

# 2. Create a failing test that reproduces the CI environment condition
# Example: Create test that fails due to case sensitivity like CI environment
PROJECT_ROOT=$(git rev-parse --show-toplevel)
TESTS_DIR="$PROJECT_ROOT/tests"
cat > "$TESTS_DIR/test_ci_discrepancy_redgreen.py" << 'EOF'
"""RED-GREEN test to reproduce GitHub CI failure locally."""
import os
import unittest

class TestCIDiscrepancy(unittest.TestCase):
    def test_case_sensitivity_like_ci(self):
        """RED: Reproduce the case sensitivity issue from GitHub CI."""
        # Simulate CI environment behavior (Linux case-sensitive)
        os.environ['FORCE_CASE_SENSITIVE'] = 'true'

        # This should fail locally to match GitHub CI failure
        result = some_function_that_failed_in_ci()
        self.assertEqual(result, 'foo')  # This will fail like CI if function returns 'FOO'

def some_function_that_failed_in_ci():
    """Simulate the CI failure condition - replace with actual failing function."""
    # Example: Simulate a case sensitivity issue by returning 'FOO' instead of 'foo'
    return 'FOO'
EOF

# 3. Verify test fails locally (RED confirmed)
# Use project-specific test runner (examples: python -m pytest, TESTING=true vpython, etc.)
<RUN_TEST_COMMAND> "$TESTS_DIR/test_ci_discrepancy_redgreen.py"
# ❌ FAIL: AssertionError: Expected 'foo' but got 'FOO'
```

#### GREEN PHASE: Fix Code to Pass Both Environments
```bash
# 4. Implement fix that works in both local and CI environments
# Example: Fix the case sensitivity issue
# Edit the source code to handle both environments consistently

# 5. Verify local test now passes (GREEN confirmed)
<RUN_TEST_COMMAND> "$TESTS_DIR/test_ci_discrepancy_redgreen.py"
# ✅ PASS: Test now passes locally

# 6. Verify all existing tests still pass
./run_tests.sh
# ✅ All tests pass
```

#### REFACTOR PHASE: Clean Up and Optimize
```bash
# 7. Clean up the fix while maintaining test coverage
# - Remove any temporary debugging code
# - Optimize the solution
# - Add proper error handling
# - Update documentation if needed

# 8. Final verification
./run_tests.sh && ./run_ci_replica.sh
# ✅ All tests pass in both local and CI-equivalent environments
```

**INTEGRATION WITH FIXPR WORKFLOW**:
- This `/redgreen` workflow is triggered automatically within `/fixpr` when CI discrepancies are detected
- Results in more robust fixes that work across environments
- Prevents push/fail/fix cycles by reproducing CI conditions locally
- Creates test cases that prevent regression of environment-specific issues
- **MANDATORY VERIFICATION**: After each fix category, run `./run_ci_replica.sh` to confirm fix works in CI environment

**For Merge Conflicts**:
- **Safe resolutions**: Combine imports from both branches, merge non-conflicting configuration
- **Function signatures**: Preserve parameters from both versions when possible
- **Complex conflicts**: Flag for human review with clear explanation of the conflict

**For Bot Suggestions**:
- Apply formatting and style fixes
- Implement suggested error handling improvements
- Add missing documentation or type hints

### Step 5: Verify Mergeability Status - **MANDATORY GITHUB RE-VERIFICATION**

🚨 **CRITICAL**: After applying fixes, ALWAYS re-fetch fresh GitHub status. NEVER assume fixes worked without GitHub confirmation.

**MANDATORY GITHUB RE-VERIFICATION PROTOCOL**:

1. **Re-fetch Fresh GitHub Status** (Wait for CI to complete):
   - **WAIT**: Allow 30-60 seconds for GitHub CI to register changes after push
   - **RE-FETCH**: `gh pr view <PR> --json statusCheckRollup,mergeable,mergeableState`
   - **DISPLAY**: Print updated GitHub status inline with before/after comparison
   - **EXAMPLE**:
     ```text
     🔄 GITHUB STATUS VERIFICATION (After Fixes):

     BEFORE:
     ❌ test-unit: FAILING - TypeError in auth.py
     ❌ mergeable: false

     AFTER (Fresh from GitHub):
     ✅ test-unit: PASSING - All tests pass
     ✅ mergeable: true

     📊 RESULT: PR is now mergeable on GitHub
     ```
   - Verify mergeable status changed from CONFLICTING to MERGEABLE
   - Confirm no new test failures were introduced
   - Ensure bot feedback has been addressed

2. **Local CI Replica Verification**:
   - **MANDATORY**: Run `./run_ci_replica.sh` to verify fixes in CI-equivalent environment
   - **PURPOSE**: Ensures fixes work in the same environment as GitHub Actions CI
   - **ENVIRONMENT**: Sets CI=true, GITHUB_ACTIONS=true, TESTING=true, TEST_MODE=mock
   - **VALIDATION**: Must pass completely before considering fixes successful
   - Check git status for uncommitted changes
   - Verify no conflicts remain with the base branch

3. **Push and Monitor**:
   - Push fixes to the PR branch
   - Wait for GitHub to re-run CI checks
   - Monitor the PR page to see blockers clearing

4. **Success Criteria**:
   - All required CI checks show green checkmarks
   - GitHub shows "This branch has no conflicts"
   - No "Changes requested" reviews blocking merge
   - The merge button would be green (but we don't click it!)

If blockers remain, iterate through the analysis and fix process again until the PR is fully mergeable.

## Auto-Apply Mode

When `--auto-apply` is specified, the command operates more autonomously:

**Safe Fixes Only**:
- Import statement corrections
- Whitespace and formatting cleanup
- Documentation updates
- Bot-suggested improvements that don't change logic

**Always Preserve**:
- Existing functionality from both branches
- Business logic integrity
- Security-related code patterns

**Incremental Approach**:
- Apply one category of fixes at a time
- Test after each change
- Stop if tests fail unexpectedly

## Intelligence Guidelines

### CI Failure Patterns

**Flaky Test Indicators**:
- Timeouts in external API calls
- Intermittent database connection failures
- Time-dependent test failures

**Real Issues Requiring Fixes**:
- Import errors (ModuleNotFoundError)
- Assertion failures with consistent patterns
- Type errors and missing dependencies

### Merge Conflict Resolution Strategy

**Preservation Priority**:
1. Never lose functionality - combine features when possible
2. Prefer bug fixes over new features in conflicts
3. Maintain backward compatibility
4. Keep security improvements from both branches

**Risk-Based Approach**:
- **Low Risk**: Documentation, comments, formatting, test additions
- **Medium Risk**: UI changes, non-critical features, configuration updates
- **High Risk**: Authentication, data handling, payment processing, API changes

### Fix Documentation

For every fix applied:
- Document why the specific resolution was chosen
- Add comments for complex merge decisions
- Create clear commit messages explaining changes
- Flag any high-risk modifications for review

## Example Usage

```bash
# Analyze and show what would be fixed (default: critical scope)
/fixpr 1234

# Analyze and automatically apply safe fixes
/fixpr 1234 --auto-apply

# 🚀 NEW: Pattern detection mode - Fix similar issues across codebase
/fixpr 1234 --scope=pattern
# → Fixes immediate blockers
# → Scans for similar patterns (e.g., firestore mocking mismatches)
# → Applies same fix to all instances
# → Prevents future similar failures

# Comprehensive mode - Fix all related test infrastructure
/fixpr 1234 --scope=comprehensive --auto-apply

# Example with GitHub CI vs Local discrepancy (auto-triggers /redgreen workflow):
# Local: ./run_tests.sh → ✅ All tests pass
# GitHub: CI shows ❌ test-unit FAILING - Environment-specific test failure
/fixpr 1234
# → Automatically detects discrepancy
# → Triggers RED-GREEN workflow
# → Creates failing test locally
# → Fixes code to work in both environments
# → Verifies GitHub CI passes

# Example with MagicMock JSON serialization pattern:
# GitHub: ❌ "Object of type MagicMock is not JSON serializable"
/fixpr 1234 --scope=pattern
# → Identifies @patch("firebase_admin.firestore.client") mismatch
# → Fixes immediate test to @patch("firestore_service.get_db")
# → Scans codebase for similar patterns
# → Fixes 4+ additional test files with same issue
# → Prevents regression of MagicMock serialization errors
```

## Integrated CI Verification Workflow

**Complete Fix and Verification Cycle**:
```bash
# 1. Apply fixes based on GitHub status analysis
# (implement fixes for failing CI checks, conflicts, etc.)

# 2. MANDATORY: Verify fixes work in CI-equivalent environment
./run_ci_replica.sh

# 3. If CI replica passes, commit and sync fixes to GitHub
git add -A && git commit -m "fix: Address CI failures and merge conflicts"

# 🚨 MANDATORY: Smart sync check to ensure changes reach remote
$(git rev-parse --show-toplevel)/scripts/sync_check.sh

# 4. Wait 30-60 seconds for GitHub CI to process
sleep 60

# 5. Re-verify GitHub status shows green
gh pr view <PR> --json statusCheckRollup,mergeable,mergeStateStatus
```

**Key Benefits of run_ci_replica.sh Integration**:
- **Environment Parity**: Exact match with GitHub Actions CI environment variables
- **Early Detection**: Catch CI failures locally before pushing to GitHub
- **Time Efficiency**: Avoid multiple push/wait/fail cycles
- **Confidence**: Know fixes will work in CI before pushing

## Integration Points

This command works naturally with:
- `/copilot` - For comprehensive PR workflow orchestration
- `/commentreply` - To respond to review feedback
- `/pushl` - To push fixes to remote
- `/redgreen` (alias `/tdd`) - **NEW**: Automatically triggered for GitHub CI vs local test discrepancies
- Testing commands - To verify fixes work correctly
- `./run_ci_replica.sh` - To verify fixes work in CI-equivalent environment

## Error Recovery

When issues arise:
- Gracefully handle missing tools by trying alternatives
- Provide clear explanations of what failed and why
- Suggest manual steps when automation isn't possible
- Maintain partial progress rather than failing completely

## Natural Language Advantage

This approach leverages Claude's understanding to:
- Adapt to different repository structures
- Handle edge cases without explicit programming
- Provide context-aware solutions
- Explain decisions in human terms

The focus is on describing intent and letting Claude determine the best implementation, making the command more flexible and maintainable than rigid scripted approaches.

## Important Notes

**🚨 NEVER MERGE**: This command's job is to make PRs mergeable, not to merge them. The user retains control over when/if to actually merge.

**📊 Success Metric**: A successful run means GitHub would show a green merge button with no blockers - all CI passing, no conflicts, no blocking reviews.
