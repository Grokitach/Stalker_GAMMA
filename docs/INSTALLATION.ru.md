[EN](./INSTALLATION.md) | RU

# Установка

## Windows

### ЧТО НУЖНО ИМЕТЬ ПЕРЕД УСТАНОВКОЙ

1. 70 GB свободного места.
2. Нужно использовать 7Zip, а не WINRAR. 7Zip: https://www.7-zip.org/download.html
3. Anomaly 1.5.1, не используйте уже установленную и модифицированную Anomaly: https://www.moddb.com/mods/stalker-anomaly/downloads/stalker-anomaly-151
 
   Можете использовать эту magnet-ссылку в любом торрент-загрузчике вместо прямой ссылки ModDB для более высокой скорости:
   ```
   magnet:?xt=urn:btih:c307c208636d1fd98ca4fe70ca0c692035659855&dn=Anomaly-1.5.1.7z&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://bt1.archive.org:6969/announce&tr=udp: //bt2.archive.org:6969/announce&tr=udp://tracker.torrent.eu.org:451/announce
   ```
4. Обновление 1.5.2 для Anomaly: https://www.moddb.com/mods/stalker-anomaly/downloads/stalker-anomaly-151-to-152

   Можете использовать эту magnet-ссылку в любом торрент-загрузчике вместо прямой ссылки ModDB для более высокой скорости:
   ```
   magnet:?xt=urn:btih:06580e9c871086d5b847a84940bd89b6d97c975f&dn=Anomaly-1.5.1-to-1.5.2-Update.7z&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://bt1.archive .org:6969/announce&tr=udp://bt2.archive.org:6969/announce&tr=udp://tracker.torrent.eu.org:451/announce
   ```
5. G.A.M.M.A. установщик GAMMA RC3.7z:
   - Зеркало 1: https://file141.gofile.io/download/8fc0e50c-77de-47d6-8612-e62e4e00713a/GAMMA%20RC3.7z
   - Зеркало 2: https://file141.gofile.io/download/796281d3-801b-4035-b57f-6fe163f9b7ec/GAMMA%20RC3.7z
   - Зеркало 3: https://file141.gofile.io/download/85787791-0aa6-4b46-8311-fe5112c195ef/GAMMA%20RC3.7z
   - Зеркало 4: https://mega.nz/file/TY1jzJbK#wV7ANyQFAUOXKGbGZXEuVhMyUjaX0NzRdcXueGyR2B8
   
   Также скачайте архив с модами downloads.7z отсюда: https://gofile.io/d/mpDnsO
6. Перед запуском настоятельно рекомендуется отключить антивирус или добавить исключения для папок Anomaly и GAMMA. BitDefender 100% будет крашить игру, потому что ему не нравится файловая система MO2.
7. Создайте 2 разные папки в корне ваших дисков (C:/, D:/): в одной будет GAMMA, а в другой Anomaly. Не создавайте эти папки в Downloads, Program Files, Documents, Desktop. Например, можно использовать: C:/GAMMA и C:/Anomaly. Не используйте символы или кириллицу в названиях ([- и тд).

### УСТАНОВКА

1. Распакуйте S.T.A.L.K.E.R. Anomaly 1.5.1 используя 7Zip (не winrar) в новой папке (C:\Anomaly).
2. - Переместите zip-файл 1.5.2 Anomaly Patch в папку с Anomaly C:\Anomaly (в ней ещё будут bin, gamedata...), щёлкните правой кнопкой мыши по архиву и распакуйте его сюда при помощи 7zip, с заменой файлов.
   - Рядом с папкой bin в вашей папке Anomaly появится файл changes151to152.txt, если распаковка прошла успешно.
3. Запустите Anomaly 1.5.2 один раз.
4. Извлеките GAMMA RC3.7z с помощью 7Zip в новую папку.
5. - Перейдите в папку C:\GAMMA RC3\ и распакуйте в неё архив downloads.7z. Появится папка C:\GAMMA RC3\downloads, в которой будет куча других архивов. Их распаковывать не надо.
   - Перейдите в папку C:\GAMMA RC3\Grok's Modpack Installer.
6. Обязательно щелкните правой кнопкой мыши по  G.A.M.M.A. Installer.exe, нажмите "Запуск от имени администратора" и затем "Allow Powershell scripts".
7. Нажмите "Launch MO2". Игнорируйте сообщение об ошибке. Нажмите Browse и выберите папку C:\Anomaly. Выйдите из МО2.
8. Нажмите «Download G.A.M.M.A. data» и дождитесь окончания загрузки.
9. Нажмите «Full G.A.M.M.A. installation».
   - Вы можете создать новый рабочий стол, нажав Windows + Tab, а затем нажать на «Создать рабочий стол» вверху, и переместить туда окно установщика и окно консоли. Так вы сможете нормально использовать свой ПК во время установки.
   - Если вам нужно закрыть установщик во время установки, то при следующем запуске он продолжит её с того мода, на котором был закрыт.
10. Когда процесс завершится, закройте программу установки, перейдите на рабочий стол и дважды щелкните по ярлыку G.A.M.M.A.. Должно появиться сообщение об ошибке, нажмите OK, у вас должно быть 358 модов в MO2. В противном случае при запуске игры у вас будет вылет.
 
    Нет ярлыка? Просто создайте ярлык C:\GAMMA RC3\modorganizer.exe и переместите его на рабочий стол.
11. STALKER GAMMA готова к запуску. Выберите «Anomaly (DX11)» в MO2 и нажмите «Run». DX9 не работает.

    Если у вас вылетает при запуске, проверьте, есть ли у вас 358 модов в MO2. Убедитесь, что вы правильно обновили игру до версии 1.5.2 (changes151to152.txt в папке Anomaly). Запустите установщик и нажмите Download GAMMA data (большая кнопка посередине), а затем Full GAMMA Installation. Если вы будете делать это более двух раз за час, moddb пометит вас как бота.

## Linux

https://github.com/DravenusRex/stalker-gamma-linux-guide

## Steam Deck

https://github.com/maxastyler/S.T.A.L.K.E.R.-Gamma-Steam-Deck-Install-Guide/blob/master/README.org

# Полезные советы

- НИКОГДА не удаляйте папку GAMMA RC3/downloads
- При создании новой игры не используйте "сохранения у костров", так как мод YACS делает то же самое, но ещё лучше (настраивается в меню MCM).
- "Война группировок" нестабильна.
- Если у вас появляются фризы, отключите ядро 0 для Anomaly.exe. Подробнее в [FRAMERATE_OPTIMISATION.md](./FRAMERATE_OPTIMISATION.md)
- Если у вас мало фпс - [FRAMERATE_OPTIMISATION.md](./FRAMERATE_OPTIMISATION.md)
- Если вы хотите, чтобы некоторые элементы пользовательского интерфейса не светились из-за решейда (мелкое свечение), вы можете изменить размер этого изображения в соответствии с разрешением вашего экрана (дефолтное разрешение -  2k): в папке Anomaly: bin/reshade-shaders/Texures/UIMask.png
- Просмотрите [KEYBINDS.md](./KEYBINDS.md)
- Прочитайте [MANUAL.ru.md](./MANUAL.ru.md) (хотя большая часть руководства теперь доступна на экранах загрузки).
- Прочитайте [How to update](./INSTALLATION.md#how-to-update), чтобы узнать, как поддерживать STALKER GAMMA в актуальном состоянии
