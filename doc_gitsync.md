## Ручной запуск gitsync (без Jenkins, для отладки)

Все версии хранилища по настройкам из `tools/gitsync_conf.json`:

```bat
gitsync --v8version 8.3.25.1546 --ibconnection /FC:/1C/build/Demo83_otus_clear all ./tools/gitsync_conf.json
```

Одно хранилище:

```bat
gitsync sync -u DeployGit tcp://localhost/StorageOtus C:\1C\Projects\otus_1c_ci\src\cf\
```

Перед первым запуском на машине: `gitsync plugins init`.
