#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="${1:-${INFRASTRUCTURE_DIR:-$RENODE_DIR/../renode-infrastructure}}"
BRANCH="main-ossystems"

resolve_branch() {
    local repo="$1"
    # prefer local branch, fall back to remote tracking branch
    if git -C "$repo" rev-parse --verify "$BRANCH" &>/dev/null; then
        echo "$BRANCH"
    elif git -C "$repo" rev-parse --verify "origin/$BRANCH" &>/dev/null; then
        echo "origin/$BRANCH"
    else
        echo "Error: branch '$BRANCH' not found in $repo" >&2
        exit 1
    fi
}

VERSION="$(cat "$SCRIPT_DIR/version")"
DATE="$(date +%y%m%d)"
TAG="${VERSION}-ossystems-${DATE}"

RENODE_REF="$(resolve_branch "$RENODE_DIR")"
INFRA_REF="$(resolve_branch "$INFRA_DIR")"

if git -C "$RENODE_DIR" tag | grep -qx "$TAG"; then
    echo "Error: tag '$TAG' already exists in renode repo." >&2
    exit 1
fi

if git -C "$INFRA_DIR" tag | grep -qx "$TAG"; then
    echo "Error: tag '$TAG' already exists in renode-infrastructure repo." >&2
    exit 1
fi

echo "Creating tag: $TAG"
git -C "$RENODE_DIR" tag "$TAG" "$RENODE_REF"
git -C "$INFRA_DIR" tag "$TAG" "$INFRA_REF"

echo "Done. Tag '$TAG' created in both repos."
echo "  renode              -> $RENODE_REF"
echo "  renode-infrastructure -> $INFRA_REF"
echo ""
echo "To push:"
echo "  git -C $RENODE_DIR push origin $TAG"
echo "  git -C $INFRA_DIR push origin $TAG"
