# bitwarden_rs Backup
---

Docker Containers for bitwarden_rs Backup.

## Usage
```sh
docker run --name bitwarden_backup --volumes-from=bitwarden registry.gitlab.com/1o/bitwarden_rs-backup
```

Example for hourly backups
```
docker run --name bitwarden_backup --volumes-from=bitwarden -e CRON_TIME="0 * * * *" registry.gitlab.com/1o/bitwarden_rs-backup
```

## Environment variables
| ENV | Description |
| ----- | ----- |
| DB_FILE | Path to the Bitwarden sqlite3 database |
| BACKUP_FILE | Path to the desired backup location |
| CRON_TIME | Cronjob format "Minute Hour Day_of_month Month_of_year Day_of_week Year" |

