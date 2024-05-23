# Backup Over SSH

This script allows you to perform backups over SSH to a remote server. Personally used to backup website from external web hosting.

## Installation

Install required packages:

    ```bash
    apt install ssh rsync
    ```

Generate an SSH key pair and copy public key to remote server

    ```bash
    ssh-keygen -t rsa
    ```
Press enter to accept defaults.

Copy public key to remote server:

    ```bash
    ssh-copy-id REMOTE_USER@REMOTE_HOST
    ```

Additionally, you can modify /etc/ssh/sshd_config file:

    ```bash
    vim /etc/ssh/sshd_config
    ```

Inside config file find PubkeyAuthentication and change to "yes":

    ```bash
    PubkeyAuthentication yes
    ```

Clone this repository to your local machine:

    ```bash
    git clone https://github.com/reytgarr/backup-over-ssh.git
    ```

Navigate to the project directory:

    ```bash
    cd backup-over-ssh
    ```
Change permissions to allow executing file:

    ```bash
    chmod +x backup.sh
    ```
Create .env file with following variables:

    ```bash
    REMOTE_USER="YOUR_SSH_USER"
    REMOTE_HOST="YOUR_HOST"
    REMOTE_DIR="/PATH/TO/SOURCE/DIR"
    BASE_LOCAL_DIR="/PATH/TO/DESTINATION/DIR"
    BASE_TMP_DIR="/PATH/TO/SOURCE/TEMP/DIR"
    SSH_PORT=YOUR_SSH_PORT
    ```

Run script:

    ```bash
    ./backup.sh
    ```

## Cron job

To schedule this script, you can add following line to your crontab:

    ```bash
    crontab -e
    
    0 3 * * * /backup-over-ssh/backup.sh
    ```

It will create new backup each day at 3 am. Of course you can change it to you needs.



## Logs

The script creates logs in the destination directory about the backup process. If you have any problems with script - you should look there.