#!/bin/bash

# Check if ~/.cache/Discord-Update/deps folder exists
if [[ ! -d ~/.cache/Discord-Update/deps ]]
then
  mkdir -p ~/.cache/Discord-Update/deps
fi

# cd to ~/.cache/Discord-Update/deps to it
cd ~/.cache/Discord-Update/deps

# Pull dependencies
echo "Pulling dependencies..."

semver_script() {
    echo -n "Grabbing fsaintjacques's semantic version bash script using wget... "

    # Download script
    wget -q https://github.com/fsaintjacques/semver-tool/raw/3c76a6f9d113f4045f693845131185611a62162e/src/semver
    # Make it executable
    chmod +x semver

    echo "done"
}
semver_script

echo "done"
