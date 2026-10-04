# CI/CD 1С: GitSync (Vanessa-Usher) + Jenkins-Lib

Репозиторий сборки для домашнего задания OTUS «CI-CD 1С с использованием JenkinsLib».
Сделан на основе примера [Kyrales/otus_JenkinsExample](https://github.com/Kyrales/otus_JenkinsExample) (ветка `storage_1c`).

Что делает сборка:

| Пайплайн | Файл | Библиотека | Что делает |
|---|---|---|---|
| `gitsync` (обычный Pipeline) | `Jenkinsfile_gitsync` | `usher2` — [Kyrales/vanessa-usher_mod](https://github.com/Kyrales/vanessa-usher_mod), ветка `my_dev` | Выгружает новые версии хранилища 1С в `src/cf`, делает коммит на каждую версию и пушит в GitHub |
| `ci` (Multibranch Pipeline) | `Jenkinsfile_lib` | `jenkins-lib` — [Kyrales/jenkins-lib](https://github.com/Kyrales/jenkins-lib), ветка `otus` | Поднимает тестовую базу из хранилища, подключает расширение YAXUnit, выполняет синтаксический контроль и модульные тесты, публикует отчёт Allure |

## Отличия от исходного примера

* `jobConfiguration.json`: по умолчанию включены только `initSteps`, `syntaxCheck`, `yaxunit` — этого достаточно для зелёного прогона без SonarQube и почты. BDD, SonarQube и e-mail включаются ключами `setup.ps1` (или вручную в `stages`).
* `tools/gitsync_conf.json`: синхронизируется только основное хранилище конфигурации (`src/cf`). Расширение YAXUnit с тестами хранится прямо в git (`src/cfe/yaxunit`) и в ci грузится из исходников — отдельное хранилище расширения не нужно.
* `src/cf/VERSION` = `0`: при первом запуске gitsync выгрузит **ваше** хранилище с первой версии, и `src/cf` будет точно соответствовать ему.
* `tools/vrunner.json`: убраны ключи подключения отладчика (`/debug -http -attach ...`) — они нужны только для замеров покрытия (`coverage`), без сервера отладки они замедляют и иногда роняют запуск.
* `setup.ps1` — подставляет вашу версию платформы, пути к базам и хранилищу, адрес репозитория во все файлы настроек.

---

## Пошаговая инструкция

Условные значения ниже (замените на свои):

| Что | Пример |
|---|---|
| Версия платформы | `8.3.25.1546` |
| Эталонная база для тестов | `C:\1C\build\Demo83_otus` |
| Пустая база для gitsync | `C:\1C\build\Demo83_otus_clear` |
| Хранилище конфигурации | `tcp://localhost/StorageOtus` или файловое `C:\1C\Storage\StorageOtus` |
| Служебный пользователь хранилища | `DeployGit` (без пароля) |
| Пользователь-разработчик хранилища | `Разработчик` |
| Репозиторий | `https://github.com/<login>/otus_1c_ci.git`, ветка `storage_1c` |

### 1. Подготовка баз 1С

1. Разверните базу «Демонстрационное приложение» (или свою конфигурацию) — это будет **эталонная база** `C:\1C\build\Demo83_otus`.
2. В эталонной базе у пользователя `Администратор`:
   * включите «Аутентификация операционной системы» и укажите пользователя Windows, под которым работает агент Jenkins (например `\\SRV-CI-1C\Admin`);
   * снимите флажок «Защита от опасных действий» (иначе тесты зависнут на диалоге).
3. Создайте рядом **пустую базу** без конфигурации `C:\1C\build\Demo83_otus_clear` — через неё работает gitsync.
4. Создайте **хранилище конфигурации** из эталонной базы (Конфигуратор → Конфигурация → Хранилище → Поместить конфигурацию в хранилище). Для домашнего задания подойдёт и файловое хранилище, сервер хранилища не обязателен.
5. В хранилище добавьте пользователей: `DeployGit` (права только на чтение, пароль пустой) и `Разработчик` (полные права) — от его имени вы будете делать доработку.
6. **Отключите эталонную и пустую базы от хранилища** (ci и gitsync должны работать с ними независимо).
7. Проверьте, что обработка `C:\tools\vanessa-automation-single.epf` открывается в тестовом режиме (нужно только если включаете BDD).

### 2. Подготовка сервера-агента (Windows, где стоит платформа 1С)

1. Установите OneScript (`OneScript-1.9.x-x64.exe`), затем в консоли от имени администратора:
   ```bat
   opm install gitsync
   opm install vanessa-runner
   gitsync plugins init
   ```
   `gitsync plugins init` обязательно выполнить **на той машине, где работает агент**.
2. Установите Git for Windows. Под пользователем, от имени которого запущен агент Jenkins, **один раз вручную** склонируйте свой репозиторий и сделайте `git push` — Git Credential Manager сохранит токен, и gitsync сможет пушить без запроса пароля. (Токен никогда не пишите в файлы репозитория — он публичный.)
3. Кодировка: в bat-файле запуска агента первой строкой `chcp 65001`, а в `jenkins.xml` контроллера в `<arguments>` добавьте `-Dfile.encoding=UTF-8`.
4. Для Allure без интернета: распакуйте allure-commandline (например `C:\tools\allure-2.32.0`).

### 3. Плагины Jenkins

Управление Jenkins → Plugins → Available. Верхнеуровневые плагины (зависимости подтянутся сами):

`Pipeline: Groovy Libraries`, `Git`, `HTTP Request`, `Pipeline Utility Steps`, `JUnit`, `xUnit`, `DTKit 2 API`, `Pipeline: Multibranch`, `Allure`, `SonarQube Scanner`, `GitLab Branch Source`, `Pipeline: Stage View`, `Pipeline`, `Timestamper`, `Blue Ocean` (тянет `GitHub Branch Source` и `HTML Publisher`), `File Operations`, `Email Extension` (если включаете почту).

`Lockable Resources` нужен только для замеров покрытия Coverage41C — в этой сборке покрытие выключено, можно не ставить.
Полный список с зависимостями — `doc/ДопПлагиныКСборке2025.txt`. Также на агент установите `OneScript-1.9.3-x64.exe`.

После установки: Настроить Jenkins → Tools → «Установки Allure Commandline» → Имя `allure`, каталог `C:\tools\allure-2.32.0`, флажок «Установить автоматически» снять (или оставить, если у агента есть интернет).

### 4. Подключение библиотек (скриншот для критерия 2)

Настроить Jenkins → System → **Global Trusted Pipeline Libraries** → Add — две библиотеки:

| Поле | Библиотека 1 | Библиотека 2 |
|---|---|---|
| Name | `jenkins-lib` | `usher2` |
| Default version | `otus` | `my_dev` |
| Load implicitly | ☐ | ☐ |
| Allow default version to be overridden | ☑ | ☑ |
| Include @Library changes in job recent changes | ☑ | ☑ |
| Retrieval method | Modern SCM → Git | Modern SCM → Git |
| Project Repository | `https://github.com/Kyrales/jenkins-lib.git` | `https://github.com/Kyrales/vanessa-usher_mod.git` |
| Library Path (optional) | `./` | `./` |

Имена `jenkins-lib` и `usher2` должны совпадать с `@Library(...)` в `Jenkinsfile_lib` и `Jenkinsfile_gitsync`. После сохранения под полем Default version должно появиться «Currently maps to revision: …» — это значит, что Jenkins видит библиотеку. **Сделайте скриншот этого раздела с обеими библиотеками.**

> В старых версиях Jenkins (плагин Pipeline: Groovy Libraries до 2.x) этот раздел называется **Global Pipeline Libraries** — это тот же раздел, настройки те же. Если в вашем Jenkins есть оба раздела — используйте **Global Trusted Pipeline Libraries**: библиотеки из него выполняются без песочницы, что нужно Jenkins-Lib и Usher.

### 5. Агент

Все стадии, работающие с 1С, выполняются на агенте, где установлена платформа, лежат эталонная и пустая базы и доступно хранилище. Возможны два варианта.

**Вариант А — одна ВМ, Jenkins и 1С на одной машине (как на ВМ курса).** Используется встроенный узел контроллера:
1. Управление Jenkins → Nodes → **Built-In Node** → Настроить.
2. Количество процессов-исполнителей: `5`.
3. Метки: `agent gitsync 8.3.25.1546`.
4. Использование: «Use this node as much as possible».
5. Служба Windows «Jenkins» по умолчанию работает под `Local System` — у этой учётной записи нет вашего токена GitHub и она не совпадает с пользователем аутентификации ОС в эталонной базе. Откройте `services.msc` → Jenkins → Свойства → вкладка «Вход в систему» → «С учётной записью» → укажите пользователя Windows (например `SRV-CI-1C\Admin`) и перезапустите службу.

**Вариант Б — отдельный агент на сервере 1С.**
1. На сервере 1С установите Java 17 или 21 (та же мажорная версия, что у контроллера).
2. Управление Jenkins → Nodes → **New Node** → имя `1C` → Permanent Agent:
   * Количество процессов-исполнителей: `5`;
   * Корень удалённой ФС: `C:\jenkins-agent` (короткий путь без пробелов и кириллицы);
   * Метки: `agent gitsync 8.3.25.1546`;
   * Использование: «Use this node as much as possible»;
   * Способ запуска: **Launch agent by connecting it to the controller** (inbound);
   * Свойства узла → Environment variables — при необходимости `PATH`, `EDT_LOCATION` и т. п.
3. Сохраните и откройте страницу узла — Jenkins покажет команду подключения. Создайте `C:\jenkins-agent\start-agent.bat`:
   ```bat
   chcp 65001
   cd /d C:\jenkins-agent
   curl.exe -sO http://<jenkins-host>:8080/jnlpJars/agent.jar
   java -Dfile.encoding=UTF-8 -jar agent.jar -url http://<jenkins-host>:8080/ -secret <секрет со страницы узла> -name "1C" -workDir "C:\jenkins-agent"
   ```
4. Запускайте bat **от имени того же пользователя Windows**, что указан в аутентификации ОС эталонной базы и под которым сохранён токен GitHub. Для автозапуска — Планировщик заданий → «При входе в систему» / «При запуске» от этого пользователя (или обёртка WinSW как служба с этой учётной записью).
5. На странице узла должно появиться «Agent is connected», а в «Метки» — `agent`, `gitsync`, версия платформы.

Метка с версией должна **точно** совпадать с `v8version` в `jobConfiguration.json`. Добавьте метку `sonar`, если включаете SonarQube.

### 6. Учётные данные (Credentials)

Настроить Jenkins → Credentials → System → Global:

| ID | Тип | Значение |
|---|---|---|
| `Path_Otus_Storage_ID` | Secret text | путь к хранилищу, например `tcp://localhost/StorageOtus` |
| `DeployGit_id` | Username with password | `DeployGit` / пустой пароль |
| `github_token` | Username with password | ваш логин GitHub / Personal access token (scope `repo`) |

Первые два ID уже прописаны в `jobConfiguration.json` → `secrets` — ci из них загружает конфигурацию из хранилища в тестовую базу.

### 7. Публичный репозиторий

1. На GitHub создайте **публичный** пустой репозиторий, например `otus_1c_ci`.
2. Распакуйте этот проект, настройте под себя и запушьте в ветку `storage_1c`:
   ```powershell
   cd C:\1C\Projects\otus_1c_ci
   powershell -ExecutionPolicy Bypass -File .\setup.ps1 `
     -V8Version 8.3.25.1546 `
     -GitHubUrl https://github.com/<login>/otus_1c_ci.git `
     -StoragePath "tcp://localhost/StorageOtus" `
     -TemplateDb "C:/1C/build/Demo83_otus" `
     -ClearDb "C:/1C/build/Demo83_otus_clear"
   git init -b storage_1c
   git add .
   git commit -m "Начальная настройка сборки"
   git remote add origin https://github.com/<login>/otus_1c_ci.git
   git push -u origin storage_1c
   ```
3. В `src/cf/AUTHORS` перечислите **всех** пользователей хранилища, чьи версии будет выгружать gitsync (плагин `check-authors` падает на неизвестном авторе):
   ```
   Администратор=Администратор <admin@example.com>
   Разработчик=Иван Иванов <ivanov@example.com>
   DeployGit=DeployGit <deploygit@example.com>
   ```
4. На GitHub в Settings → General сделайте `storage_1c` веткой по умолчанию.

> Если используете **свою** конфигурацию вместо демо: удалите тестовые модули `ОМ_ПервыйТест`, `ОМ_API_ОписанияТоваров`, `Док_РасходТовара` из `src/cfe/yaxunit` (они проверяют объекты демо-базы) или замените своими тестами, а каталог `features` — своими сценариями.

### 8. Пайплайн gitsync

Создать Item → имя `gitsync` → **Pipeline**:
* Build Triggers → Build periodically: `H/15 * * * *` (или запуск вручную);
* Pipeline → Definition: **Pipeline script from SCM** → SCM: Git;
* Repository URL: `https://github.com/<login>/otus_1c_ci.git`, Credentials: `github_token`;
* Branch Specifier: `*/storage_1c`;
* Additional Behaviours: **Check out to specific local branch** = `storage_1c` (без этого gitsync не сможет закоммитить в «оторванную» HEAD), **Clean before checkout**, **Clean after checkout**;
* Script Path: `Jenkinsfile_gitsync`, Lightweight checkout ☑.

Запустите вручную. Первый прогон выгрузит все версии хранилища в `src/cf` и запушит коммиты — проверьте историю ветки на GitHub.

### 9. Мультипайплайн ci

Создать Item → имя `ci` → **Multibranch Pipeline**:
* Branch Sources → Add source → **GitHub**, Credentials: `github_token`, Repository HTTPS URL: `https://github.com/<login>/otus_1c_ci.git`;
* Behaviours: добавьте **Clean after checkout**;
* Build Configuration → Mode: by Jenkinsfile, Script Path: `Jenkinsfile_lib`;
* Scan Multibranch Pipeline Triggers → Periodically if not otherwise run → **1 minute** (тогда ci сам запускается после пуша от gitsync).

> Имя задания: в тексте ДЗ оно называется «мультипайплайн ci», в PDF-документации курса — `ci_otus`. Имя ни на что не влияет (библиотека его не использует), выберите любое; здесь — `ci`, как в формулировке задания.

После сохранения Jenkins просканирует репозиторий, найдёт ветку `storage_1c` и запустит сборку. Ожидаемые стадии: pre-stage → Подготовка 1С базы (создание ИБ, загрузка конфигурации из хранилища, загрузка расширений, инициализация, архивация) → Синтаксический контроль и YAXUnit тесты (параллельно) → публикация Allure.

### 10. Моделирование доработки и полный прогон

1. Откройте в Конфигураторе рабочую базу, подключённую к хранилищу, под пользователем хранилища `Разработчик`.
2. Захватите объект, внесите небольшую доработку — например, в модуль документа `РасходТовара` добавьте комментарий или новую процедуру; или добавьте новый реквизит справочнику.
3. Поместите изменения в хранилище с комментарием, например `OTUS ДЗ: доработка РасходТовара`.
4. Запустите `gitsync` (или дождитесь расписания) → на GitHub появится коммит от автора `Разработчик` с комментарием из хранилища.
5. Мультипайплайн `ci` увидит новый коммит и запустит сборку ветки `storage_1c` (или нажмите «Сканировать репозиторий сейчас»).
6. Дождитесь зелёного статуса обоих пайплайнов.

### 11. Что приложить к сдаче

Шаблон отчёта — [`HOMEWORK.md`](HOMEWORK.md). Нужны:
1. Ссылка на этот публичный репозиторий.
2. Скриншот Настроить Jenkins → System → **Global Trusted Pipeline Libraries** с `jenkins-lib` и `usher2`.
3. Для `gitsync` и `ci`: скриншот успешного прогона (Stage View / Blue Ocean) и лог — Console Output → **View as plain text** → сохранить страницу как `.txt`.

Положите скриншоты в `doc/screens/`, логи в `doc/logs/`, заполните `HOMEWORK.md` и запушьте в `storage_1c` — тогда проверяющему достаточно одной ссылки на репозиторий. (gitsync перед выгрузкой делает `pull`, поэтому ваши коммиты в эту ветку ему не мешают.)

### 12. Полный набор проверок (по желанию)

Критерии приёмки требуют только успешного завершения пайплайнов, поэтому по умолчанию включён минимальный набор: подготовка ИБ, синтаксический контроль, YAXUnit. Чтобы прогон был как в примере курса, включите остальные стадии — ключами `setup.ps1` (`-EnableBdd -EnableSonar -EnableEmail`) или вручную в `jobConfiguration.json` → `stages`:

| Стадия | Что нужно заранее |
|---|---|
| `bdd` | `C:\tools\vanessa-automation-single.epf` (путь в `tools/vrunner.json`), каталог `features` со сценариями под вашу базу |
| `sonarqube` | SonarQube на `localhost:9000` с плагином BSL, токен в Credentials, SonarQube servers в настройках Jenkins, `sonar-scanner` в `PATH`, метка `sonar` у агента |
| `email` | плагин Email Extension, SMTP в Настроить Jenkins → System → Extended E-mail Notification |

Если после включения стадия падает, а сдавать нужно — выключите её обратно: на приёмку это не влияет.

### 13. Соответствие критериям приёмки

| Критерий | Шаги инструкции | Что прикладываете |
|---|---|---|
| 1. Публичный репозиторий сборки в облачном Git | 7 | ссылка на репозиторий |
| 2. Jenkins настроен, подключены Vanessa-Usher и JenkinsLib | 3, 4, 5, 6 | скриншот Global Trusted Pipeline Libraries |
| 3. Пайплайны `gitsync` и мультипайплайн `ci` выполнены успешно | 1, 2, 8, 9, 10 | скриншоты результатов и логи «View as plain text» обоих |

---

## Частые ошибки

| Симптом | Причина / решение |
|---|---|
| `There are no nodes with the label '8.3.25.1546'` | метка агента не совпадает с `v8version` в `jobConfiguration.json` |
| `No such DSL method 'pipeline1C'` / `repoSyncPipeline` | библиотека не подключена или имя отличается от `@Library(...)` |
| gitsync: `Автор ... не найден` | пользователя хранилища нет в `src/cf/AUTHORS` |
| gitsync: `Authentication failed` при push | под пользователем агента не сохранён токен GitHub (см. шаг 2.2) |
| gitsync: `You are not currently on a branch` | не добавлено «Check out to specific local branch» в задании |
| gitsync ничего не выгружает | в `src/cf/VERSION` номер ≥ последней версии хранилища — поставьте `0` |
| gitsync: плагины не найдены | не выполнен `gitsync plugins init` на агенте |
| ci: ошибка загрузки из хранилища | проверьте credentials `Path_Otus_Storage_ID` и `DeployGit_id`, доступ `DeployGit` к хранилищу |
| ci: `Could not find allure installation` | не настроен инструмент Allure Commandline с именем `allure` |
| Тесты висят | в эталонной базе не снята «Защита от опасных действий» или не включена аутентификация ОС |
| Кракозябры в логе | `chcp 65001` в запуске агента и `-Dfile.encoding=UTF-8` у контроллера |
| Ошибка конфигурации «режим совместимости» | версия платформы ниже, чем режим совместимости демо-конфигурации (8.3.25) |

## Ссылки

* Пример сборки OTUS: https://github.com/Kyrales/otus_JenkinsExample
* Jenkins-Lib (оригинал): https://github.com/firstBitMarksistskaya/jenkins-lib
* Vanessa-Usher (оригинал): https://github.com/silverbulleters/vanessa-usher
* Описание Jenkins-Lib: https://infostart.ru/1c/articles/1681427/
* Документация по настройке: `doc/Jenkins-lib_docs_otus.pdf`
