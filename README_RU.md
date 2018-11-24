## Подключение серверу

Подключение к серверу осуществляется через дуплексный протокол **bullet**, пример подключения для React Native

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L17

Здесь функция **bullet** представляет из себя небольшую обёртку над вебсокетами либо XHR (который по сути эмулирует те же вебсокеты для конечного пользователя). Реализация протокола **bullet** на языке JavaScript (которая использовалась в предыдущем примере) находится здесь

https://github.com/timCF/bulletjs/blob/e8c87334bad8c496965487c33f60a8e822fd3535/bullet.js

После успешно установленного соединения библиотекой вызывается соответствующий callback

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L18

Также существуют callbacks которые вызываются при потере или закрытии соединения

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L22
https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L25

В реально работающих на данный момент проектах (админка https://github.com/timCF/studio_ui_admin, iframe расписания https://github.com/timCF/studio_ui_iframe) используется подключение именно через вебсокеты:

https://github.com/timCF/studio_ui_admin/blob/cd9611a1fe333fb0eda4307c9c88ee62e2b64000/app/bullet.iced#L80
https://github.com/timCF/studio_ui_iframe/blob/07aa758e31c512e55f5f40002ed6398d94eaef22/app/iced/bullet.iced#L14

Вариант подключения через XHR не тестировался, потому он менее эффективен и при этом вебсокеты поддерживаются всеми современными платформами, языками и браузерами. Подключение через XHR теоретически должно работать (для обратной совместимости со старыми браузерами), но эта функциональность не тестировалась.

## Отправка сообщений на сервер

После успешного подключения становится возможен обмен сообщениями с сервером. Для отправки какого-либо сообщения на сервер, необходимо вызвать функцию **send**

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L41

В функцию необходимо передать protobuf сообщение **Request**

https://github.com/timCF/studio_proto/blob/37816aa61712c2199fdefcd745c61fed62740cb9/studio.proto#L277-L285

закодированное в формат Base64. Пример кодирования перед вызовом функции **send**

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L40
https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/proto.ls#L32-L33

## Получение сообщений с сервера

При получении какого-либо сообщения с сервера, библиотекой вызывается соответствующий callback в который передаются полученные данные

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L33

Полученные с сервера данные всегда представляют собой protobuf сообщение **Response**

https://github.com/timCF/studio_proto/blob/37816aa61712c2199fdefcd745c61fed62740cb9/studio.proto#L287-L294

закодированное в формате Base64. Пример декодирования после получения сообщения:

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L34
https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/proto.ls#L27-L31

## Heartbeats

Предполагается что с течение всего жизненного цикла установленного соединения, клиент будет время от времени отправлять серверу сообщение **Request** с командой **CMD_ping** для того чтобы дать информацию о том что он всё ещё подключен. В библиотеке **bulletjs** за этот функционал отвечает соответствующий callback **onheartbeat**

https://github.com/timCF/studio_mobile/blob/1bba062ceb2c87ddf545f3e6b4cd530bc4e088dd/app/bullet.ls#L28-L32

Отправлять эти сообщения необходимо, иначе сервер посчитает что клиент отсоединился и закроет сокет со своей стороны.

... продолжение следует ...
