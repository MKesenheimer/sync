#/bin/sh

if ! diff -q $1 $2 &>/dev/null; then
  >&2 echo "different"
fi
