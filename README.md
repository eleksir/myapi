# MyAPI

## Что это такое

myapi - разнообразное api и пример его использования. Api написано на perl-е
для удобства и простоты разработки.

## Что оно умеет

### config.pm

Модуль конфигурации api.

```json
"api" : {
	"prefix" : "/api"
}
```

### ping.pm

Отвечает pong, нужно для проверки, что приложение в принципе живо

### easter_egg.pm

ditto, просто бесполезные функции, just for fun:

`quote` - цитата дня (использует системную fortune)

`chanserv` - обращение к несуществующему chanserv

`nickserv` - обращение у несуществующему nickserv

`me` - действие /me

### image_dl.pm

Модуль для скачивания картинок из интернетов. Чтобы слить картинку, надо 
позвать урл на котором болтается api, например 'http://localhost/api/image_dl',
и выставить заголовок url с урлом, который надо скачать.

```json
"image_dl" : {
	"fifo" : "data/image_dl.fifo",
	"dir" : "/download/imgsave"
}
```

### metagen.pm

Модуль для генерации метаданных в указанном репозитории slackware. Чтобы
перегенерировать метаданные, надо позвать урл, на котором болтается api,
например, 'http://localhost/api/metagen' и выставить заголовок repo в название
репозитория, который надо освежить.

```json
"metagen" : {
	"myrepo" : "/var/www/repos/myrepo/14.2/x86_64"
}
```

### buildinfo.pm

Модуль для предоставления информации по собираемому slackware-пакету в
ci-конвеере, для сборки этого самого пакета.

Например, так:

```sh
curl -H 'repo: репозиторий/имя_пакета' localhost/api/buildinfo
```

```json
"buildinfo" : {
	"myrepo" : "/var/lib/ci/config-slackbuild-myrepo.json
}
```

### upload.pm

Модуль для загрузки файлов в каталог, конфигурируется в myapi.json в классе
upload. Загрузка происходит через метод PUT в процессе используется каcтомный
заголовок auth.

"upload" : {
	"dir" : {
		"myrepo" : "/var/www/repos/myrepo/14.2/x86_64"
	},
	"auth": "secret"
}

### paste.pm

будет модуль для пасты и для сокращения ссылок

### utils.pm

модуль с простыми утилитами
ip - возвращает ip, с которого пришёл клиент
getaddrbyname - возвращает список ipv4 адресов по имени хоста
getnamebyaddr - возвращает имя хоста по ipv4 адресу
punycoder - кодирует в punycode
punydecoder - превращает punycode-строку в utf-8 строку
mytime - возвращает время

### ircbot.pm

модуль с простым ботом

### jabberbot.pm

модуль с простым jabber-ботом

### telegrambot.pm

Модуль с простым telegram-ботом. Бот с бредогенератором, фактически, это единственная его фича. С ним можно пообщаться в привате, его можно пригласить в чат, он будет собирать фразы из чата и если к нему обратиться по имени или по @нику, он попытается что-то сгенерировать в ответ.

```json
"telegrambot" : {
	"name" : "BOTNAME",
	"tname" : "@botname_bot",
	"csign" : "!",
	"token" : "token for bot from botfather",
	"braindir": "data/telegrambot-brains"
}
```

### joyproxy.pm

Модуль-прокся для генерации ссылок с видосиками с joy.reactor.cc. Работает
через get-параметры, для простоты работы есть 2 урла.

* Проксирующий:

  `http://localhost/api/joyproxy/...`

* Генерирующий, который генерит из ссылок на видосик, скопированных с реактора, сыылки на проксю:

  `http://localhost/api/joyurl`

## Зачем это?

ХЗ, если есть что-то интересное в наборе модулей, то можно это использовать

## Подготовка к запуску

### Сервер приложений

Для запуска api используется uwsgi. Возможен вариант запуска и через другие
сервера psgi, например, через plack или nginx unit, но это не тестировалось.

### Перловые модули

Помимо самого perl-а, для запуска нужны cpanm и lib::local, чтобы иметь
возможность засосать всё остальное в каталог vendor_perl.

### Подготовительные операции

Перед первым запуском и после каждого обновления необходимо запускать
bootstrap.sh, который и засасывает зависимости из интернетов и складывает
их все в каталог vendor_perl.

Зависимостей сравнительно много и среди них есть "пидорские", но вполне себе
стабильные модули, подтягиваемые по графу зависимостей не напрямую :)

### Рабочий каталог и данные

API работает непосредственно в том каталоге, где лежит myapi.psgi.

Конфигурация самого api и модулей хранится в каталоге data, там же хранится
состояние модулей, которые подразумевают хранение таковых данных.

### Конфигурация uWSGI

TBD

### Конфигурация nginx Unit

## Запуск

TBD

## Останов

TBD
