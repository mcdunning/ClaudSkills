#!/usr/bin/env bash
# Usage: protect-branches.sh <owner/repo>
# Protects main (admins included) and develop (admins may bypass) so changes
# need a pull request. Approval count is 0: a solo owner cannot approve their
# own PR on GitHub. A gh failure is reported but never fatal.
set -uo pipefail

repo="${1:?usage: protect-branches.sh <owner/repo>}"

body() { # $1 = enforce_admins (true|false)
  cat <<JSON
{
  "required_status_checks": null,
  "enforce_admins": $1,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "restrictions": null
}
JSON
}

protect() { # $1 = branch, $2 = enforce_admins
  local err
  if err=$(body "$2" | gh api -X PUT "repos/$repo/branches/$1/protection" --input - 2>&1 >/dev/null); then
    echo "protected $1"
  else
    echo "could not protect $1: $err"
  fi
}

protect main true
protect develop false
exit 0
