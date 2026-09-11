#!/bin/bash

PARSE_ONLY=0

# Only GNU diff can label the two sides
if command -v gdiff >/dev/null 2>&1; then
    DIFF=gdiff
else
    DIFF=diff
fi

function just_body {
    if [[ $PARSE_ONLY == 1 ]]; then
        sed -e '/^[[:space:]]*$/d' -e '/^#/d' \
            -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+/ /g'
    else
        sed -e '/^#/d' -e '/^$/d'
    fi
}

function test_file {
    file=$1
    label=
    [[ $DIFF == gdiff ]] && label="-L $file-(Sun-cpp) -L $file-(Joyent-cpp)"
    $DIFF $label -u \
        <(timeout 60 /usr/lib/cpp $file 2>/dev/null | just_body) \
        <(timeout 60 ./cpp $file 2>/dev/null | just_body)
}

while getopts p name; do
    case $name in
        p) PARSE_ONLY=1;;
    esac
done
shift $(($OPTIND - 1))

if (( $# > 0 )); then
    while (( $# > 0 )); do
        test_file $1
        shift;
    done
else
    for elt in $(find /usr/include -name '*.h' | sort); do
        # C++ that will never parse
        [[ $elt == */firefox/* ]] && continue
        # Triggers pre-ANSI infinitely recursive expansion
        [[ $elt == */ncurses/* ]] && continue
        echo "*** $elt" >&2
        test_file $elt
    done
fi
