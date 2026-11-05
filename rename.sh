#!/usr/bin/env bash
# Renames the library: ./rename.sh <name>
#
# Replaces mylib, Mylib and MYLIB with the new name in every file, moves
# include/mylib/ to include/<name>/, then deletes this script and the renaming
# section of the README, which are no longer needed.
# Run it once, right after creating a project from the template.
#
# Written for bash 3.2, the version macOS ships.

set -euo pipefail

old=mylib
old_capitalized=Mylib
old_upper=MYLIB

cd "$(dirname "$0")"

usage() {
    echo "usage: $0 <name>" >&2
    echo "  <name>: lowercase letters, digits and _, starting with a letter" >&2
    exit 2
}

fail() {
    echo "error: $1" >&2
    exit 1
}

[ $# -eq 1 ] || usage
new=$1

# The name becomes a C prefix (foo_add), a folder (include/foo/) and part of a
# file name (libfoo.a): only accept what is valid in all three.
[[ $new =~ ^[a-z][a-z0-9_]*$ ]] || { echo "error: invalid name \"$new\"" >&2; usage; }
[ "$new" != "$old" ] || fail "the library is already called $old"
[ -d "include/$old" ] || fail "include/$old/ not found: has the library already been renamed?"

# In a git repository, start from a clean tree: the rename can then be
# reviewed with git diff, and undone with git checkout.
in_git=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    in_git=true
    [ -z "$(git status --porcelain)" ] ||
        fail "uncommitted changes: commit or stash them first"
fi

# my_parser -> MY_PARSER (macros), MyParser (types: MylibError -> MyParserError).
new_upper=$(printf '%s' "$new" | tr '[:lower:]' '[:upper:]')
new_capitalized=$(printf '%s' "$new" | awk -F_ '{
    for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2)
}')

# The README section about renaming, and the line about this script in the
# project tree, only make sense before renaming.
sed -i.bak \
    -e '/<!-- rename:start -->/,/<!-- rename:end -->/d' \
    -e '/rename\.sh .*deletes itself/d' \
    README.md
rm README.md.bak

# Every text file that mentions the old name, except the build folders and
# this script. (sed -i.bak works with both BSD and GNU sed.)
count=0
while IFS= read -r -d '' file; do
    if grep -Iq -e "$old" -e "$old_capitalized" -e "$old_upper" "$file"; then
        sed -i.bak \
            -e "s/$old/$new/g" \
            -e "s/$old_capitalized/$new_capitalized/g" \
            -e "s/$old_upper/$new_upper/g" \
            "$file"
        rm "$file.bak"
        echo "  updated $file"
        count=$((count + 1))
    fi
done < <(find . \( -name .git -o -name build -o -name build-release \) -prune \
    -o -type f ! -path ./rename.sh -print0)

if $in_git; then
    git mv "include/$old" "include/$new"
    git rm -q rename.sh
else
    mv "include/$old" "include/$new"
    rm rename.sh
fi

echo
echo "Renamed $old to $new in $count files, moved include/$old/ to include/$new/."
echo "Deleted rename.sh and the renaming section of the README."
echo "Next: review the changes, then from a clean build folder:"
echo "  rm -rf build build-release"
echo "  cmake --workflow --preset debug"
