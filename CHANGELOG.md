## [2.0.4](https://gitlab.com/1O/vaultwarden-backup/compare/v2.0.3...v2.0.4) (2023-07-04)


### Bug Fixes

* Do not use live database file in backup ([229b586](https://gitlab.com/1O/vaultwarden-backup/commit/229b5869ef14afc42df89ccd22c96fe75846a69d)), closes [#31](https://gitlab.com/1O/vaultwarden-backup/issues/31)
* fixed broken gpg backup and wrong db ([3df0614](https://gitlab.com/1O/vaultwarden-backup/commit/3df0614d66c6bed1c063c04af6b4a39a5f398cc1)), closes [#31](https://gitlab.com/1O/vaultwarden-backup/issues/31) [#33](https://gitlab.com/1O/vaultwarden-backup/issues/33)
* fixed cronjob ([9fc2ee6](https://gitlab.com/1O/vaultwarden-backup/commit/9fc2ee6f1e6cb845ccf5b3897bc562b4987d335e)), closes [#32](https://gitlab.com/1O/vaultwarden-backup/issues/32)
* re-initiate cron on change ([3e1b71c](https://gitlab.com/1O/vaultwarden-backup/commit/3e1b71ccbf436216deb3b075910d933680d67370))

## [2.0.3](https://gitlab.com/1O/vaultwarden-backup/compare/v2.0.2...v2.0.3) (2023-07-01)


### Bug Fixes

* fixed cronjob ([a2aaccb](https://gitlab.com/1O/vaultwarden-backup/commit/a2aaccb78664adbb6ac2df9481c58f0b74b9ee5c)), closes [#32](https://gitlab.com/1O/vaultwarden-backup/issues/32)

## [2.0.2](https://gitlab.com/1O/vaultwarden-backup/compare/v2.0.1...v2.0.2) (2023-07-01)


### Bug Fixes

* re-initiate cron on change ([eb37e56](https://gitlab.com/1O/vaultwarden-backup/commit/eb37e563505b11f25d4f5289f8f8a4093a5a1cf9))

## [2.0.1](https://gitlab.com/1O/vaultwarden-backup/compare/v2.0.0...v2.0.1) (2023-06-02)


### Bug Fixes

* version number in latest builds was incorrect ([5c55d02](https://gitlab.com/1O/vaultwarden-backup/commit/5c55d0292fee0a569d43b96b9500e5a8437ea483)), closes [#30](https://gitlab.com/1O/vaultwarden-backup/issues/30)

# [2.0.0](https://gitlab.com/1O/vaultwarden-backup/compare/v1.1.0...v2.0.0) (2023-04-07)


* Merge branch 'dev' into 'main' ([7a98065](https://gitlab.com/1O/vaultwarden-backup/commit/7a9806595c81aacf4d4c838601fca196317155c5))


### Features

* Added BACKUP_ON_STARTUP ([4952ce3](https://gitlab.com/1O/vaultwarden-backup/commit/4952ce3c963d6f287c76decadc6c93133821c34d))
* Password protection and switch to xz ([fb4b207](https://gitlab.com/1O/vaultwarden-backup/commit/fb4b207f23f8b311ebe3230eee352069ebe75de2)), closes [#28](https://gitlab.com/1O/vaultwarden-backup/issues/28)


### BREAKING CHANGES

* Include database backup in tar

See merge request 1O/vaultwarden-backup!13

# [1.1.0](https://gitlab.com/1O/vaultwarden-backup/compare/v1.0.4...v1.1.0) (2023-01-02)


### Bug Fixes

* Added error counter to critical errors ([0f53b1d](https://gitlab.com/1O/vaultwarden-backup/commit/0f53b1d31b841d9d932fcc860399c211ff44684e))
* init health file ([a327c8e](https://gitlab.com/1O/vaultwarden-backup/commit/a327c8e5506a39b5f688d449eb3ddc987c6822df))


### Features

* added container health check ([c3364dd](https://gitlab.com/1O/vaultwarden-backup/commit/c3364dda22a0ab7117a2bc77d519435668d45880))

## [1.0.4](https://gitlab.com/1O/vaultwarden-backup/compare/v1.0.3...v1.0.4) (2022-04-19)


### Bug Fixes

* Make set-env.sh executable ([6f403c8](https://gitlab.com/1O/vaultwarden-backup/commit/6f403c862e2cadf16059a28587d1c75aa08b761b)), closes [#24](https://gitlab.com/1O/vaultwarden-backup/issues/24)

## [1.0.3](https://gitlab.com/1O/vaultwarden-backup/compare/v1.0.2...v1.0.3) (2022-02-04)


### Bug Fixes

* deprecation check for $LOGFILE ([11d6cf9](https://gitlab.com/1O/vaultwarden-backup/commit/11d6cf93b0e5b2ea1de84932b84aacd83e40f0c4))
* Moved deprecation checks to set-env script ([81f6190](https://gitlab.com/1O/vaultwarden-backup/commit/81f619001e1028ea6aad372237c22bb43bded045)), closes [#23](https://gitlab.com/1O/vaultwarden-backup/issues/23)
* Set LOG_LEVEL first ([d5ee0b1](https://gitlab.com/1O/vaultwarden-backup/commit/d5ee0b1c60ba5d3c8aab57a6abffbf70f968a72d)), closes [#23](https://gitlab.com/1O/vaultwarden-backup/issues/23)

## [1.0.2](https://gitlab.com/1O/vaultwarden-backup/compare/v1.0.1...v1.0.2) (2022-01-31)


### Bug Fixes

* always create logfiles as $UID:$GID ([0034bfb](https://gitlab.com/1O/vaultwarden-backup/commit/0034bfb70107daf3a70039320ac18a57a85d55f6)), closes [#21](https://gitlab.com/1O/vaultwarden-backup/issues/21)
* Fixed permissions issues with log files ([fec55cc](https://gitlab.com/1O/vaultwarden-backup/commit/fec55cce32790cc23909922f1b1f6ef88dd87b9c)), closes [#21](https://gitlab.com/1O/vaultwarden-backup/issues/21)

## [1.0.1](https://gitlab.com/1O/vaultwarden-backup/compare/v1.0.0...v1.0.1) (2022-01-29)


### Bug Fixes

* Fixed DELETE_AFTER ([b945105](https://gitlab.com/1O/vaultwarden-backup/commit/b945105fd620a07b6a7f513cad9c250e52afab08))
* Fixed permission issues ([6108810](https://gitlab.com/1O/vaultwarden-backup/commit/610881056f6ed89bf6cf30b645121f9edd5ddfb5)), closes [#19](https://gitlab.com/1O/vaultwarden-backup/issues/19) [#20](https://gitlab.com/1O/vaultwarden-backup/issues/20) [#21](https://gitlab.com/1O/vaultwarden-backup/issues/21)
* Fixed su-exec issues in manual mode ([62f9db9](https://gitlab.com/1O/vaultwarden-backup/commit/62f9db996236e649ce07144d056dfae2e2a59dbf)), closes [#20](https://gitlab.com/1O/vaultwarden-backup/issues/20)
* loop when run with UID zero ([724dd65](https://gitlab.com/1O/vaultwarden-backup/commit/724dd657ccb41caec2b0a298c19a28be3caa21dd))

# [1.0.0](https://gitlab.com/1O/vaultwarden-backup/compare/v0.0.8...v1.0.0) (2022-01-26)


### Features

* renamed to vaultwarden-backup ([4ce504e](https://gitlab.com/1O/vaultwarden-backup/commit/4ce504e6debb6cd3993a9f36135b6db539f01dd5)), closes [#18](https://gitlab.com/1O/vaultwarden-backup/issues/18)


### BREAKING CHANGES

* Changed environment variables
