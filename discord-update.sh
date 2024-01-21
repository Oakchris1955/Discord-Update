#!/bin/bash

url="https://discord.com/api/download?platform=linux&format=deb"
name="Discord"
debname="discord.deb"
tmpdir=$(mktemp -d /tmp/discord-update.XXXXXX)

cleanup() {
  # remove the temp directory
  echo "Cleaning up..."
  rm -r $tmpdir
}

trap_ctrlc() {
  echo "Aborted."
  cleanup
  exit
}

# Handle ctrl-c (mainly so that we can remove the tmpdir)
trap trap_ctrlc INT

if [[ ! -d ~/.cache/Discord-Update ]]
then
  echo "Cache folder not found."
  bash $(dirname $(realpath ${0}))/get-dependencies.sh
fi

# copy dependencies subfolder to the temp directory
cp -r ~/.cache/Discord-Update/deps $tmpdir

# navigate to the temp directory
cd $tmpdir

# Run wget quietly and without downloading any files and save log
wget --spider -o wget-log $url

remote_name=$(
    # Pipe wget-log to stdout
    cat wget-log |
    # Find all redirection locations
    grep Location: |
    # Get the last one
    tail -n1 |
    # Extract the filename from it
    grep -Po '\w\K/\w+[^?]+' |
    cut -d' ' -f1 |
    xargs basename
)

remote_semver=$(echo "$remote_name" | grep -oP '\b\d+\.\d+\.\d+\b')
local_semver=$(cat /usr/share/discord/resources/build_info.json | jq .version | xargs echo)

semver_comp_result=$(./deps/semver compare $remote_semver $local_semver)
semver_exit_code=$(echo $?)

# If semver script exited with error, abort
if [[ $semver_exit_code -eq 0 ]]
then
  if [[ $semver_comp_result -ge 1 ]]
  then
    echo "A most recent version is available"

    # kill all processes called discord
    echo "Killing all processes called $name"
    for KILLPID in `ps ax | grep $name | awk ' { print $1;}'`; do
    kill -9 $KILLPID &> /dev/null
    done


    echo
    echo "Getting latest version of $name from $url..."
    wget -q --show-progress -O $debname $url

    # install the deb
    echo
    echo "Installing $debname..."
    sudo dpkg -i $debname
  elif [[ $semver_comp_result -eq 0 ]]
  then
    echo "Already up-to-date"
  else
    echo "Current version isn't available"
    echo "That means that the discord version you are running is newer than the one available for download"
    echo "This is probably a bug, please file an issue at https://github.com/Oakchris1955/Discord-Update/issues"
  fi
else
  echo "semver exited with error, "
fi

cleanup

echo "Finished"
echo "You can now launch Discord"
