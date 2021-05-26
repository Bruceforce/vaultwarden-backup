Backs up vaultwarden files using cron daemon.
Can be set to be run automatically.

## Usage

#### Automatic Backups
Refer to the `docker-compose` section below. By default, backing up is automatic.

#### Manual Backups
Pass `manual` to `docker run` or `docker-compose` as a `command`.

## docker-compose
```
services:
  vaultwarden:
	# Vaultwarden configuration here.
  backup:
    image: jmqm/vaultwarden-backup
    container_name: vaultwarden_backup
    volumes:
      - "/vaultwarden_data_directory:/data:ro"
      - "/backup_directory:/backups"

      - "/etc/localtime:/etc/localtime:ro" # Container uses date from host.
    environment:
      - DELETE_AFTER=30 #optional
      - CRON_TIME=* */4 * * *
      - UID=1024
      - GID=100
```

## Environment Variables
#### ⭐Required, 👍 Recommended
| Variable       | Description                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| UID          ⭐| User ID to run the cron job as.                                                                                                       |
| GID          ⭐| Group ID to run the cron job as.                                                                                                      |
| CRON_TIME    👍| When to run. Info [here](https://www.ibm.com/docs/en/db2oc?topic=task-unix-cron-format) and generator [here](https://crontab.guru/)   |
| DELETE_AFTER 👍| Delete backups _X_ days old. (unsupported at the moment(                                                                              |

#### Optional
| Variable       | Description                                                                                  |
| -------------- | -------------------------------------------------------------------------------------------- |
| TZ ¹           | Timezone inside the container. Can mount `/etc/localtime` instead as well _(recommended)_.   |
| LOGFILE        | Log file path relative to inside the container.                                              |
| CRONFILE       | Cron file path relative to inside the container.                                             |

¹ See <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones> for more information

## Errors
#### Wrong permissions
`Error: unable to open database file` is most likely caused by permission errors.
Note that sqlite3 creates a lock file in the source directory while running the backup.
So source *AND* destination have to be +rw for the user. You can set the user and group ID
via the `UID` and `GID` environment variables like described above.

#### Date Time issues / Wrong timestamp
If you need timestamps in your local timezone you should mount `/etc/timezone:/etc/timezone:ro` and `/etc/localtime:/etc/localtime:ro`
like it's done in the [docker-compose.yml](docker-compose.yml). An other possible solution is to set the environment variable accordingly (like  `TZ=Europe/Berlin`) 
(see <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones> for more information).
