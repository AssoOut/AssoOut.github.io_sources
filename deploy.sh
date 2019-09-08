#!/bin/bash -
#===============================================================================
#
#         USAGE: ./deploy.sh --help
#
#   DESCRIPTION: 
#  REQUIREMENTS: ---
#        AUTHOR: Sylvain S. (ResponSyS), mail@sylsau.com
#  ORGANIZATION: 
#       CREATED: 08/29/2018 12:05:58 PM
#===============================================================================
# Enable strict mode in debug mode
[[ $DEBUG ]] && set -o nounset
set -o pipefail -o errexit -o errtrace
trap 'echo "ERROR: ${FUNCNAME:-(top level)}:$LINENO"' ERR

# TODO:
#

readonly PUBLISHDIR="_site/"
BUILD_SITE=1
CLEAN_SITE=0
COMMIT_MSG=
HUGO_OPT="--gc --minify --enableGitInfo"

fn_show_help() {
    cat << EOF
$0 
USAGE
    $0 [-m COMMIT_MSG] [-c|--clean] [--push]
OPTIONS
    -m COMMIT_MSG           deploy site to GitHub with commit message COMMIT_MSG
    -c, --clean             clean "$PUBLISHDIR" before building the site
    -n, --no-build          don't build the site
    --push                  just \`push\` without rebuilding the site
REPORTING BUGS
    Mail at: <feedback@sylsau.com>
EOF
}

fn_clean_site() {
    if [[ -d "$PUBLISHDIR" ]]; then
        echo -n "All files in \"$PUBLISHDIR\" will be deleted. Proceed? (y/n): " && read RESP
        if [[ $RESP = "y" ]]; then
            rm -rvf "$PUBLISHDIR"/*
        else
            echo "Not cleaning \"$PUBLISHDIR\""
        fi
    else
        echo "$0: can't find \"$PUBLISHDIR\" deployment directory" >&2
        exit 2
    fi
}

main() {
# Parse arguments
while [[ $# -ge 1 ]]; do
    case "$1" in
        "-m")
            COMMIT_MSG="$2"
            shift
            ;;
        "-c"|"--clean")
            CLEAN_SITE=1
            ;;
        "--push")
            cd "$PUBLISHDIR" && git push origin master
            exit
            ;;
        "-n"|"--no-build")
            BUILD_SITE=0
            ;;
        "-h"|"--help")
            fn_show_help
            exit
            ;;
        *)
            echo "$0: invalid argument: $1" >&2
            exit 1
            ;;
    esac	# --- end of case ---
    # Delete $1
    shift
done

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

if [[ CLEAN_SITE -eq 1 ]]; then
    fn_clean_site
fi
# Build the project.
if [[ BUILD_SITE -eq 1 ]]; then
    hugo $HUGO_OPT
fi
# Go to publish folder
cd "$PUBLISHDIR"
# Add changes to git.
git add . --verbose
# Commit changes.
if [[ $COMMIT_MSG = "" ]]; then
    COMMIT_MSG="rebuilding site (`date`)"
    if [[ CLEAN_SITE -eq 1 ]]; then
        COMMIT_MSG="cleaning and $COMMIT_MSG"
    fi
fi
git commit -m "$COMMIT_MSG"
# Push source and build repos.
git push origin master
# Come Back up to the Project Root
cd -
}

main "$@"

