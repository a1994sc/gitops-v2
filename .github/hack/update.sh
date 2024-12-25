#!/usr/bin/env bash

readarray resourceMap < <(yq -o=j -I=0 '.projects[]' .github/hack/resources.json)

for resource in "${resourceMap[@]}"; do
  path=$(echo "$resource" | yq e '.path' -)
  url=$(echo "$resource" | yq e '.repo.url' -)
  tag=$(echo "$resource" | yq e '.repo.tag' -)
  file=$(echo "$resource" | yq e '.repo.path' -)
  release=$(echo "$resource" | yq e '.repo.release' -)

  mkdir -p $path

  echo "resource: $url"
  echo "tag: $tag"

  if [ "$release" = "true" ]; then
    gh release download --repo $url --pattern $file --dir $path --clobber $tag
  else
    echo "TODO: gh file from repo"
  fi
done

git diff
