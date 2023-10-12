#!/bin/bash

set -e -x

MANIFEST=$1

# variables
# MANIFEST: manifest id
# STEAM_USERNAME: steam username
# STEAM_PASSWORD: steam password
# REPO_URL: git repo url
# REGISTRY_URL: registry url
# REGISTRY_USERNAME: registry username
# REGISTRY_PASSWORD: registry password
# DEPOTDOWNLOADER_IMAGE: depotdownloader image
# IDA_IMAGE: ida image

# wait for docker to start
echo "Waiting for docker to start..."
while ! docker info &>/dev/null; do sleep 1; done

# login to registry
echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin

# clear the data directory just in case
rm -rf /data/{*,.*} || true
cd /data

git config --global user.email "nezu-bot@nezu.cc"
git config --global user.name "nezu-bot"
git config --global init.defaultBranch master

# clone the repo if REPO_URL is set or create a new repo if not
if [ -n "$REPO_URL" ]; then
  git clone --depth 1 "$REPO_URL" .
else
  git init
fi

# create an empty commit if there are no commits
if ! git rev-parse HEAD &>/dev/null; then
  git commit --allow-empty -m "Initial commit"
fi

# create a gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
  echo ".DepotDownloader" > .gitignore
  git add .gitignore
  git commit -m "Add .gitignore"
fi

# download the manifest
mkdir -p /data/files
docker run --rm -v /data/files:/files "${REGISTRY_URL}/${DEPOTDOWNLOADER_IMAGE}" \
  -username "$STEAM_USERNAME" -password "$STEAM_PASSWORD" \
  -app 730 -depot 2347771 -manifest "$MANIFEST" \
  -os windows -osarch 64 -dir /files

# exit early if there are no changes
git add --intent-to-add files
if git diff-index --quiet HEAD -- files; then
  echo "No changes"
  exit 0
fi

# commit and push
git add files
git commit -m "Update $MANIFEST"
if [ -n "$REPO_URL" ]; then
  git push --set-upstream origin "$(git branch --show-current)"
fi

# get changed files
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACM -- files | { grep -E "\.(exe|dll)$" || test $? = 1; })
if [ -z "$CHANGED_FILES" ]; then
  echo "No changed files"
  exit 0
fi

# disassemble all files
mkdir -p /data/ida
chmod 777 /data/ida
docker pull "${REGISTRY_URL}/${IDA_IMAGE}"
echo "$CHANGED_FILES" | xargs -I{} -P 4 bash -c \
  "docker run --rm -v /data:/data -w /data -e WINEDEBUG=-all \"${REGISTRY_URL}/${IDA_IMAGE}\" -oida/\$(basename {} | cut -f 1 -d \".\").idb {}"

# commit and push
git add ida
git commit -m "Disassemble $MANIFEST"
if [ -n "$REPO_URL" ]; then
  git push --set-upstream origin "$(git branch --show-current)"
fi

# cleanup
rm -rf /data/{*,.*}