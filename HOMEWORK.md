# Отчёт по ДЗ «CI-CD 1С с использованием JenkinsLib»

## 1. Публичный репозиторий сборки

`https://github.com/<login>/otus_1c_ci` (ветка `storage_1c`)

## 2. Библиотеки Jenkins — Global Trusted Pipeline Libraries

Подключены `jenkins-lib` (Kyrales/jenkins-lib, ветка `otus`) и `usher2` (Kyrales/vanessa-usher_mod, ветка `my_dev`).

![Global Trusted Pipeline Libraries](doc/screens/01_libraries.png)

## 3. Доработка в хранилище

Версия хранилища №__ от пользователя `Разработчик`, комментарий: «OTUS ДЗ: …».
Что изменено: …

Коммит в репозитории, созданный gitsync: `https://github.com/<login>/otus_1c_ci/commit/<hash>`

## 4. Пайплайн gitsync

![gitsync](doc/screens/02_gitsync.png)

Лог: [doc/logs/gitsync_console.txt](doc/logs/gitsync_console.txt)

## 5. Мультипайплайн ci

![ci](doc/screens/03_ci.png)

![Allure](doc/screens/04_allure.png)

Лог: [doc/logs/ci_console.txt](doc/logs/ci_console.txt)
