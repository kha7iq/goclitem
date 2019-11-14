#!/bin/sh

while getopts “d” opt; do
  case $opt in
    d) ECHO=echo ;;
  esac
done

echo "Enter your username (Github org):"
read ORG

echo "Enter the name of your project:"
read NAME

set -e

${ECHO} mv ./cmd/goclitem ./cmd/${NAME}
${ECHO} mv ./cmd/${NAME}/goclitem.go ./cmd/${NAME}/${NAME}.go
${ECHO} mv ./cmd/${NAME}/goclitem_test.go ./cmd/${NAME}/${NAME}_test.go
${ECHO} mv ./goclitem.go ./${NAME}.go
${ECHO} mv ./goclitem_test.go ./${NAME}_test.go

update() {
    sed -i -e "s/dnnrly/${ORG}/g" ${1}
    sed -i -e "s/goclitem/${NAME}/g" ${1}
}

for f in `find . -type f -not -iwholename '*.git/*' -not -iwholename '*tmp*' -not -iwholename '*libexec*' -not -iwholename '*bin*' -not -iwholename '*share*' -not -iwholename '*setup*'`
do
    ${ECHO} update $f
done

