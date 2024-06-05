#!/bin/bash

# unset for now, will be set later
tmpdir=""

url="https://discord.com/api/download?platform=linux&format=deb"
name="Discord"
debname="discord.deb"
cache_dir=~/.cache/Discord-Update

# Handle ctrl-c (mainly so that we can remove the tmpdir)
trap trap_ctrlc INT

cleanup() {
  if [[ pwd == $tmpdir ]]; then
    # check if we have downloaded the entire executable (wget_success exists)
    if [[ -z  "$wget_success" ]]; then
      mv $debname $cache_dir
    fi
  fi

  # remove the temp directory
  echo -n "Cleaning up temp dir... "
  # these extra procautions are probably unnecessary, but better be safe than sorry, right?
  if [[ -z "$tmpdir" ]]; then
    echo "Nothing to clean"
  else
    rm -r $tmpdir
    echo "done"
  fi
}

trap_ctrlc() {
  echo "Aborted."
  cleanup
  exit 2
}

tmpdir=$(mktemp -d /tmp/discord-update.XXXXXX)

# rm is a dangerous command that's is used during the last step of cleanup, let's make sure that mktemp didn't error out or something (not likely)
mktemp_status=$?
if [[ mktemp_status -ne 0 ]]; then
  echo "For (some) reason, mktemp didn't succeed in making a temp directory. This is probably a bug, report it at https://github.com/Oakchris1955/Discord-Update/issues"
  exit 1
fi

if [[ ! -d $cache_dir ]]
then
  echo "Cache folder not found. Please run $(dirname $(realpath ${0}))/get-dependencies.sh using bash to install dependencies"
  exit 1
fi

# copy dependencies subfolder to the temp directory
cp -r $cache_dir/deps $tmpdir

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

# change the debname variable according to remote_semver
debname+="-$remote_semver"

semver_comp_result=$(./deps/semver compare $remote_semver $local_semver)
semver_exit_code=$(echo $?)

# If semver script exited with error, abort
if [[ $semver_exit_code -eq 0 ]]
then
  if [[ $semver_comp_result -ge 1 ]]
  then
    echo "A most recent version ($remote_semver) is available"

    # kill all processes nalled discord
    echo "Killing all processes named $name"
    for KILLPID in `ps ax | grep $name | awk ' { print $1;}'`; do
    kill -9 $KILLPID &> /dev/null
    done

    if [[ -f $cache_dir/${debname} ]]; then
      echo "Using cached deb ${debname}"
      cp $cache_dir/${debname} $tmpdir
    else
      echo "Getting latest version of $name ($remote_semver) from $url..."
      wget -q --show-progress -O $debname $url
      # also copy downloaded .deb to cache
      cp $debname $cache_dir/${debname}
    fi
    # check the cleanup function for more info about this line
    wget_success=1

    echo "Removing older .debs from cache to clean up space"
    find $cache_dir/discord.deb-* ! -name "$debname" -type f -exec rm {} +

    # install the deb
    dpkg_exit_code=-1
    while true
    do
      echo "Installing $debname..."
      sudo dpkg -i $debname
      dpkg_exit_code=$?
      if [ $dpkg_exit_code -eq 0 ]; then
        break
      fi
      read -s -p "An error occured when installing the package. Perharps the database is locked? Press enter to retry."
    done

    echo -n "Removing ${debname} from cache to save up space... "
    rm $cache_dir/$debname
    echo "done"
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
