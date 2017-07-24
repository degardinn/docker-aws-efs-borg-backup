# EFS Borg Backup Docker image

[`degardinn/efs-borg-backup`](https://hub.docker.com/r/degardinn/efs-borg-backup/)

A container that backups the content of an [AWS EFS](https://aws.amazon.com/efs/) cluster to another [AWS EFS](https://aws.amazon.com/efs/) cluster using the [Borg backup](https://borgbackup.readthedocs.io/) tool.

This container is meant to be run on a daily basis. Its backups are incremental, encrypted and compressed.

Although not mandatory, this image is designed to be used with its counterpart, [`degardinn/efs-borg-restore`](https://hub.docker.com/r/degardinn/efs-borg-backup/) (hence some technical choices).

## Features

When run, this container reads each subdirectory of a source **EFS** filesystem (or mounted volume), and backups each folder as a **Borg repository**, into a destination **EFS** filesystem (or mounted volume). If run again, only the difference will be backuped (incremental backup).

- Both the *source* and the *backup destination* can be either an **EFS** filesystem (maybe working for a **NFS** filesystem) or a **Docker** *mounted volume*
- Backups each folder of the *source*, into an *independent **Borg** repository* 
- Takes a *passphrase* in entry to encrypt the repositories
- Uses *ZLIB compression*
- Keeps *backup archives*

## Usage

### As a **Docker** command to run a backup from a mounted volume to another mounted volume

    docker run -v /my/volume/to/backup:/my/source -v /my/backup/destination:/mnt/backup degardinn/efs-borg-backup MyPassPhrase

### As a **Docker** command to run a remote backup with EFS volumes

    docker run degardinn/efs-borg-backup MyPassPhrase fs-a1b2c3d4.efs.us-east-1.amazonaws.com fs-c5d6e7f8.efs.us-east-1.amazonaws.com

### Command arguments

    docker run degardinn/efs-borg-backup <passphrase> <source EFS filesystem> <backup destination EFS filesystem> <repo name> <daily retention> <weekly retention> <monthly retention>

With:
 - `passphrase`: the passphrase to use to encrypt the **Borg** repositories. Necesary to restore the archives
 - `source EFS filesystem`: the URL of the **EFS** filesystem to backup. Will be mounted at `mnt/source`. If unspecified, this place can also be used to mount a **Docker** volume. 
 - `backup destination EFS filesystem`: the URL of the **EFS** filesystem where the backup repositories will be created/updated. Will be mounted at `mnt/backup`. If unspecified, this place can also be used to mount a **Docker** volume. 
 - `repo name`: the repository name to use in the backup destination. `borg` per default
 - `daily retention`: backup archives to keep. 7 daily archives to keep per default 
 - `weekly retention`: backup archives to keep. 4 weekly archives to keep per default
 - `monthly retention`: backup archives to keep. 6 monthly archives to keep per default

 ## Notes

 **EFS**'s bill is based on the stored data volume (price per gygabyte). Costs due to data transfer may also exist. Of course, I can't be held responsible for any cost related to the use of this container.