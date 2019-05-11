# bitwarden_rs Backup

Docker Containers for [bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs) Backup.

## Usage

The default tag `latest` should be used for a x86-64 system. If you try to run the container on a raspberry pi 3 you should use the tag `rpi3`. Also make sure that your **bitwarden_rs container is named `bitwarden`** otherwise you have to replace the container name in the `--volumes-from` section of the `docker run` call.

### Automatic Backups 
A cron daemon is running inside the container and the container keeps running in background.

Start backup container with default settings (automatic backup at 5 am)
```sh
docker run -d --restart=always --name bitwarden_backup --volumes-from=bitwarden bruceforce/bw_backup
```

Example for hourly backups
```sh
docker run -d --restart=always --name bitwarden_backup --volumes-from=bitwarden -e CRON_TIME="0 * * * *" bruceforce/bw_backup
```

### Manual Backups
You can use the crontab of your host to schedule the backup and the container will only be running during the backup process.

Example using the integrated Backup script. You can use Environment variables for database and backup location
```sh
docker run --rm --volumes-from=bitwarden bruceforce/bw_backup /backup.sh
```

If you want to run the sqlite commands manually you can use the following command
```sh
docker run --rm --volumes-from=bitwarden bruceforce/bw_backup sqlite3 $DB_FILE ".backup $BACKUP_FILE"
```

## Environment variables
| ENV | Description |
| ----- | ----- |
| DB_FILE | Path to the Bitwarden sqlite3 database *inside* the container |
| BACKUP_FILE | Path to the desired backup location *inside* the container |
| CRON_TIME | Cronjob format "Minute Hour Day_of_month Month_of_year Day_of_week Year" |
| TIMESTAMP | Set to `true` to append timestamp to the `BACKUP_FILE` |
| UID | User ID to run the cron job with |
| GID | Group ID to run the cron job with |
| LOGFILE | Path to the logfile *inside* the container |
| CRONFILE | Path to the cron file *inside* the container |
