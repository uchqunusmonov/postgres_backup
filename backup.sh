#!/bin/bash

# ------ Configurations ------
CONTAINER_NAME="" # postgres container name
DB_NAME="" # your db name
DB_USER="" # db user
BACKUP_DIR="" # your backup dir path
LOG_DIR="" # your log dir path

# log and backup name
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
LOG_DATE=$(date +'%Y-%m-%d') 
LOG_FILE="${LOG_DIR}/backup_${LOG_DATE}.log"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# ------ create dirs ------
mkdir -p "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"

log "------------------------------------------"
log "The backup process has started."

# ------ Backup ------
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" "${DB_NAME}" > "${BACKUP_FILE}" 2>"${LOG_DIR}"/error/backup_error.log
if [ $? -eq 0 ]; then
    if [ -s "${BACKUP_FILE}" ]; then
        log "Backup completed successfully: ${BACKUP_FILE}"
    else
        log "The backup file is empty. An error may have occurred."
        cat "${LOG_DIR}"/error/backup_error.log | tee -a "${LOG_FILE}"
        exit 1
    fi
else
    log "An error occurred during backup!"
    cat "${LOG_DIR}"/error/backup_error.log | tee -a "${LOG_FILE}"
    exit 1
fi

# ------ Delete old backup files ------
log "The process of deleting old backups has begun."
log "The process of leaving the last 2 backups and deleting old files has begun."

cd "${BACKUP_DIR}" || { log "An error occurred while accessing the directory!"; exit 1; }

# Sort by file names in reverse order (newest -> oldest)
ls -1 "${DB_NAME}"_*.sql 2>/dev/null | sort -r | sed -n '3,$p' | xargs -r rm -f

log "Old, unnecessary backup files have been deleted."
