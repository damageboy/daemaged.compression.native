#!/bin/bash
mkdir -p nuget.package
git submodule foreach git clean -fdx && git submodule foreach git reset --hard
RID=$1

echo Building container for $RID
echo -----------------------------------
docker build -t $RID -f Dockerfile.$RID .
echo Running container for $RID
echo -----------------------------------
docker run -e RID=$RID --name=$RID $RID
if [[ $? != 0 ]]; then
  echo "compilation failed, aborting..."
  exit 666
fi
echo Copying artifacts from $RID container
echo -----------------------------------
docker cp $RID:/nativebinaries/runtimes nuget.package/
echo Removing container for $RID
echo -----------------------------------
docker rm $RID
