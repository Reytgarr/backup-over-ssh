#!/bin/bash

# Variables
source ./.env
DATE=$(date +"%Y-%m-%d")
LOCAL_FILE="${BASE_LOCAL_DIR}/backup_${DATE}.tar.gz"
LOG_FILE="${BASE_LOCAL_DIR}/backup-log.log"
TMP_DIR="${BASE_TMP_DIR}/backup_${DATE}"
DELETE_DAYS=10


log_message() {
    echo "$(date) - $1" >> $LOG_FILE
}

check_result() {
    if [ $? -eq 0 ]; then
        log_message "$1 completed successfully."
    else
        log_message "$1 failed. Check the log for details."
        exit 1
    fi
}

log_message "Starting backup.sh script..."
log_message "Backup source directory: $REMOTE_DIR"
log_message "Backup destination directory: $BASE_LOCAL_DIR"
log_message "Temporary files directory: $TMP_DIR"


# Create temporary directory on remote server
ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST "mkdir -p $TMP_DIR/tmp" >> $LOG_FILE 2>&1
check_result "Creating temporary directory on remote server"

# Rsync command to synchronize remote data to temporary directory
log_message "Starting rsync on remote server..."
ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST "rsync -avz $REMOTE_DIR $TMP_DIR/tmp" >> /dev/null 2>&1
check_result "Rsync on remote server"

# Check if files are copied on remote server
if ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST "[ -n \"\$(ls -A $TMP_DIR/tmp)\" ]"; then
    log_message "Files copied to temporary directory on remote server."
else
    log_message "Temporary directory is empty after rsync on remote server."
    exit 1
fi


# Create a compressed archive of the backup on remote server
log_message "Creating tar archive on remote server..."
ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST "tar -czf $TMP_DIR/backup_${DATE}.tar.gz -C $TMP_DIR/tmp ." >> $LOG_FILE 2>&1
check_result "Creating tar archive on remote server"


# Transfer the archive to local PC
log_message "Transferring backup archive to local PC..."
scp -P $SSH_PORT $REMOTE_USER@$REMOTE_HOST:$TMP_DIR/backup_${DATE}.tar.gz $LOCAL_FILE >> $LOG_FILE 2>&1
check_result "Transferring backup archive to local PC"

log_message "Backup size: $(stat -c '%s' $LOCAL_FILE | awk '{printf "%.2f MB\n", $1/1024/1024}')"

# Clean up temporary directory on remote server
ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST "rm -rf $TMP_DIR" >> /dev/null 2>&1
check_result "Cleaning up temporary directory on remote server"

log_message "Backup completed successfully for ${DATE}."


# Calculate the date 10 days ago
DATE_THRESHOLD=$(date -d "$DELETE_DAYS days ago" "+%s")

find "$BASE_LOCAL_DIR" -maxdepth 1 -type f -name "*.tar.gz" | while read -r file; do
    # Get the creation time of the file in seconds since the epoch
    creation_time=$(stat -c %W "$file")

    # Compare the creation time with the date threshold
    if (( creation_time < DATE_THRESHOLD )); then
        # Delete the file
        log_message "Deleting old backup: $(stat -c %n "$file")"
        rm -f "$file"
    fi
done