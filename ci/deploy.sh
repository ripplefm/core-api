#! /bin/bash
set -e

docker login -u "$DOCKER_HUB_USERNME" -p "$DOCKER_HUB_PASSWORD"

if [ -n "$TRAVIS_TAG" ]; then
  release_version=`cat mix.exs | grep "version: " | cut -d \" -f 2`
  
  # enforce mix.exs version to be equal to travis_tag
  if [[ "$TRAVIS_TAG" != "$release_version" ]]; then
    echo "Branch tag ($TRAVIS_TAG) not equal to version defined in 'mix.exs' ($release_version)"
    echo "Terminating Build..."
    exit 1
  fi

  docker build \
    --build-arg RELEASE_VERSION=${release_version} \
    --tag ripplefm/core-api:${TRAVIS_TAG} .

  docker push ripplefm/core-api:${TRAVIS_TAG}
fi

docker logout