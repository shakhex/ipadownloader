# IPA Downloader

Инструмент для загрузки и установки IPA-файлов из App Store через Apple ID. Поддерживает **Windows** и **macOS**.

## Возможности

- Поиск приложений в App Store и собственном списке
- Загрузка последних и предыдущих версий приложений
- Пакетная загрузка из списка
- Покупка приложений (без загрузки)
- Установка IPA на подключённые устройства
- Проверка минимальной версии iOS
- Двуязычный интерфейс (RU/EN)
- Выбор версии ipatool (v2/v3)

## Быстрый старт

### Windows

1. Скачайте или клонируйте репозиторий
2. Запустите `Start_IPA_Downloader.bat`

Всё необходимое уже включено в комплект.

### macOS

1. Скачайте или клонируйте репозиторий
2. Откройте терминал в папке проекта:
   ```bash
   chmod +x Start_IPA_Downloader.command
   ./Start_IPA_Downloader.command
   ```
   Или напрямую:
   ```bash
   chmod +x IPA_Downloader.sh
   zsh IPA_Downloader.sh
   ```

**Зависимости** устанавливаются автоматически при первом запуске:
- [Homebrew](https://brew.sh) — менеджер пакетов
- `python3` — парсинг JSON и метаданных IPA
- `curl` — HTTP-запросы (предустановлен на macOS)
- [ipatool](https://github.com/majd/ipatool) — загрузка IPA
- [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller) — установка IPA на устройства

Для ручной установки зависимостей:
```bash
brew install python3 ipatool libimobiledevice
```

## Структура проекта

```
IPA_Downloader/
├── IPA_Downloader.ps1            # Windows (PowerShell)
├── Start_IPA_Downloader.bat      # Запуск на Windows
├── IPA_Downloader.sh             # macOS (zsh, нативный)
├── Start_IPA_Downloader.command  # Запуск на macOS
├── MainApp/                      # Бинарные файлы
│   ├── windows_amd64_v2/         #   ipatool.exe, ideviceinstaller.exe
│   ├── windows_amd64_v3/         #   ipatool.exe, ideviceinstaller.exe, anisette.exe
│   ├── macOS_amd64_v2/           #   ipatool (Intel)
│   ├── macOS_amd64_v3/           #   ipatool (Intel)
│   ├── macOS_arm64_v2/           #   ipatool (Apple Silicon)
│   └── macOS_arm64_v3/           #   ipatool (Apple Silicon)
├── Lists/                        # Списки приложений
│   ├── Apps_ID_List.txt          #   Основной список (обновляется с GitHub)
│   └── Banks_ID_List.txt         #   Список банковских приложений
├── Apps/                         # Загруженные IPA-файлы
├── README.md
├── LICENSE
└── .gitignore
```

## Использование

### Режим IPA_Downloader

| Пункт | Описание |
|-------|----------|
| 1-3 | Поиск приложения → покупка / загрузка / загрузка с выбором версии |
| 4-6 | Ввод App ID → покупка / загрузка / загрузка с выбором версии |
| 7-9 | Выбор из списка → покупка / загрузка / загрузка с выбором версии |
| 10 | Проверка минимальной iOS для IPA в папке Apps |
| 11 | Установка IPA из папки Apps на устройство |
| 12-14 | Пакетная загрузка/покупка из полного списка |
| 15-17 | Пакетная загрузка/покупка банковских приложений |
| 18 | Очистка данных |
| 19 | Выход из Apple ID + сброс настроек |
| 20 | Поддержка проекта |
| 21 | Смена языка |

### Режим IPA_Installer

Упрощённый режим для проверки iOS-версий и установки IPA на устройства.

### Навигация в меню

| Клавиша | Действие |
|---------|----------|
| Up/Down | Навигация по пунктам |
| Left/Right | Переключение страниц |
| Space | Выбор/отмена выбора (галочки) |
| Enter | Подтвердить |
| Esc | Отмена / Возврат |
| A / D | Выбрать / снять все на странице |

## Поддержка проекта

Если проект оказался полезным:

- [GitHub Sponsors](https://github.com/sponsors/shakhex)
- [Telegram](https://t.me/shakhex)

## Лицензия

[MIT License](LICENSE)
