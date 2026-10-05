# Отчёт по ДЗ «CI-CD 1С с использованием JenkinsLib»

## 1. Публичный репозиторий сборки

https://github.com/retry-warder/otus_1c_jenkins_ci (ветка `storage_1c`)

Сделан на основе примера OTUS [Kyrales/otus_JenkinsExample](https://github.com/Kyrales/otus_JenkinsExample).

## 2. Библиотеки Jenkins — Global Trusted Pipeline Libraries

Подключены:
- `jenkins-lib` — https://github.com/Kyrales/jenkins-lib.git, ветка `otus` (мультипайплайн `ci`, `Jenkinsfile_lib`);
- `usher2` — https://github.com/Kyrales/vanessa-usher_mod.git, ветка `my_dev` (пайплайн `gitsync`, `Jenkinsfile_gitsync`).

![Global Trusted Pipeline Libraries](doc/screens/01_libraries.png)

## 3. Доработка в хранилище 1С

| Параметр | Значение |
|---|---|
| Хранилище | файловое, `D:/Otus_1c_projects/Base1c/StorageOtus` |
| Версия хранилища | **2** от 05.10.2026 14:11 |
| Пользователь | `1CDeveloper` |
| Метка / комментарий | `#TASK_1` / `#TASK_1 #HW_OTUS_CI` |
| Изменённые объекты | `Документ.Заказ`, `Документ.Заказ.Форма.ФормаДокумента` |

Коммит, созданный gitsync: https://github.com/retry-warder/otus_1c_jenkins_ci/commit/cae1a1b
(автор `1CDeveloper`, сообщение `#TASK_1 #HW_OTUS_CI`, `src/cf/VERSION` = 2).

## 4. Пайплайн gitsync

Pipeline script from SCM → `Jenkinsfile_gitsync`, ветка `storage_1c`, библиотека `usher2`.
Синхронизировал версию 2 хранилища (`Номер синхронизированной версии: 1` → `Номер последней версии в хранилище: 2`) и отправил коммит в GitHub. Результат: `Finished: SUCCESS`.

![gitsync](doc/screens/02_gitsync.png)

Лог: [doc/logs/gitsync_console.txt](doc/logs/gitsync_console.txt)

## 5. Мультипайплайн ci

Multibranch Pipeline → `Jenkinsfile_lib`, библиотека `jenkins-lib`, сканирование репозитория раз в минуту.
Сборка запущена автоматически (Branch indexing) по коммиту `cae1a1b`:
- создание ИБ из эталонной базы и загрузка конфигурации из хранилища (`--storage-ver 2`, `Объект изменен: Документ.Заказ`);
- сборка и загрузка расширения YAXUnit;
- синтаксический контроль;
- модульные тесты YAXUnit;
- публикация отчёта Allure.

Результат: `Finished: SUCCESS`.

![ci](doc/screens/03_ci.png)

![Allure](doc/screens/04_allure.png)

Лог: [doc/logs/ci_console.txt](doc/logs/ci_console.txt)

## 6. Окружение

- Jenkins 2.580.1 LTS, Java 21 (Temurin), Windows;
- 1С:Предприятие 8.3.27.2130, демо-конфигурация «Демонстрационное приложение» 1.0.37.2;
- OneScript 1.9.3, gitsync 3.8.0, vanessa-runner 2.6.1;
- Allure 2.46.0.

## 7. Замечания по ходу настройки

- Тест `ОМ_API_ОписанияТоваров` удалён из расширения YAXUnit: он вызывает общий модуль `API_ОписанияТоваров`, которого нет в используемой версии демо-конфигурации (1.0.37.2). Остальные тесты (`Док_РасходТовара`, `ОМ_ПервыйТест`) выполняются.
- Для работы Jenkins-Lib дополнительно к списку курса понадобились плагины **Config File Provider** и **Blue Ocean**.
- Jenkins запускается в пользовательском сеансе Windows (не службой): тесты YAXUnit открывают клиент 1С, которому нужен интерактивный рабочий стол.
- Пути OneScript, плагинов gitsync и временных файлов вынесены в каталоги без кириллицы: библиотеки выполняют команды с `chcp 65001`.
