# :card_file_box: Restic Installer

📝 [restic](https://github.com/restic/restic) is an awesome backup :floppy_disk: utility, this is an script that installs it quickly on different platforms. 


### What platforms

Workks on alot of platforms.

### Breakdown

1. Checks if restic exists, if it exists, asks the user to update it.
2. If restic is not installed, it goes to github, checks for the lastest release and tries to insrtall the corresponding version.
2.5 It triest to install it in ```/usr/bin``` but if it's not possible (MacOS :trollface:) tries to install it into ```/usr/local/bin```
3. If the instalations is successfully it will ~~beg~~ ask to add an entry to ```/etc/crontab``` to update restic every night.

### Installation from the :octocat: ☁️ <sub><sup>git clone is recommended</sup></sub>
rastic can be installed in 4 (that's right, four) ways: via `git clone`, `curl`, `wget` or plain old copy paste.

#### via curl 

```shell
bash -c "$(curl -L -s https://github.com/necenzurat/restic-installer/raw/master/restic-installer.sh)"
```

#### via wget

```shell
bash -c "$(wget -q -O - https://github.com/necenzurat/restic-installer/raw/master/restic-installer.sh)"
```

#### via git clone 

```shell
git clone https://github.com/necenzurat/restic-installer/
cd restic-installer
bash restic-installer.sh
```

#### copy paste

[install-rastic.sh](restic-installer.sh), ```copy, ssh to server, paste to server, save file, then run file.```


### 📜License

[License.me](License)
