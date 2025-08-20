#!/usr/bin/env python3
"""
commentfetch.py - Fetch all PR comments from GitHub

Extracts comments from all sources:
- Inline PR comments (code review comments)
- General PR comments (issue comments)
- Review comments
- Copilot suppressed comments

Based on copilot_comment_fetch.py from PR #796 but adapted for modular architecture.
"""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

from base import CopilotCommandBase


class CommentFetch(CopilotCommandBase):
    """Fetch all comments from a GitHub PR."""

    def __init__(self, pr_number: str):
        """Initialize comment fetcher.

        Args:
            pr_number: GitHub PR number
        """
        super().__init__(pr_number)
        self.comments = []

        # Get current branch for file path
        try:
            result = subprocess.run(['git', 'branch', '--show-current'],
                                  capture_output=True, text=True, check=True)
            branch_name = result.stdout.strip()
            # Sanitize branch name for filesystem safety
            self.branch_name = self._sanitize_branch_name(branch_name) if branch_name else "unknown-branch"
        except subprocess.CalledProcessError:
            # Use consistent fallback with base class
            self.branch_name = "unknown-branch"

        # Set output file path using sanitized branch name
        self.output_file = Path(f"/tmp/{self.branch_name}/comments.json")

    def _get_inline_comments(self) -> List[Dict[str, Any]]:
        """Fetch inline code review comments."""
        self.log("Fetching inline PR comments...")

        comments = []
        # Fetch all comments with pagination
        cmd = [
            "gh",
            "api",
            f"repos/{self.repo}/pulls/{self.pr_number}/comments",
            "--paginate",
        ]

        page_comments = self.run_gh_command(cmd)
        if isinstance(page_comments, list):
            comments.extend(page_comments)

        # Standardize format
        standardized = []
        for comment in comments:
            standardized.append(
                {
                    "id": comment.get("id"),
                    "type": "inline",
                    "body": comment.get("body", ""),
                    "author": comment.get("user", {}).get("login", "unknown"),
                    "created_at": comment.get("created_at", ""),
                    "file": comment.get("path"),
                    "line": comment.get("line") or comment.get("original_line"),
                    "position": comment.get("position"),
                    "in_reply_to_id": comment.get("in_reply_to_id"),
                    "requires_response": self._requires_response(comment),
                }
            )

        return standardized

    def _get_general_comments(self) -> List[Dict[str, Any]]:
        """Fetch general PR comments (issue comments)."""
        self.log("Fetching general PR comments...")

        cmd = [
            "gh",
            "api",
            f"repos/{self.repo}/issues/{self.pr_number}/comments",
            "--paginate",
        ]

        comments = self.run_gh_command(cmd)
        if not isinstance(comments, list):
            return []

        # Standardize format
        standardized = []
        for comment in comments:
            standardized.append(
                {
                    "id": comment.get("id"),
                    "type": "general",
                    "body": comment.get("body", ""),
                    "author": comment.get("user", {}).get("login", "unknown"),
                    "created_at": comment.get("created_at", ""),
                    "requires_response": self._requires_response(comment),
                }
            )

        return standardized

    def _get_review_comments(self) -> List[Dict[str, Any]]:
        """Fetch PR review comments."""
        self.log("Fetching PR reviews...")

        cmd = [
            "gh",
            "api",
            f"repos/{self.repo}/pulls/{self.pr_number}/reviews",
            "--paginate",
        ]

        reviews = self.run_gh_command(cmd)
        if not isinstance(reviews, list):
            return []

        # Extract review body comments
        standardized = []
        for review in reviews:
            if review.get("body"):
                standardized.append(
                    {
                        "id": review.get("id"),
                        "type": "review",
                        "body": review.get("body", ""),
                        "author": review.get("user", {}).get("login", "unknown"),
                        "created_at": review.get("submitted_at", ""),
                        "state": review.get("state"),
                        "requires_response": self._requires_response(review),
                    }
                )

        return standardized

    def _get_copilot_comments(self) -> List[Dict[str, Any]]:
        """Fetch Copilot suppressed comments if available."""
        self.log("Checking for Copilot comments...")

        # Try to get Copilot-specific comments using jq filtering
        cmd = [
            "gh",
            "api",
            f"repos/{self.repo}/pulls/{self.pr_number}/comments",
            "--jq",
            '.[] | select(.user.login == "github-advanced-security[bot]" or .user.type == "Bot") | select(.body | contains("copilot"))',
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip():
                # Parse JSONL output
                comments = []
                for line in result.stdout.strip().split("\n"):
                    try:
                        comments.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass

                # Standardize format
                standardized = []
                for comment in comments:
                    standardized.append(
                        {
                            "id": comment.get("id"),
                            "type": "copilot",
                            "body": comment.get("body", ""),
                            "author": "copilot",
                            "created_at": comment.get("created_at", ""),
                            "file": comment.get("path"),
                            "line": comment.get("line"),
                            "suppressed": True,
                            "requires_response": True,  # Copilot comments usually need attention
                        }
                    )

                return standardized
        except Exception as e:
            self.log(f"Could not fetch Copilot comments: {e}")

        return []

    def _requires_response(self, comment: Dict[str, Any]) -> bool:
        """Include all comments for Claude to analyze.

        Claude will decide what needs responses, not Python pattern matching.

        Args:
            comment: Comment data

        Returns:
            True (always - let Claude decide)
        """
        # Let Claude decide what needs responses
        # No pattern matching, no keyword detection
        return True

    def _get_ci_status(self) -> Dict[str, Any]:
        """Fetch GitHub CI status using /fixpr methodology.
        
        Uses GitHub as authoritative source for CI status.
        Implements defensive programming patterns from /fixpr.
        
        Returns:
            Dict with CI status information
        """
        try:
            # Use /fixpr methodology: GitHub is authoritative source
            cmd = [
                'gh', 'pr', 'view', self.pr_number, 
                '--json', 'statusCheckRollup,mergeable,mergeStateStatus'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            pr_data = json.loads(result.stdout)
            
            # Defensive programming: statusCheckRollup is often a LIST
            status_checks = pr_data.get('statusCheckRollup', [])
            if not isinstance(status_checks, list):
                status_checks = [status_checks] if status_checks else []
            
            # Process checks with safe access patterns from /fixpr
            checks = []
            failing_checks = []
            pending_checks = []
            passing_checks = []
            
            for check in status_checks:
                if not isinstance(check, dict):
                    continue
                    
                # Prefer conclusion (for completed check runs). Fall back to state (contexts), then UNKNOWN.
                status_value = (check.get('conclusion') or check.get('state') or 'UNKNOWN')
                check_info = {
                    'name': check.get('name', check.get('context', 'unknown')),
                    'status': status_value,
                    'description': check.get('description', ''),
                    'url': check.get('detailsUrl', ''),
                    'started_at': check.get('startedAt', ''),
                    'completed_at': check.get('completedAt', '')
                }
                checks.append(check_info)
                
                # Categorize for quick analysis with safe status normalization
                status_upper = (status_value or 'UNKNOWN').upper()
                # Treat failure-like outcomes as failing
                if status_upper in ['FAILURE', 'FAILED', 'CANCELLED', 'TIMED_OUT', 'ACTION_REQUIRED', 'ERROR', 'STALE']:
                    failing_checks.append(check_info)
                # Queue/progress states are pending
                elif status_upper in ['PENDING', 'IN_PROGRESS', 'QUEUED', 'REQUESTED', 'WAITING']:
                    pending_checks.append(check_info)
                # Only SUCCESS (and optionally NEUTRAL/SKIPPED) should count as passing
                elif status_upper in ['SUCCESS', 'NEUTRAL', 'SKIPPED']:
                    passing_checks.append(check_info)
            
            # Overall CI state assessment
            overall_state = 'UNKNOWN'
            if failing_checks:
                overall_state = 'FAILING'
            elif pending_checks:
                overall_state = 'PENDING'
            elif passing_checks and not failing_checks and not pending_checks:
                overall_state = 'PASSING'
            
            return {
                'overall_state': overall_state,
                'mergeable': pr_data.get('mergeable', None),
                'merge_state_status': pr_data.get('mergeStateStatus', 'unknown'),
                'checks': checks,
                'summary': {
                    'total': len(checks),
                    'passing': len(passing_checks),
                    'failing': len(failing_checks),
                    'pending': len(pending_checks)
                },
                'failing_checks': failing_checks,
                'pending_checks': pending_checks,
                'fetched_at': datetime.now().isoformat()
            }
            
        except subprocess.CalledProcessError as e:
            self.log(f"Error fetching CI status: {e}")
            return {
                'overall_state': 'ERROR',
                'error': f"Failed to fetch CI status: {e}",
                'checks': [],
                'summary': {'total': 0, 'passing': 0, 'failing': 0, 'pending': 0}
            }
        except json.JSONDecodeError as e:
            self.log(f"Error parsing CI status JSON: {e}")
            return {
                'overall_state': 'ERROR', 
                'error': f"Failed to parse CI status: {e}",
                'checks': [],
                'summary': {'total': 0, 'passing': 0, 'failing': 0, 'pending': 0}
            }
        except Exception as e:
            self.log(f"Unexpected error fetching CI status: {e}")
            return {
                'overall_state': 'ERROR',
                'error': f"Unexpected error: {e}", 
                'checks': [],
                'summary': {'total': 0, 'passing': 0, 'failing': 0, 'pending': 0}
            }

    def execute(self) -> Dict[str, Any]:
        """Execute comment fetching from all sources."""
        self.log(f"🔄 FETCHING FRESH COMMENTS for PR #{self.pr_number} from GitHub API")
        self.log(f"⚠️ NEVER reading from cache - always fresh API calls")
        self.log(f"📁 Will save to: {self.output_file}")

        # Fetch comments and CI status in parallel for speed
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {
                executor.submit(self._get_inline_comments): "inline",
                executor.submit(self._get_general_comments): "general",
                executor.submit(self._get_review_comments): "review",
                executor.submit(self._get_copilot_comments): "copilot",
                executor.submit(self._get_ci_status): "ci_status",
            }
            
            ci_status = None

            for future in as_completed(futures):
                data_type = futures[future]
                try:
                    result = future.result()
                    if data_type == "ci_status":
                        ci_status = result
                        self.log(f"  Fetched CI status: {result.get('overall_state', 'unknown')}")
                    else:
                        # This is comment data
                        self.comments.extend(result)
                        self.log(f"  Found {len(result)} {data_type} comments")
                except Exception as e:
                    if data_type == "ci_status":
                        self.log_error(f"Failed to fetch CI status: {e}")
                        ci_status = {'overall_state': 'ERROR', 'error': str(e)}
                    else:
                        self.log_error(f"Failed to fetch {data_type} comments: {e}")

        # Sort by created_at (most recent first)
        self.comments.sort(key=lambda c: c.get("created_at", ""), reverse=True)

        # Count comments needing responses
        # After filtering, all remaining comments are unresponded
        unresponded_count = len(self.comments)

        # Prepare data to save
        data = {
            "pr": self.pr_number,
            "fetched_at": datetime.now(timezone.utc).isoformat(),
            "comments": self.comments,
            "ci_status": ci_status or {'overall_state': 'UNKNOWN', 'error': 'CI status not fetched'},
            "metadata": {
                "total": len(self.comments),
                "by_type": {
                    "inline": len(
                        [c for c in self.comments if c["type"] == "inline"]
                    ),
                    "general": len(
                        [c for c in self.comments if c["type"] == "general"]
                    ),
                    "review": len(
                        [c for c in self.comments if c["type"] == "review"]
                    ),
                    "copilot": len(
                        [c for c in self.comments if c["type"] == "copilot"]
                    ),
                },
                "unresponded_count": unresponded_count,
                "repo": self.repo,
            },
        }

        # Create directory if it doesn't exist
        self.output_file.parent.mkdir(parents=True, exist_ok=True)

        # Save to file (always replace)
        with open(self.output_file, 'w') as f:
            json.dump(data, f, indent=2)

        self.log(f"Comments saved to {self.output_file}")

        # Prepare result with CI status summary
        ci_summary = ""
        if ci_status:
            state = ci_status.get('overall_state', 'UNKNOWN')
            failing = len(ci_status.get('failing_checks', []))
            pending = len(ci_status.get('pending_checks', []))
            if failing > 0:
                ci_summary = f", CI: {failing} failing"
            elif pending > 0:
                ci_summary = f", CI: {pending} pending"
            else:
                ci_summary = f", CI: {state.lower()}"
        
        result = {
            "success": True,
            "message": f"Fetched {len(self.comments)} comments ({unresponded_count} unresponded){ci_summary} - saved to {self.output_file}",
            "data": data,
        }

        return result


def main():
    """Command line interface."""
    import argparse

    parser = argparse.ArgumentParser(description="Fetch all comments from a GitHub PR")
    parser.add_argument("pr_number", help="PR number to fetch comments from")
    parser.add_argument(
        "--output", "-o", default=None, help="No longer used - returns data directly"
    )

    args = parser.parse_args()

    fetcher = CommentFetch(args.pr_number)
    try:
        result = fetcher.execute()
        result["execution_time"] = fetcher.get_execution_time()

        # Output JSON data to stdout as documented
        print(json.dumps(result["data"], indent=2))

        # Log success to stderr so it doesn't interfere with JSON output
        import sys
        print(f"[CommentFetch] ✅ Success: {result.get('message', 'Command completed')}", file=sys.stderr)

        return 0 if result.get("success") else 1
    except Exception as e:
        fetcher.log_error(f"Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
