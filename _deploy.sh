#!/bin/sh

set -e

[ -z "${GITHUB_PAT}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "master" ] && exit 0

git config --global user.email "leg.ufpr@gmail.com"
git config --global user.name "LEG UFPR"

git clone -b gh-pages https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}.git site-ce003
cd site-ce003
cp -r ../docs/* ./
git add --all *
git commit -m "The site is alive." || true
git push -q origin gh-pages
