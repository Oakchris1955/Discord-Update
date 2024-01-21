Original by [Blacktea1501](https://github.com/Blacktea1501) and [Pantonius](https://github.com/Pantonius)

# Discord Updater
Downloads and installs the latest Discord version for Linux.

# My changes
- Download `discord.deb` only if Discord isn't already up-to-date
- Handle Ctrl-C: remove the /tmp/discord-update.XXXXXX directory even if the bash script is interrupted
- Use the `~/.cache` directory to store various dependencies, such as the `semver` script

## Setup
```bash
# Clone the repository
git clone https://github.com/Oakchris1955/Discord-Update.git

# Change into the directory
cd Discord-Update

# Grab dependencies
bash get-dependencies.sh

# Make the script executable
chmod +x discord-update.sh
```

## Usage
```bash
./discord-update.sh
```

### Optional
You may prefer to run the script from anywhere on the system.
The best way is to make a symlink to a scripts folder and adding it to your `$PATH` environment varibale.  
Assuming the directory of the repository is on your Desktop and your scripts folder is in your home directory, you can do it like so:
```bash
ln -s /home/user/Desktop/Discord-Update/discord-update.sh /home/user/scripts/discord-update
```

The scripts folder can be added to your `$PATH` variable, so you can run the script from anywhere. To do this, add the following line to your `.bashrc` file:
```bash
export PATH=/home/user/scripts:$PATH
```
**DO NOT FORGET TO ADD `$PATH` TO THE END. We don't want to break your cmdline!**  

Now you can simply run the script by typing `discord-update` in your terminal:
```bash
discord-update
```

### Notes

- Make sure that the `discord-update.sh` and `get-dependencies.sh` scripts are **ALWAYS** in the same directory, otherwise `discord-update.sh` might fail
