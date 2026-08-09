#!/bin/zsh
# IPA_Downloader macOS (zsh)
# Версия: 3.9.8.1.1-macOS (t.me/shakhex edit)

setopt NO_NOMATCH

# Переключение рабочей директории в папку со скриптом:
cd "$(dirname "$0")" || exit 1

# ============================================================
# НАСТРОЙКИ И ПЕРЕМЕННЫЕ
# ============================================================

SCRIPT_VERSION="3.9.8.1.1-macOS (t.me/shakhex edit)"
REPO_URL="https://github.com/shakhex/ipadownloader"
RAW_BASE="https://raw.githubusercontent.com/shakhex/ipadownloader/main"
SELF_UPDATE_URL="$RAW_BASE/IPA_Downloader.sh"
SELF_UPDATE_PS_URL="$RAW_BASE/IPA_Downloader.ps1"
SELF_UPDATE_COMMAND_URL="$RAW_BASE/Start_IPA_Downloader.command"

MAINAPP_DIR="./MainApp"
SETTINGS_FILE="$MAINAPP_DIR/Settings.txt"
LISTS_DIR="./Lists"
APPS_DIR="./Apps"
DOWNLOADED_FILE="$LISTS_DIR/Downloaded_IDs.json"
PURCHASED_FILE="$LISTS_DIR/Purchased_IDs.json"
APPS_ID_LIST="$LISTS_DIR/Apps_ID_List.txt"
APPS_ID_TMP="$MAINAPP_DIR/Apps_ID_List_tmp.txt"
IPATOOL_HOME="$HOME/.ipatool"
ACCOUNT_FILE="$IPATOOL_HOME/account"
COOKIES_FILE="$IPATOOL_HOME/cookies"
TEMP_IPA="$(getconf DARWIN_USER_TEMP_DIR)/Temp.ipa"

# Определение архитектуры:
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    ARCH_BASE="macOS_arm64"
else
    ARCH_BASE="macOS_amd64"
fi

# ============================================================
# ПЕРЕВОДЫ
# ============================================================

typeset -A L
CURRENT_LANG="RU"

load_lang() {
    local lang="$1"
    CURRENT_LANG="$lang"

    L[AccountCleared_RU]="Готово. Данные аккаунта %s удалены."
    L[AccountCleared_EN]="Done. Account %s data cleared."
    L[AddedToDownloadedList_RU]="Добавлено в список: %s - %s"
    L[AddedToDownloadedList_EN]="Added to list: %s - %s"
    L[AddedToPurchasedList_RU]="Добавлено в список покупок: %s - %s"
    L[AddedToPurchasedList_EN]="Added to purchased list: %s - %s"
    L[AlreadyInList_RU]="Уже есть в списке: %s - %s"
    L[AlreadyInList_EN]="Already in list: %s - %s"
    L[AppsCleared_RU]="Готово. Приложения в папке Apps удалены."
    L[AppsCleared_EN]="Done. Apps folder has been cleared."
    L[AskAppNum_RU]="Введите номера приложений"
    L[AskAppNum_EN]="Enter app index numbers"
    L[AskIdDownload_RU]="Введите ID приложения для загрузки"
    L[AskIdDownload_EN]="Enter app IDs to download"
    L[AskIdSearch_RU]="Введите ID приложения для поиска"
    L[AskIdSearch_EN]="Enter app IDs to search"
    L[AskIdPurchase_RU]="Введите ID приложения для покупки"
    L[AskIdPurchase_EN]="Enter app IDs to purchase"
    L[AskSearch_RU]="Введите название приложения для поиска"
    L[AskSearch_EN]="Enter app name to search"
    L[AskVerCount_RU]="Введите количество версий для отображения"
    L[AskVerCount_EN]="Enter number of versions to display"
    L[AuthFail_RU]="Вход в Apple ID не выполнен."
    L[AuthFail_EN]="Not authenticated with Apple ID."
    L[AuthSuccess_RU]="Вход в Apple ID выполнен.\nДанные аккаунта:"
    L[AuthSuccess_EN]="Apple ID login successful.\nAccount details:"
    L[CancelStep_RU]="(0: Отмена/Возврат в главное меню)"
    L[CancelStep_EN]="(0: Cancel/Return to main menu)"
    L[ClearAccountMenuTitle_RU]="Выберите аккаунты для очистки:"
    L[ClearAccountMenuTitle_EN]="Select accounts to clear:"
    L[ClearAllAccounts_RU]="Все аккаунты"
    L[ClearAllAccounts_EN]="All accounts"
    L[ClearMenu1_RU]="Список приобретенных приложений"
    L[ClearMenu1_EN]="Purchased apps list"
    L[ClearMenu2_RU]="Список загруженных приложений"
    L[ClearMenu2_EN]="Downloaded apps list"
    L[ClearMenu3_RU]="Приложения в папке Apps"
    L[ClearMenu3_EN]="Apps in Apps folder"
    L[ClearMenuTitle_RU]="Выберите данные для очистки:"
    L[ClearMenuTitle_EN]="Select data to clear:"
    L[DownloadedListCleared_RU]="Готово. Список загруженных приложений очищен."
    L[DownloadedListCleared_EN]="Done. Downloaded apps list cleared."
    L[DownloadedListMenu1_RU]="Полный список приложений (GitHub)"
    L[DownloadedListMenu1_EN]="Full apps list (GitHub)"
    L[DownloadedListMenu2_RU]="Список загруженных приложений"
    L[DownloadedListMenu2_EN]="Downloaded apps list"
    L[DownloadedListMenu3_RU]="Список не загруженных приложений"
    L[DownloadedListMenu3_EN]="Not downloaded apps list"
    L[ErrorDownloadedEmpty_RU]="Ошибка: История загрузок пуста."
    L[ErrorDownloadedEmpty_EN]="Error: Download history is empty."
    L[ErrorInvalidInput_RU]="Ошибка: Неверный ввод."
    L[ErrorInvalidInput_EN]="Error: Invalid input."
    L[ErrorListLoadError_RU]="Ошибка загрузки списка приложений."
    L[ErrorListLoadError_EN]="Failed to load apps list."
    L[ErrorIdeviceinstallerNotFound_RU]="Ошибка: ideviceinstaller не найден. Установка приложений через скрипт невозможна."
    L[ErrorIdeviceinstallerNotFound_EN]="Error: ideviceinstaller not found. Apps installation via script is impossible."
    L[ErrorMissingFiles_RU]="Ошибка. Следующие файлы не найдены:"
    L[ErrorMissingFiles_EN]="Error. Following files were not found:"
    L[ErrorNoApps_RU]="Ошибка: В папке Apps отсутствуют приложения."
    L[ErrorNoApps_EN]="Error: No apps found in Apps folder."
    L[ErrorNoAppsFound_RU]="Ошибка: Приложения не найдены."
    L[ErrorNoAppsFound_EN]="Error: No apps found."
    L[ErrorPurchasedEmpty_RU]="Ошибка: История покупок пуста."
    L[ErrorPurchasedEmpty_EN]="Error: Purchase history is empty."
    L[ErrorUpdateCheck_RU]="Ошибка: Не удалось проверить наличие обновлений."
    L[ErrorUpdateCheck_EN]="Error: Failed to check for updates."
    L[FileName_RU]="Имя файла:"
    L[FileName_EN]="File name:"
    L[FileSaved_RU]="Готово. Файл сохранен в папку Apps."
    L[FileSaved_EN]="Done. File saved to Apps folder."
    L[HeaderFileName_RU]="Имя файла"
    L[HeaderFileName_EN]="File name"
    L[HeaderMinIOS_RU]="Мин. iOS"
    L[HeaderMinIOS_EN]="Min. iOS"
    L[HeaderVerID_RU]="ID версии"
    L[HeaderVerID_EN]="Version ID"
    L[HeaderVersion_RU]="Версия"
    L[HeaderVersion_EN]="Version"
    L[InstallApp_RU]="Установка:"
    L[InstallApp_EN]="Installing:"
    L[InstallerMenu1_RU]="Проверка минимальной версии iOS для приложений в папке Apps"
    L[InstallerMenu1_EN]="Check minimum iOS version for apps in Apps folder"
    L[InstallerMenu2_RU]="Установка приложений из папки Apps"
    L[InstallerMenu2_EN]="Install apps from Apps folder"
    L[InstallerMenu3_RU]="Поддержка проекта"
    L[InstallerMenu3_EN]="Project support"
    L[InstallerMenu4_RU]="Сменить язык (Change Language)"
    L[InstallerMenu4_EN]="Change Language (Сменить язык)"
    L[InstallerMenu5_RU]="Сброс настроек"
    L[InstallerMenu5_EN]="Reset settings"
    L[InstallerMenu6_RU]="Перейти в IPA_Downloader"
    L[InstallerMenu6_EN]="Switch to IPA_Downloader"
    L[IpatoolVersionMenuTitle_RU]="Выберите версию ipatool:"
    L[IpatoolVersionMenuTitle_EN]="Select ipatool version:"
    L[LangChanged_RU]="Язык успешно изменен на Русский."
    L[LangChanged_EN]="Language successfully changed to English."
    L[LanguageMenu1_RU]="Русский"
    L[LanguageMenu1_EN]="Русский"
    L[LanguageMenu2_RU]="English"
    L[LanguageMenu2_EN]="English"
    L[LanguageMenuTitle_RU]="Выберите язык (Select language):"
    L[LanguageMenuTitle_EN]="Выберите язык (Select language):"
    L[ListMenuTitle_RU]="Выберите список для отображения:"
    L[ListMenuTitle_EN]="Select list to display:"
    L[LoggedOut_RU]="Выполнен выход из Apple ID."
    L[LoggedOut_EN]="Successfully logged out of Apple ID."
    L[Menu1_RU]="Поиск приложения и покупка (без загрузки)"
    L[Menu1_EN]="Search for app and purchase (without downloading)"
    L[Menu2_RU]="Поиск приложения и загрузка последней версии"
    L[Menu2_EN]="Search for app and download latest version"
    L[Menu3_RU]="Поиск приложения и загрузка (с выбором версии)"
    L[Menu3_EN]="Search for app and download (with version selection)"
    L[Menu4_RU]="Ввод ID приложений и покупка (без загрузки)"
    L[Menu4_EN]="Enter app IDs and purchase (without downloading)"
    L[Menu5_RU]="Ввод ID приложений и загрузка последней версии"
    L[Menu5_EN]="Enter app IDs and download latest version"
    L[Menu6_RU]="Ввод ID приложений и загрузка (с выбором версии)"
    L[Menu6_EN]="Enter app IDs and download (with version selection)"
    L[Menu7_RU]="Вывод списка приложений и покупка (без загрузки)"
    L[Menu7_EN]="Show list of apps and purchase (without downloading)"
    L[Menu8_RU]="Вывод списка приложений и загрузка последней версии"
    L[Menu8_EN]="Show list of apps and download latest version"
    L[Menu9_RU]="Вывод списка приложений и загрузка (с выбором версии)"
    L[Menu9_EN]="Show list of apps and download (with version selection)"
    L[Menu10_RU]="Проверка минимальной версии iOS для приложений в папке Apps"
    L[Menu10_EN]="Check minimum iOS version for apps in Apps folder"
    L[Menu11_RU]="Установка приложений из папки Apps"
    L[Menu11_EN]="Install apps from Apps folder"
    L[Menu12_RU]="Загрузить приложения из списка (последняя версия)"
    L[Menu12_EN]="Download apps from list (latest version)"
    L[Menu13_RU]="Загрузить приложения из списка (с выбором версии)"
    L[Menu13_EN]="Download apps from list (with version selection)"
    L[Menu14_RU]="Приобрести приложения из списка (без загрузки)"
    L[Menu14_EN]="Purchase apps from list (without downloading)"
    L[Menu15_RU]="Загрузить банковские приложения из списка (последняя версия)"
    L[Menu15_EN]="Download bank apps from list (latest version)"
    L[Menu16_RU]="Загрузить банковские приложения из списка (с выбором версии)"
    L[Menu16_EN]="Download bank apps from list (with version selection)"
    L[Menu17_RU]="Приобрести банковские приложения из списка (без загрузки)"
    L[Menu17_EN]="Purchase bank apps from list (without downloading)"
    L[Menu18_RU]="Очистка данных"
    L[Menu18_EN]="Clear data"
    L[Menu19_RU]="Выход из Apple ID + сброс настроек"
    L[Menu19_EN]="Log out of Apple ID + reset settings"
    L[Menu20_RU]="Поддержка проекта"
    L[Menu20_EN]="Project support"
    L[Menu21_RU]="Сменить язык (Change Language)"
    L[Menu21_EN]="Change Language (Сменить язык)"
    L[MenuTitle_RU]="Введите команду:"
    L[MenuTitle_EN]="Enter a command:"
    L[MinIOS_RU]="Минимальная версия iOS:"
    L[MinIOS_EN]="Minimum iOS version:"
    L[ModeMenu1_RU]="IPA_Downloader"
    L[ModeMenu1_EN]="IPA_Downloader"
    L[ModeMenu2_RU]="IPA_Installer"
    L[ModeMenu2_EN]="IPA_Installer"
    L[ModeMenuTitle_RU]="Выберите режим работы:"
    L[ModeMenuTitle_EN]="Select operating mode:"
    L[PurchasedListCleared_RU]="Готово. Список приобретенных приложений очищен."
    L[PurchasedListCleared_EN]="Done. Purchased apps list cleared."
    L[PurchasedListMenu1_RU]="Полный список приложений (GitHub)"
    L[PurchasedListMenu1_EN]="Full apps list (GitHub)"
    L[PurchasedListMenu2_RU]="Список приобретенных приложений"
    L[PurchasedListMenu2_EN]="Purchased apps list"
    L[PurchasedListMenu3_RU]="Список не приобретенных приложений"
    L[PurchasedListMenu3_EN]="Not purchased apps list"
    L[SelectedApp_RU]="Выбрано приложение:"
    L[SelectedApp_EN]="Selected app:"
    L[SelectedVer_RU]="Выбрана версия:"
    L[SelectedVer_EN]="Selected version:"
    L[UpdateAvailableTitle_RU]="Доступно обновление (версия %s). Перейти на страницу GitHub для загрузки?"
    L[UpdateAvailableTitle_EN]="Update available (version %s). Go to GitHub page to download?"
    L[UpdateMenu1_RU]="Да"
    L[UpdateMenu1_EN]="Yes"
    L[UpdateMenu2_RU]="Нет"
    L[UpdateMenu2_EN]="No"
    L[BulkDownloadProgress_RU]="[%s/%s] %s (ID: %s)"
    L[BulkDownloadProgress_EN]="[%s/%s] %s (ID: %s)"
    L[BulkDownloadComplete_RU]="Готово. Обработано приложений: %s"
    L[BulkDownloadComplete_EN]="Done. Apps processed: %s"
    L[AlreadyDownloaded_RU]="Уже скачано, пропускаю: %s"
    L[AlreadyDownloaded_EN]="Already downloaded, skipping: %s"
    L[BanksListLoaded_RU]="Загружено банковских приложений: %s"
    L[BanksListLoaded_EN]="Bank apps loaded: %s"
    L[PageHeader_RU]="Страница %s/%s"
    L[PageHeader_EN]="Page %s/%s"
    L[SelectedCount_RU]="Выбрано: %s"
    L[SelectedCount_EN]="Selected: %s"
    L[NothingSelected_RU]="Ничего не выбрано."
    L[NothingSelected_EN]="Nothing selected."
    L[HelpConfirm_RU]="Enter: подтвердить"
    L[HelpConfirm_EN]="Enter: confirm"
    L[HelpCancel_RU]="Esc: отмена"
    L[HelpCancel_EN]="Esc: cancel"
    L[HelpNavigate_RU]="Up/Down: навигация"
    L[HelpNavigate_EN]="Up/Down: navigate"
    L[HelpToggle_RU]="Space: выбор"
    L[HelpToggle_EN]="Space: toggle"
    L[HelpPages_RU]="Left/Right: страницы"
    L[HelpPages_EN]="Left/Right: pages"
    L[HelpMenuNav_RU]="Up/Down: навигация | Enter: выбор"
    L[HelpMenuNav_EN]="Up/Down: navigate | Enter: select"
    L[HelpMenuNavCancel_RU]="Up/Down: навигация | Enter: выбор | Esc: отмена"
    L[HelpMenuNavCancel_EN]="Up/Down: navigate | Enter: select | Esc: cancel"
}

# Получение строки перевода:
t() {
    local key="$1"
    local full_key="${key}_${CURRENT_LANG}"
    if [[ -n "${L[$full_key]+x}" ]]; then
        echo "${L[$full_key]}"
    else
        echo "$key"
    fi
}

# Форматированная строка перевода (printf):
tf() {
    local key="$1"
    shift
    local pattern
    pattern=$(t "$key")
    printf "$pattern" "$@"
}

# ============================================================
# УТИЛИТЫ
# ============================================================

separator() {
    echo "================================================"
}

show_error() {
    local key="${1:-ErrorInvalidInput}"
    separator
    echo "$(t "$key")"
}

press_any_key() {
    echo ""
    if [[ "$CURRENT_LANG" == "RU" ]]; then
        echo -n "Нажмите любую клавишу для продолжения..."
    else
        echo -n "Press any key to continue..."
    fi
    read -k 1 -s -r < /dev/tty
    echo ""
}

# ============================================================
# НАСТРОЙКИ
# ============================================================

get_setting() {
    local key="$1"
    if [[ -f "$SETTINGS_FILE" ]]; then
        local val
        val=$(grep "^${key}=" "$SETTINGS_FILE" 2>/dev/null | tail -1 | cut -d'=' -f2-)
        echo "$val"
    fi
}

set_setting() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    if [[ -f "$SETTINGS_FILE" ]] && grep -q "^${key}=" "$SETTINGS_FILE" 2>/dev/null; then
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$SETTINGS_FILE"
    else
        echo "${key}=${value}" >> "$SETTINGS_FILE"
    fi
}

load_settings() {
    local saved_lang saved_mode saved_ver
    saved_lang=$(get_setting "Language")
    saved_mode=$(get_setting "Mode")
    saved_ver=$(get_setting "IpatoolVersion")

    if [[ "$saved_lang" == "RU" || "$saved_lang" == "EN" ]]; then
        CURRENT_LANG="$saved_lang"
    else
        CURRENT_LANG="RU"
    fi

    if [[ "$saved_mode" == "Downloader" || "$saved_mode" == "Installer" ]]; then
        WORK_MODE="$saved_mode"
    else
        WORK_MODE=""
    fi

    if [[ "$saved_ver" == "v3" ]]; then
        IPATOOL_VERSION="v3"
    else
        IPATOOL_VERSION="v2"
    fi
}

# ============================================================
# АРХИТЕКТУРА И ПУТИ
# ============================================================

get_arch_subfolder() {
    local ver="$1"
    if [[ "$ARCH" == "arm64" ]]; then
        echo "macOS_arm64_${ver}"
    else
        echo "macOS_amd64_${ver}"
    fi
}

update_paths() {
    ARCH_SUBFOLDER=$(get_arch_subfolder "$IPATOOL_VERSION")
    BINARY_DIR="$MAINAPP_DIR/$ARCH_SUBFOLDER"
    IPATOOL_PATH="$BINARY_DIR/ipatool"
}

# ============================================================
# JSON УТИЛИТЫ (python3)
# ============================================================

json_read_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "null"
        return
    fi
    python3 -c "
import json, sys
try:
    with open('$file', 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(json.dumps(data, ensure_ascii=False))
except:
    print('null')
" 2>/dev/null
}

json_write_file() {
    local file="$1"
    local data="$2"
    mkdir -p "$(dirname "$file")"
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
with open(sys.argv[2], 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
" "$data" "$file" 2>/dev/null
}

json_get_keys() {
    local data="$1"
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
if isinstance(data, dict):
    for k in data.keys():
        print(k)
" "$data" 2>/dev/null
}

json_get_account_apps() {
    local data="$1"
    local account="$2"
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
account = sys.argv[2]
if isinstance(data, dict) and account in data:
    apps = data[account]
    if isinstance(apps, list):
        print(json.dumps(apps, ensure_ascii=False))
    else:
        print('[]')
elif isinstance(data, list):
    print(json.dumps(data, ensure_ascii=False))
else:
    print('[]')
" "$data" "$account" 2>/dev/null
}

json_set_account_apps() {
    local data="$1"
    local account="$2"
    local apps="$3"
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
account = sys.argv[2]
apps = json.loads(sys.argv[3])
if not isinstance(data, dict):
    data = {}
data[account] = apps
print(json.dumps(data, ensure_ascii=False, indent=2))
" "$data" "$account" "$apps" 2>/dev/null
}

json_array_contains_appid() {
    local apps_json="$1"
    local appid="$2"
    python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
appid = sys.argv[2]
if isinstance(apps, list):
    for item in apps:
        if isinstance(item, dict) and item.get('appid') == appid:
            print('yes')
            sys.exit(0)
print('no')
" "$apps_json" "$appid" 2>/dev/null
}

# ============================================================
# IPA МЕТАДАННЫЕ (python3)
# ============================================================

get_ipa_metadata() {
    local ipa_path="$1"
    if [[ ! -f "$ipa_path" ]]; then
        echo "App|0|NA"
        return
    fi
    python3 -c "
import zipfile, plistlib, sys, os

ipa_path = sys.argv[1]
try:
    with zipfile.ZipFile(ipa_path, 'r') as z:
        plist_entries = [e for e in z.namelist() if e.startswith('Payload/') and e.endswith('.app/Info.plist')]
        if not plist_entries:
            print('App|0|NA')
            sys.exit(0)
        plist_data = z.read(plist_entries[0])
        try:
            plist = plistlib.loads(plist_data)
        except:
            plist = None
            content = plist_data.decode('utf-8', errors='ignore')
            import re
            app_name = 'App'
            version = '0'
            min_ios = 'NA'
            m = re.search(r'<key>CFBundleName</key>\s*<string>([^<]+)</string>', content)
            if m: app_name = m.group(1)
            if app_name == 'App':
                m = re.search(r'<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>', content)
                if m: app_name = m.group(1)
            m = re.search(r'<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>', content)
            if m: version = m.group(1)
            m = re.search(r'<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>', content)
            if m: min_ios = m.group(1)
            app_name = app_name.replace('/', '').replace(':', '').replace('*', '').replace('?', '').replace('\"', '').replace('<', '').replace('>', '').replace('|', '')
            print(f'{app_name}|{version}|{min_ios}')
            sys.exit(0)
        app_name = plist.get('CFBundleName', 'App')
        if app_name == 'App':
            app_name = plist.get('CFBundleDisplayName', 'App')
        version = plist.get('CFBundleShortVersionString', '0')
        min_ios = plist.get('MinimumOSVersion', 'NA')
        for c in '/:*?\"<>|':
            app_name = app_name.replace(c, '')
        print(f'{app_name}|{version}|{min_ios}')
except Exception as e:
    print('App|0|NA')
" "$ipa_path" 2>/dev/null || echo "App|0|NA"
}

# ============================================================
# GITHUB СПИСОК
# ============================================================

# Глобальные массивы для кэша:
GITHUB_NAMES=()
GITHUB_IDS=()
GITHUB_LOADED=0

initialize_github_list() {
    if [[ $GITHUB_LOADED -eq 1 ]]; then
        return
    fi

    # Скачиваем если нет:
    if [[ ! -f "$APPS_ID_LIST" ]]; then
        curl -sL "$RAW_BASE/Lists/Apps_ID_List.txt" -o "$APPS_ID_LIST" 2>/dev/null
    fi

    if [[ ! -f "$APPS_ID_LIST" ]]; then
        GITHUB_LOADED=1
        return
    fi

    GITHUB_NAMES=()
    GITHUB_IDS=()

    while IFS= read -r line; do
        if [[ "$line" =~ ^(.+):\ *([0-9]+)$ ]]; then
            GITHUB_NAMES+=("${match[1]}")
            GITHUB_IDS+=("${match[2]}")
        fi
    done < "$APPS_ID_LIST"

    GITHUB_LOADED=1
}

get_github_app_name() {
    local appid="$1"
    initialize_github_list
    local i
    for ((i=1; i<=${#GITHUB_IDS[@]}; i++)); do
        if [[ "${GITHUB_IDS[$i]}" == "$appid" ]]; then
            echo "${GITHUB_NAMES[$i]}"
            return
        fi
    done
    echo ""
}

resolve_app_display_name() {
    local appid="$1"
    local github_name
    github_name=$(get_github_app_name "$appid")
    if [[ -n "$github_name" ]]; then
        DISPLAY_NAME="$github_name"
        FINAL_NAME="$github_name"
    else
        DISPLAY_NAME="$appid"
        FINAL_NAME="Unknown"
    fi
}

# ============================================================
# ТЕКУЩИЙ APPLE ID
# ============================================================

CURRENT_APPLEID="UnknownAccount"

get_current_appleid() {
    local auth_info
    auth_info=$("$IPATOOL_PATH" auth info 2>&1)
    if [[ "$auth_info" =~ email=([^[:space:]]+) ]]; then
        CURRENT_APPLEID="${match[1]}"
    else
        CURRENT_APPLEID="UnknownAccount"
    fi
}

test_ipatool_auth() {
    local auth_info
    auth_info=$("$IPATOOL_PATH" auth info 2>&1)
    [[ "$auth_info" =~ email= ]]
}

connect_apple_id() {
    while ! test_ipatool_auth; do
        rm -f "$COOKIES_FILE" 2>/dev/null
        separator
        echo "$(t AuthFail)"
        "$IPATOOL_PATH" auth login
    done
    get_current_appleid
}

# ============================================================
# СОХРАНЕНИЕ В СПИСОК
# ============================================================

save_app_to_list() {
    local appid="$1"
    local app_name="$2"
    local type="$3"  # Downloaded | Purchased

    if [[ -z "$app_name" || "$app_name" == "Unknown" ]]; then
        return
    fi

    local history_file
    if [[ "$type" == "Purchased" ]]; then
        history_file="$PURCHASED_FILE"
    else
        history_file="$DOWNLOADED_FILE"
    fi

    # Создание файла если нет:
    if [[ ! -f "$history_file" ]]; then
        echo '{}' > "$history_file"
    fi

    local raw_data
    raw_data=$(json_read_file "$history_file")
    if [[ "$raw_data" == "null" || -z "$raw_data" ]]; then
        raw_data='{}'
    fi

    # Проверка на старый формат (массив):
    local is_array
    is_array=$(python3 -c "
import json, sys
d = json.loads(sys.argv[1])
print('yes' if isinstance(d, list) else 'no')
" "$raw_data" 2>/dev/null)

    if [[ "$is_array" == "yes" ]]; then
        local old_array="$raw_data"
        raw_data=$(python3 -c "
import json, sys
old = json.loads(sys.argv[1])
print(json.dumps({'UnknownAccount': old}, ensure_ascii=False))
" "$old_array" 2>/dev/null)
    fi

    # Получаем список для текущего аккаунта:
    local account_apps
    account_apps=$(json_get_account_apps "$raw_data" "$CURRENT_APPLEID")

    # Синхронизация имён с GitHub:
    initialize_github_list

    # Проверка на дубликат:
    local is_dup
    is_dup=$(json_array_contains_appid "$account_apps" "$appid")

    if [[ "$is_dup" == "yes" ]]; then
        local current_name
        current_name=$(get_github_app_name "$appid")
        if [[ -z "$current_name" ]]; then
            current_name="$app_name"
        fi
        tf AlreadyInList "$current_name" "$appid"
        return
    fi

    # Добавление нового элемента:
    local new_apps
    new_apps=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
apps.append({'name': sys.argv[2], 'appid': sys.argv[3]})
print(json.dumps(apps, ensure_ascii=False))
" "$account_apps" "$app_name" "$appid" 2>/dev/null)

    # Сортировка по порядку GitHub списка:
    new_apps=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
ids = sys.argv[2].split('\n') if sys.argv[2] else []
names_raw = sys.argv[3].split('\n') if sys.argv[3] else []
ref_map = {}
for i, gid in enumerate(ids):
    ref_map[gid] = i

def sort_key(item):
    aid = item.get('appid', '')
    idx = ref_map.get(aid, 999999)
    name = item.get('name', '').upper().replace('Ё', 'Е')
    return (idx, name)

apps.sort(key=sort_key)
print(json.dumps(apps, ensure_ascii=False))
" "$new_apps" "$(printf '%s\n' "${GITHUB_IDS[@]}")" "$(printf '%s\n' "${GITHUB_NAMES[@]}")" 2>/dev/null)

    # Сохраняем:
    local updated_data
    updated_data=$(json_set_account_apps "$raw_data" "$CURRENT_APPLEID" "$new_apps")
    json_write_file "$history_file" "$updated_data"

    # Сообщение:
    if [[ "$type" == "Purchased" ]]; then
        tf AddedToPurchasedList "$app_name" "$appid"
    else
        tf AddedToDownloadedList "$app_name" "$appid"
    fi
}

# ============================================================
# ЧТЕНИЕ СПИСКА ПРИЛОЖЕНИЙ
# ============================================================

read_app_list_json() {
    local file_path="$1"
    local empty_error="$2"

    if [[ ! -f "$file_path" ]]; then
        if [[ -n "$empty_error" ]]; then
            show_error "$empty_error"
        fi
        echo ""
        return
    fi

    local raw
    raw=$(json_read_file "$file_path")
    if [[ "$raw" == "null" || "$raw" == "{}" ]]; then
        if [[ -n "$empty_error" ]]; then
            show_error "$empty_error"
        fi
        echo ""
        return
    fi

    # Получаем данные аккаунта:
    local apps
    apps=$(json_get_account_apps "$raw" "$CURRENT_APPLEID")

    local count
    count=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
print(len(apps) if isinstance(apps, list) else 0)
" "$apps" 2>/dev/null)

    if [[ "$count" == "0" ]]; then
        if [[ -n "$empty_error" ]]; then
            show_error "$empty_error"
        fi
        echo ""
        return
    fi

    echo "$apps"
}

# ============================================================
# ПЕРЕМЕЩЕНИЕ IPA
# ============================================================

move_ipa_files() {
    local appid="$1"
    local app_name="$2"

    local found=0
    for f in *.ipa(N); do
        if [[ -f "$f" ]]; then
            found=1
            mv "$f" "$APPS_DIR/"
            separator
            echo "$(t FileSaved)"

            local meta
            meta=$(get_ipa_metadata "$APPS_DIR/$f")
            IFS='|' read -r meta_name meta_ver meta_minios <<< "$meta"

            local final_name="$meta_name"

            # Проверяем GitHub если имя неизвестно:
            if [[ -z "$app_name" || "$app_name" == "Unknown" ]]; then
                local gh_name
                gh_name=$(get_github_app_name "$appid")
                if [[ -n "$gh_name" ]]; then
                    app_name="$gh_name"
                fi
            fi

            if [[ -n "$app_name" && "$app_name" != "Unknown" ]]; then
                final_name="$app_name"
            fi

            # Очистка имени от спецсимволов:
            final_name=$(echo "$final_name" | sed 's/[\\/:*?"<>|]//g')

            local new_name="${final_name}_${meta_ver}_iOS_${meta_minios}+_${CURRENT_APPLEID}.ipa"
            new_name=$(echo "$new_name" | sed 's/ /_/g')

            if [[ -f "$APPS_DIR/$new_name" ]]; then
                rm -f "$APPS_DIR/$new_name"
            fi

            mv "$APPS_DIR/$f" "$APPS_DIR/$new_name"
            echo "$(t FileName) $new_name"
            echo "$(t MinIOS) ${meta_minios}+"

            if [[ -n "$appid" ]]; then
                save_app_to_list "$appid" "$final_name" "Downloaded"
            fi
        fi
    done
}

# ============================================================
# ИНТЕРАКТИВНЫЕ КЛАВИШИ
# ============================================================

# Чтение клавиши (возвращает: UP, DOWN, LEFT, RIGHT, ENTER, ESC, SPACE, или символ)
read_key() {
    local key
    read -k 1 -s key < /dev/tty

    case "$key" in
        $'\x1b')
            local seq1
            if read -k 1 -t 0.1 -s seq1 2>/dev/null < /dev/tty; then
                if [[ "$seq1" == '[' ]]; then
                    local seq2
                    read -k 1 -s seq2 < /dev/tty
                    case "$seq2" in
                        A) echo "UP" ;;
                        B) echo "DOWN" ;;
                        C) echo "RIGHT" ;;
                        D) echo "LEFT" ;;
                        *) echo "UNKNOWN" ;;
                    esac
                else
                    echo "ESC"
                fi
            else
                echo "ESC"
            fi
            ;;
        ''|$'\n'|$'\r') echo "ENTER" ;;
        ' ') echo "SPACE" ;;
        *) echo "$key" ;;
    esac
}

# ============================================================
# ИНТЕРАКТИВНОЕ МЕНЮ (одиночный выбор)
# ============================================================

# Глобальная переменная для заголовка:
MENU_HEADER=""

show_interactive_menu() {
    local title="$1"
    local allow_cancel="$2"  # "cancel" or ""
    shift 2
    local options=("$@")

    local cursor=0
    local count=${#options[@]}

    redraw_menu() {
        printf '\033[2J\033[H' > /dev/tty
        if [[ -n "$MENU_HEADER" ]]; then
            echo "$MENU_HEADER" > /dev/tty
        fi
        echo "$title" > /dev/tty
        echo "" > /dev/tty
        local i
        for ((i=0; i<count; i++)); do
            if [[ $i -eq $cursor ]]; then
                printf '\033[7m > %s\033[0m\n' "${options[$i]}" > /dev/tty
            else
                echo "   ${options[$i]}" > /dev/tty
            fi
        done
        echo "" > /dev/tty
        if [[ "$allow_cancel" == "cancel" ]]; then
            echo "$(t HelpMenuNavCancel)" > /dev/tty
        else
            echo "$(t HelpMenuNav)" > /dev/tty
        fi
    }

    redraw_menu

    while true; do
        local key
        key=$(read_key)
        case "$key" in
            UP)
                if [[ $cursor -gt 0 ]]; then
                    ((cursor--))
                    redraw_menu
                fi
                ;;
            DOWN)
                if [[ $cursor -lt $((count-1)) ]]; then
                    ((cursor++))
                    redraw_menu
                fi
                ;;
            ENTER)
                echo $((cursor+1))
                return
                ;;
            ESC)
                if [[ "$allow_cancel" == "cancel" ]]; then
                    echo "0"
                    return
                fi
                ;;
        esac
    done
}

# ============================================================
# ПАГИНИРОВАННЫЙ ВЫБОР С ГАЛОЧКАМИ
# ============================================================

# Возвращает через глобальную переменную SELECTED_INDICES (массив 1-based)
SELECTED_INDICES=()

show_paginated_selection() {
    local -a item_names=()
    local -a item_ids=()
    local page_size=20

    # Парсинг аргументов: pairs of (name, id)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --page-size) page_size="$2"; shift 2 ;;
            *) item_names+=("$1"); item_ids+=("$2"); shift 2 ;;
        esac
    done

    local total=${#item_names[@]}
    if [[ $total -eq 0 ]]; then
        SELECTED_INDICES=()
        echo ""
        return
    fi

    local total_pages=$(( (total + page_size - 1) / page_size ))
    local current_page=1
    local cursor=0
    local -A selected_map=()

    redraw_page() {
        printf '\033[2J\033[H' > /dev/tty
        local start_idx=$(( (current_page - 1) * page_size ))
        local end_idx=$(( start_idx + page_size ))
        if [[ $end_idx -gt $total ]]; then
            end_idx=$total
        fi

        # Заголовок:
        printf '\033[36m=== %s ===\033[0m\n' "$(printf "$(t PageHeader)" "$current_page" "$total_pages")" > /dev/tty
        echo "" > /dev/tty

        local i
        for ((i=start_idx; i<end_idx; i++)); do
            local num=$((i+1))
            local rel=$((i - start_idx))
            local mark="   "
            local prefix="   "

            if [[ -n "${selected_map[$num]+x}" ]]; then
                mark="[x]"
            else
                mark="[ ]"
            fi

            if [[ $rel -eq $cursor ]]; then
                prefix=" > "
                printf '\033[30;47m%s%s %s (ID: %s)\033[0m\n' "$prefix" "$mark" "${item_names[$i]}" "${item_ids[$i]}" > /dev/tty
            elif [[ -n "${selected_map[$num]+x}" ]]; then
                printf '\033[32m%s%s %s (ID: %s)\033[0m\n' "$prefix" "$mark" "${item_names[$i]}" "${item_ids[$i]}" > /dev/tty
            else
                echo "${prefix}${mark} ${item_names[$i]} (ID: ${item_ids[$i]})" > /dev/tty
            fi
        done

        echo "" > /dev/tty
        echo "================================================" > /dev/tty
        local sel_count=${#selected_map[@]}
        printf '\033[33m%s | %s | %s\033[0m\n' "$(printf "$(t SelectedCount)" "$sel_count")" "$(t HelpConfirm)" "$(t HelpCancel)" > /dev/tty
        printf '\033[36m%s | %s | %s\033[0m\n' "$(t HelpNavigate)" "$(t HelpToggle)" "$(t HelpPages)" > /dev/tty
    }

    redraw_page

    while true; do
        local key
        key=$(read_key)
        local need_redraw=0
        local max_in_page=$(( end_idx - start_idx ))
        # Recalculate:
        local s_idx=$(( (current_page - 1) * page_size ))
        local e_idx=$(( s_idx + page_size ))
        if [[ $e_idx -gt $total ]]; then e_idx=$total; fi
        local max_rel=$(( e_idx - s_idx - 1 ))

        case "$key" in
            UP)
                if [[ $cursor -gt 0 ]]; then
                    ((cursor--))
                    need_redraw=1
                fi
                ;;
            DOWN)
                if [[ $cursor -lt $max_rel ]]; then
                    ((cursor++))
                    need_redraw=1
                fi
                ;;
            LEFT)
                if [[ $current_page -gt 1 ]]; then
                    ((current_page--))
                    cursor=0
                    need_redraw=1
                fi
                ;;
            RIGHT)
                if [[ $current_page -lt $total_pages ]]; then
                    ((current_page++))
                    cursor=0
                    need_redraw=1
                fi
                ;;
            SPACE)
                local gi=$(( (current_page - 1) * page_size + cursor + 1 ))
                if [[ -n "${selected_map[$gi]+x}" ]]; then
                    unset "selected_map[$gi]"
                else
                    selected_map[$gi]=1
                fi
                need_redraw=1
                ;;
            ENTER)
                SELECTED_INDICES=()
                local k
                for k in ${(onk)selected_map}; do
                    SELECTED_INDICES+=($k)
                done
                if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
                    echo "" > /dev/tty
                    echo "$(t NothingSelected)" > /dev/tty
                    SELECTED_INDICES=()
                    return
                fi
                return
                ;;
            ESC)
                SELECTED_INDICES=()
                return
                ;;
            a|A|ф|Ф)
                # Выбрать страницу:
                local ii
                for ((ii=s_idx+1; ii<=e_idx; ii++)); do
                    selected_map[$ii]=1
                done
                need_redraw=1
                ;;
            d|D|в|В)
                # Снять страницу:
                local ii
                for ((ii=s_idx+1; ii<=e_idx; ii++)); do
                    unset "selected_map[$ii]"
                done
                need_redraw=1
                ;;
        esac

        if [[ $need_redraw -eq 1 ]]; then
            redraw_page
        fi
    done
}

# ============================================================
# ЗАГРУЗКА IPA
# ============================================================

ipatool_download() {
    local appid="$1"
    local app_name="$2"

    if [[ ! "$appid" =~ ^[0-9]+$ ]]; then
        separator
        echo "$(t ErrorInvalidInput)"
        return
    fi

    separator
    "$IPATOOL_PATH" download -i "$appid" --purchase
    move_ipa_files "$appid" "$app_name"
}

ipatool_download_with_version() {
    local appid="$1"
    local app_name="$2"

    if [[ ! "$appid" =~ ^[0-9]+$ ]]; then
        separator
        echo "$(t ErrorInvalidInput)"
        return
    fi

    separator
    local raw_output
    raw_output=$("$IPATOOL_PATH" list-versions -i "$appid" 2>&1)

    if [[ "$raw_output" == *"Error:"* ]]; then
        echo "$raw_output"
        return
    fi

    if [[ -z "$raw_output" ]]; then
        return
    fi

    # Извлечение ID версий:
    local -a version_ids
    version_ids=($(echo "$raw_output" | grep -oE '"[0-9]+"' | tr -d '"'))

    if [[ ${#version_ids[@]} -eq 0 ]]; then
        return
    fi

    # Запрос количества версий:
    local ver_qty=0
    while true; do
        separator
        echo -n "$(t AskVerCount) $(t CancelStep): "
        read -r input
        if [[ "$input" == "0" ]]; then return; fi
        if [[ "$input" =~ ^[0-9]+$ && "$input" -gt 0 ]]; then
            ver_qty=$input
            break
        fi
        echo "$(t ErrorInvalidInput)"
    done

    # Берём последние N версий:
    local -a recent_versions
    local total_ver=${#version_ids[@]}
    local start=$(( total_ver - ver_qty ))
    if [[ $start -lt 0 ]]; then start=0; fi
    recent_versions=("${version_ids[@]:$start}")

    # Получаем метаданные версий:
    local -a version_display=()
    local -a version_id_list=()

    for vid in "${recent_versions[@]}"; do
        local meta
        meta=$("$IPATOOL_PATH" get-version-metadata -i "$appid" --external-version-id "$vid" 2>/dev/null)
        local display_ver="NA"
        if [[ "$meta" =~ displayVersion=([^[:space:],]+) ]]; then
            display_ver="${match[1]}"
        fi
        version_display+=("$display_ver (ID: $vid)")
        version_id_list+=("$vid")
    done

    separator

    # Показываем меню выбора версий:
    local -a sel_args=()
    local i
    for ((i=0; i<${#version_display[@]}; i++)); do
        sel_args+=("${version_display[$i]}" "${version_id_list[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        return
    fi

    for idx in "${SELECTED_INDICES[@]}"; do
        local sel_id="${version_id_list[$((idx-1))]}"
        local sel_ver="${version_display[$((idx-1))]}"
        separator
        echo "$(t SelectedVer) $sel_ver"
        separator
        local dl_output
        dl_output=$("$IPATOOL_PATH" download -i "$appid" --external-version-id "$sel_id" 2>&1)
        if [[ "$dl_output" == *"Error:"* || "$dl_output" == *"error"* ]]; then
            echo "$dl_output"
            echo "Skipping version..."
            continue
        fi
        move_ipa_files "$appid" "$app_name"
    done
}

# ============================================================
# ПОИСК ПРИЛОЖЕНИЙ
# ============================================================

search_apps_menu() {
    local app_name=""
    while true; do
        separator
        echo -n "$(t AskSearch) $(t CancelStep): "
        read -r app_name
        if [[ "$app_name" == "0" ]]; then
            echo ""
            return
        fi
        if [[ -n "$app_name" ]]; then
            break
        fi
        echo "$(t ErrorInvalidInput)"
    done

    initialize_github_list

    # Поиск в GitHub списке:
    local -a found_names=()
    local -a found_ids=()

    local i
    for ((i=1; i<=${#GITHUB_NAMES[@]}; i++)); do
        if [[ "${GITHUB_NAMES[$i]}" == *"$app_name"* ]]; then
            found_names+=("${GITHUB_NAMES[$i]}")
            found_ids+=("${GITHUB_IDS[$i]}")
        fi
    done

    # Поиск в App Store через ipatool:
    local search_output
    search_output=$("$IPATOOL_PATH" search "$app_name" --limit 10 2>&1)

    # Пытаемся распарсить результаты:
    local store_apps
    store_apps=$(python3 -c "
import re, json, sys
text = sys.argv[1]
m = re.search(r'apps=(\[.*?\])', text, re.DOTALL)
if m:
    try:
        apps = json.loads(m.group(1))
        for app in apps:
            name = app.get('name', '')
            appid = app.get('id', '')
            if name and appid:
                print(f'{name}|{appid}')
    except:
        pass
" "$search_output" 2>/dev/null)

    if [[ -n "$store_apps" ]]; then
        while IFS='|' read -r s_name s_id; do
            if [[ -n "$s_name" && -n "$s_id" ]]; then
                found_names+=("$s_name")
                found_ids+=("$s_id")
            fi
        done <<< "$store_apps"
    fi

    if [[ ${#found_names[@]} -eq 0 ]]; then
        show_error "ErrorNoAppsFound"
        echo ""
        return
    fi

    # Интерактивный выбор:
    local -a sel_args=()
    for ((i=0; i<${#found_names[@]}; i++)); do
        sel_args+=("${found_names[$i]}" "${found_ids[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    # Возвращаем выбранные приложения:
    SELECTED_APP_NAMES=()
    SELECTED_APP_IDS=()
    for idx in "${SELECTED_INDICES[@]}"; do
        SELECTED_APP_NAMES+=("${found_names[$((idx-1))]}")
        SELECTED_APP_IDS+=("${found_ids[$((idx-1))]}")
    done
}

SELECTED_APP_NAMES=()
SELECTED_APP_IDS=()

# ============================================================
# ВВОД НЕСКОЛЬКИХ ID
# ============================================================

MULTI_APP_IDS=()

get_multiple_app_ids() {
    local prompt_key="$1"
    MULTI_APP_IDS=()

    while true; do
        separator
        echo -n "$(t $prompt_key) $(t CancelStep): "
        read -r input
        if [[ "$input" == "0" ]]; then
            return
        fi
        if [[ -z "$input" ]]; then
            echo "$(t ErrorInvalidInput)"
            continue
        fi

        MULTI_APP_IDS=()
        local valid=1
        local IFS=','
        for part in $input; do
            part=$(echo "$part" | tr -d ' ')
            if [[ "$part" =~ ^[0-9]+$ ]]; then
                MULTI_APP_IDS+=("$part")
            else
                valid=0
                break
            fi
        done

        if [[ $valid -eq 1 && ${#MULTI_APP_IDS[@]} -gt 0 ]]; then
            return
        fi

        echo "$(t ErrorInvalidInput)"
    done
}

# ============================================================
# ВЫБОР ИЗ СПИСКА
# ============================================================

APPS_FROM_LIST=()

get_apps_from_list() {
    local list_mode="$1"  # Download | Purchase
    APPS_FROM_LIST=()

    local menu1 menu2 menu3 target_file empty_error

    if [[ "$list_mode" == "Purchase" ]]; then
        menu1=$(t PurchasedListMenu1)
        menu2=$(t PurchasedListMenu2)
        menu3=$(t PurchasedListMenu3)
        target_file="$PURCHASED_FILE"
        empty_error="ErrorPurchasedEmpty"
    else
        menu1=$(t DownloadedListMenu1)
        menu2=$(t DownloadedListMenu2)
        menu3=$(t DownloadedListMenu3)
        target_file="$DOWNLOADED_FILE"
        empty_error="ErrorDownloadedEmpty"
    fi

    local choice
    choice=$(show_interactive_menu "$(t ListMenuTitle)" "cancel" "$menu1" "$menu2" "$menu3")

    if [[ "$choice" == "0" ]]; then
        return
    fi

    local -a app_names=()
    local -a app_ids=()

    case "$choice" in
        1)
            initialize_github_list
            if [[ ${#GITHUB_IDS[@]} -eq 0 ]]; then
                show_error "ErrorListLoadError"
                return
            fi
            app_names=("${GITHUB_NAMES[@]}")
            app_ids=("${GITHUB_IDS[@]}")
            ;;
        2)
            local history_data
            history_data=$(read_app_list_json "$target_file" "$empty_error")
            if [[ -z "$history_data" ]]; then return; fi

            local count
            count=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
print(len(apps) if isinstance(apps, list) else 0)
" "$history_data" 2>/dev/null)

            if [[ "$count" == "0" ]]; then return; fi

            local names_str ids_str
            names_str=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
for a in apps:
    print(a.get('name', ''))
" "$history_data" 2>/dev/null)
            ids_str=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
for a in apps:
    print(a.get('appid', ''))
" "$history_data" 2>/dev/null)

            while IFS= read -r n; do
                [[ -n "$n" ]] && app_names+=("$n")
            done <<< "$names_str"
            while IFS= read -r id; do
                [[ -n "$id" ]] && app_ids+=("$id")
            done <<< "$ids_str"
            ;;
        3)
            initialize_github_list
            if [[ ${#GITHUB_IDS[@]} -eq 0 ]]; then
                show_error "ErrorListLoadError"
                return
            fi

            local saved_ids=""
            if [[ -f "$target_file" ]]; then
                local history_data
                history_data=$(read_app_list_json "$target_file" "")
                if [[ -n "$history_data" ]]; then
                    saved_ids=$(python3 -c "
import json, sys
apps = json.loads(sys.argv[1])
for a in apps:
    print(a.get('appid', ''))
" "$history_data" 2>/dev/null)
                fi
            fi

            local i
            for ((i=1; i<=${#GITHUB_IDS[@]}; i++)); do
                local gid="${GITHUB_IDS[$i]}"
                if ! echo "$saved_ids" | grep -qxF "$gid" 2>/dev/null; then
                    app_names+=("${GITHUB_NAMES[$i]}")
                    app_ids+=("$gid")
                fi
            done
            ;;
    esac

    if [[ ${#app_names[@]} -eq 0 ]]; then
        show_error "ErrorNoAppsFound"
        return
    fi

    local -a sel_args=()
    local i
    for ((i=0; i<${#app_names[@]}; i++)); do
        sel_args+=("${app_names[$i]}" "${app_ids[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        return
    fi

    APPS_FROM_LIST=()
    for idx in "${SELECTED_INDICES[@]}"; do
        local name="${app_names[$((idx-1))]}"
        local id="${app_ids[$((idx-1))]}"
        APPS_FROM_LIST+=("${name}|${id}")
    done
}

# ============================================================
# ПРОВЕРКА МИНИМАЛЬНОЙ iOS
# ============================================================

get_ios_min_version() {
    local -a ipa_files=()
    for f in "$APPS_DIR"/*.ipa(N); do
        ipa_files+=("$f")
    done

    if [[ ${#ipa_files[@]} -eq 0 ]]; then
        show_error "ErrorNoApps"
        return
    fi

    separator
    printf "%-3s %-30s %s\n" "№" "$(t HeaderFileName)" "$(t HeaderMinIOS)"
    local counter=1
    for f in "${ipa_files[@]}"; do
        local meta
        meta=$(get_ipa_metadata "$f")
        IFS='|' read -r m_name m_ver m_minios <<< "$meta"
        local min_os="${m_minios}+"
        local fname=$(basename "$f")
        if [[ ${#fname} -gt 30 ]]; then
            fname="${fname:0:27}..."
        fi
        printf "%-3s %-30s %s\n" "$counter" "$fname" "$min_os"
        ((counter++))
    done
}

# ============================================================
# УСТАНОВКА ПРИЛОЖЕНИЙ
# ============================================================

invoke_install_apps() {
    local ideviceinstaller_path
    ideviceinstaller_path=$(which ideviceinstaller 2>/dev/null)
    if [[ -z "$ideviceinstaller_path" ]]; then
        show_error "ErrorIdeviceinstallerNotFound"
        return
    fi

    local -a ipa_files=()
    for f in "$APPS_DIR"/*.ipa(N); do
        ipa_files+=("$f")
    done

    if [[ ${#ipa_files[@]} -eq 0 ]]; then
        show_error "ErrorNoApps"
        return
    fi

    local -a item_names=()
    local -a item_ids=()
    local -a item_paths=()

    for f in "${ipa_files[@]}"; do
        local meta
        meta=$(get_ipa_metadata "$f")
        IFS='|' read -r m_name m_ver m_minios <<< "$meta"
        local fname=$(basename "$f")
        item_names+=("$fname [${m_minios}+]")
        item_ids+=("$fname")
        item_paths+=("$f")
    done

    local -a sel_args=()
    local i
    for ((i=0; i<${#item_names[@]}; i++)); do
        sel_args+=("${item_names[$i]}" "${item_ids[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        return
    fi

    for idx in "${SELECTED_INDICES[@]}"; do
        local sel_path="${item_paths[$((idx-1))]}"
        local sel_name="${item_ids[$((idx-1))]}"
        separator
        echo "$(t InstallApp) $sel_name"
        cp "$sel_path" "$TEMP_IPA"
        "$ideviceinstaller_path" install "$TEMP_IPA"
        rm -f "$TEMP_IPA" 2>/dev/null
    done
}

# ============================================================
# ПРОВЕРКА ОБНОВЛЕНИЙ
# ============================================================

UPDATE_CHECKED=0

check_update() {
    # Получаем последнюю версию скрипта с GitHub:
    local remote_script
    remote_script=$(curl -sL "$SELF_UPDATE_URL" 2>/dev/null)

    if [[ -z "$remote_script" || ${#remote_script} -lt 100 ]]; then
        return
    fi

    # Извлекаем версию из удалённого скрипта:
    local remote_version
    remote_version=$(echo "$remote_script" | grep -m1 '^SCRIPT_VERSION=' | sed 's/SCRIPT_VERSION="//;s/"//')

    if [[ -z "$remote_version" ]]; then
        return
    fi

    local remote_ver
    remote_ver=$(echo "$remote_version" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
    local current_ver
    current_ver=$(echo "$SCRIPT_VERSION" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)

    if [[ -z "$remote_ver" || -z "$current_ver" ]]; then
        return
    fi

    # Сравнение версий:
    local newer=0
    local -a rv=(${(s:.:)remote_ver})
    local -a cv=(${(s:.:)current_ver})
    local j
    for ((j=0; j<${#rv[@]}; j++)); do
        local r=${rv[$j]:-0}
        local c=${cv[$j]:-0}
        if [[ $r -gt $c ]]; then
            newer=1
            break
        elif [[ $r -lt $c ]]; then
            break
        fi
    done

    if [[ $newer -eq 0 ]]; then
        return
    fi

    separator
    local update_title
    update_title=$(printf "$(t UpdateAvailableTitle)" "$remote_version")
    local choice
    choice=$(show_interactive_menu "$update_title" "" "$(t UpdateMenu1)" "$(t UpdateMenu2)")

    if [[ "$choice" != "1" ]]; then
        return
    fi

    separator
    echo "Обновление до версии $remote_version..."

    # Скачиваем новый скрипт во временный файл:
    local tmp_file="/tmp/ipadownloader_update_$$.sh"
    curl -sL "$SELF_UPDATE_URL" -o "$tmp_file" 2>/dev/null

    if [[ ! -f "$tmp_file" ]] || [[ $(wc -c < "$tmp_file") -lt 100 ]]; then
        echo "Ошибка загрузки обновления."
        rm -f "$tmp_file"
        press_any_key
        return
    fi

    # Заменяем текущий скрипт:
    local self_path
    self_path=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    cp "$tmp_file" "$self_path"
    chmod +x "$self_path"
    rm -f "$tmp_file"

    # Обновляем .command файл:
    local command_path
    command_path=$(cd "$(dirname "$0")" && pwd)/Start_IPA_Downloader.command
    curl -sL "$SELF_UPDATE_COMMAND_URL" -o "$command_path" 2>/dev/null
    chmod +x "$command_path" 2>/dev/null

    # Обновляем Windows скрипты (если есть):
    local ps1_path
    ps1_path=$(cd "$(dirname "$0")" && pwd)/IPA_Downloader.ps1
    curl -sL "$SELF_UPDATE_PS_URL" -o "$ps1_path" 2>/dev/null

    echo "[OK] Обновление установлено."
    echo "Перезапуск..."
    echo ""
    exec zsh "$self_path"
}

# ============================================================
# БАННЕР
# ============================================================

show_mode_banner() {
    local mode_label
    if [[ "$WORK_MODE" == "Installer" ]]; then
        mode_label="IPA_Installer"
    else
        mode_label="IPA_Downloader"
    fi
    separator
    echo "$mode_label $SCRIPT_VERSION ($ARCH_SUBFOLDER)"
}

# ============================================================
# МАСТЕР НАСТРОЙКИ
# ============================================================

setup_wizard() {
    # Очистка .ipatool:
    rm -rf "$IPATOOL_HOME"/* 2>/dev/null

    # Выбор языка:
    separator
    local lang_choice
    lang_choice=$(show_interactive_menu "$(t LanguageMenuTitle)" "" "$(t LanguageMenu1)" "$(t LanguageMenu2)")
    if [[ "$lang_choice" == "1" ]]; then
        CURRENT_LANG="RU"
    else
        CURRENT_LANG="EN"
    fi
    set_setting "Language" "$CURRENT_LANG"

    # Проверка обновлений:
    if [[ $UPDATE_CHECKED -eq 0 ]]; then
        check_update
        UPDATE_CHECKED=1
    fi

    # Выбор режима:
    separator
    local mode_choice
    mode_choice=$(show_interactive_menu "$(t ModeMenuTitle)" "" "$(t ModeMenu1)" "$(t ModeMenu2)")
    if [[ "$mode_choice" == "2" ]]; then
        WORK_MODE="Installer"
    else
        WORK_MODE="Downloader"
    fi

    if [[ "$WORK_MODE" == "Installer" ]]; then
        set_setting "Mode" "$WORK_MODE"
    fi

    # Версия ipatool:
    if [[ "$WORK_MODE" == "Downloader" ]]; then
        invoke_ipatool_version_prompt
    fi

    show_mode_banner
}

invoke_ipatool_version_prompt() {
    local v2_label="ipatool_$(get_arch_subfolder v2)"
    local v3_label="ipatool_$(get_arch_subfolder v3)"

    while true; do
        separator
        local choice
        choice=$(show_interactive_menu "$(t IpatoolVersionMenuTitle)" "" "$v2_label" "$v3_label")
        local selected_ver
        if [[ "$choice" == "2" ]]; then
            selected_ver="v3"
        else
            selected_ver="v2"
        fi

        local new_subfolder
        new_subfolder=$(get_arch_subfolder "$selected_ver")
        local new_binary_dir="$MAINAPP_DIR/$new_subfolder"
        local new_ipatool="$new_binary_dir/ipatool"

        if [[ ! -f "$new_ipatool" ]]; then
            separator
            echo "$(t ErrorMissingFiles)"
            echo "$new_ipatool"
            continue
        fi

        IPATOOL_VERSION="$selected_ver"
        ARCH_SUBFOLDER="$new_subfolder"
        BINARY_DIR="$new_binary_dir"
        IPATOOL_PATH="$new_ipatool"

        # Права на запуск:
        xattr -cr "$BINARY_DIR" 2>/dev/null
        chmod +x "$IPATOOL_PATH" 2>/dev/null

        return
    done
}

# ============================================================
# ДЕЙСТВИЕ С ПРИЛОЖЕНИЕМ
# ============================================================

invoke_app_action() {
    local appid="$1"
    local app_name="$2"
    local display_name="$3"
    local action="$4"  # Purchase | Download | DownloadVersion

    separator
    echo "$(t SelectedApp) $display_name"

    case "$action" in
        Purchase)
            separator
            "$IPATOOL_PATH" purchase -i "$appid"
            save_app_to_list "$appid" "$app_name" "Purchased"
            ;;
        Download)
            ipatool_download "$appid" "$app_name"
            ;;
        DownloadVersion)
            ipatool_download_with_version "$appid" "$app_name"
            ;;
    esac
}

# ============================================================
# ОЧИСТКА ДАННЫХ (для списков)
# ============================================================

clear_list_data() {
    local file_path="$1"
    local empty_key="$2"
    local cleared_key="$3"

    if [[ ! -f "$file_path" ]]; then
        separator
        echo "$(t $empty_key)"
        return
    fi

    local raw
    raw=$(json_read_file "$file_path")
    if [[ "$raw" == "null" || "$raw" == "{}" ]]; then
        rm -f "$file_path"
        separator
        echo "$(t $empty_key)"
        return
    fi

    local is_obj
    is_obj=$(python3 -c "
import json, sys
d = json.loads(sys.argv[1])
print('yes' if isinstance(d, dict) and len(d) > 0 else 'no')
" "$raw" 2>/dev/null)

    if [[ "$is_obj" != "yes" ]]; then
        rm -f "$file_path"
        separator
        echo "$(t $cleared_key)"
        return
    fi

    # Выбор аккаунта:
    local accounts_str
    accounts_str=$(json_get_keys "$raw")
    local -a accounts=()
    while IFS= read -r acc; do
        [[ -n "$acc" ]] && accounts+=("$acc")
    done <<< "$accounts_str"

    local -a acc_options=()
    local counter=1
    for acc in "${accounts[@]}"; do
        acc_options+=("$counter. $acc")
        ((counter++))
    done
    acc_options+=("$counter. $(t ClearAllAccounts)")

    separator
    local acc_choice
    acc_choice=$(show_interactive_menu "$(t ClearAccountMenuTitle)" "cancel" "${acc_options[@]}")

    if [[ "$acc_choice" == "0" ]]; then
        return
    fi

    if [[ "$acc_choice" -eq "$counter" ]]; then
        rm -f "$file_path"
        separator
        echo "$(t $cleared_key)"
    else
        local selected_acc="${accounts[$((acc_choice-1))]}"
        if [[ ${#accounts[@]} -le 1 ]]; then
            rm -f "$file_path"
        else
            local updated
            updated=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
del data[sys.argv[2]]
print(json.dumps(data, ensure_ascii=False, indent=2))
" "$raw" "$selected_acc" 2>/dev/null)
            json_write_file "$file_path" "$updated"
        fi
        separator
        printf "$(t AccountCleared)\n" "$selected_acc"
    fi
}

# ============================================================
# ОСНОВНОЙ РЕЖИМ DOWNLOADER
# ============================================================

invoke_downloader_mode() {
    # Проверка авторизации:
    if test_ipatool_auth; then
        separator
        echo "$(t AuthSuccess)"
        "$IPATOOL_PATH" auth info
        get_current_appleid
    fi

    connect_apple_id

    set_setting "Mode" "Downloader"
    set_setting "IpatoolVersion" "$IPATOOL_VERSION"

    local mode_label
    if [[ "$WORK_MODE" == "Installer" ]]; then
        mode_label="IPA_Installer"
    else
        mode_label="IPA_Downloader"
    fi
    MENU_HEADER="================================================\n${mode_label} ${SCRIPT_VERSION} (${ARCH_SUBFOLDER})\n================================================\n$(t AuthSuccess)\n${CURRENT_APPLEID}\n================================================"

    while test_ipatool_auth; do
        separator
        local -a menu_options=()
        local i
        for ((i=1; i<=21; i++)); do
            menu_options+=("$(t Menu${i})")
        done

        local choice
        choice=$(show_interactive_menu "$(t MenuTitle)" "" "${menu_options[@]}")

        case "$choice" in
            1)
                search_apps_menu
                if [[ ${#SELECTED_APP_IDS[@]} -gt 0 ]]; then
                    local i
                    for ((i=0; i<${#SELECTED_APP_IDS[@]}; i++)); do
                        invoke_app_action "${SELECTED_APP_IDS[$i]}" "${SELECTED_APP_NAMES[$i]}" "${SELECTED_APP_NAMES[$i]}" "Purchase"
                    done
                fi
                ;;
            2)
                search_apps_menu
                if [[ ${#SELECTED_APP_IDS[@]} -gt 0 ]]; then
                    local i
                    for ((i=0; i<${#SELECTED_APP_IDS[@]}; i++)); do
                        invoke_app_action "${SELECTED_APP_IDS[$i]}" "${SELECTED_APP_NAMES[$i]}" "${SELECTED_APP_NAMES[$i]}" "Download"
                    done
                fi
                ;;
            3)
                search_apps_menu
                if [[ ${#SELECTED_APP_IDS[@]} -gt 0 ]]; then
                    local i
                    for ((i=0; i<${#SELECTED_APP_IDS[@]}; i++)); do
                        invoke_app_action "${SELECTED_APP_IDS[$i]}" "${SELECTED_APP_NAMES[$i]}" "${SELECTED_APP_NAMES[$i]}" "DownloadVersion"
                    done
                fi
                ;;
            4)
                get_multiple_app_ids "AskIdPurchase"
                if [[ ${#MULTI_APP_IDS[@]} -gt 0 ]]; then
                    for id in "${MULTI_APP_IDS[@]}"; do
                        resolve_app_display_name "$id"
                        invoke_app_action "$id" "$FINAL_NAME" "$DISPLAY_NAME" "Purchase"
                    done
                fi
                ;;
            5)
                get_multiple_app_ids "AskIdDownload"
                if [[ ${#MULTI_APP_IDS[@]} -gt 0 ]]; then
                    for id in "${MULTI_APP_IDS[@]}"; do
                        resolve_app_display_name "$id"
                        invoke_app_action "$id" "$FINAL_NAME" "$DISPLAY_NAME" "Download"
                    done
                fi
                ;;
            6)
                get_multiple_app_ids "AskIdSearch"
                if [[ ${#MULTI_APP_IDS[@]} -gt 0 ]]; then
                    for id in "${MULTI_APP_IDS[@]}"; do
                        resolve_app_display_name "$id"
                        invoke_app_action "$id" "$FINAL_NAME" "$DISPLAY_NAME" "DownloadVersion"
                    done
                fi
                ;;
            7)
                get_apps_from_list "Purchase"
                if [[ ${#APPS_FROM_LIST[@]} -gt 0 ]]; then
                    for entry in "${APPS_FROM_LIST[@]}"; do
                        IFS='|' read -r name id <<< "$entry"
                        invoke_app_action "$id" "$name" "$name" "Purchase"
                    done
                fi
                ;;
            8)
                get_apps_from_list "Download"
                if [[ ${#APPS_FROM_LIST[@]} -gt 0 ]]; then
                    for entry in "${APPS_FROM_LIST[@]}"; do
                        IFS='|' read -r name id <<< "$entry"
                        invoke_app_action "$id" "$name" "$name" "Download"
                    done
                fi
                ;;
            9)
                get_apps_from_list "Download"
                if [[ ${#APPS_FROM_LIST[@]} -gt 0 ]]; then
                    for entry in "${APPS_FROM_LIST[@]}"; do
                        IFS='|' read -r name id <<< "$entry"
                        invoke_app_action "$id" "$name" "$name" "DownloadVersion"
                    done
                fi
                ;;
            10)
                get_ios_min_version
                press_any_key
                ;;
            11)
                invoke_install_apps
                press_any_key
                ;;
            12)
                bulk_download_all "Download"
                press_any_key
                ;;
            13)
                bulk_download_all "DownloadVersion"
                press_any_key
                ;;
            14)
                bulk_download_all "Purchase"
                press_any_key
                ;;
            15)
                download_banks "Download"
                press_any_key
                ;;
            16)
                download_banks "DownloadVersion"
                press_any_key
                ;;
            17)
                download_banks "Purchase"
                press_any_key
                ;;
            18)
                clear_data_menu
                ;;
            19)
                separator
                echo "$(t LoggedOut)"
                "$IPATOOL_PATH" auth revoke
                rm -f "$SETTINGS_FILE"
                WORK_MODE=""
                return
                ;;
            20)
                open "$REPO_URL#поддержка-проекта"
                ;;
            21)
                if [[ "$CURRENT_LANG" == "RU" ]]; then
                    CURRENT_LANG="EN"
                else
                    CURRENT_LANG="RU"
                fi
                load_lang "$CURRENT_LANG"
                set_setting "Language" "$CURRENT_LANG"
                separator
                echo "$(t LangChanged)"
                press_any_key
                ;;
        esac
    done
}

# ============================================================
# ОЧИСТКА ДАННЫХ (меню)
# ============================================================

clear_data_menu() {
    separator
    local choice
    choice=$(show_interactive_menu "$(t ClearMenuTitle)" "cancel" "$(t ClearMenu1)" "$(t ClearMenu2)" "$(t ClearMenu3)")

    case "$choice" in
        1) clear_list_data "$PURCHASED_FILE" "ErrorPurchasedEmpty" "PurchasedListCleared" ;;
        2) clear_list_data "$DOWNLOADED_FILE" "ErrorDownloadedEmpty" "DownloadedListCleared" ;;
        3)
            local -a ipa_files=()
            for f in "$APPS_DIR"/*.ipa(N); do
                ipa_files+=("$f")
            done
            if [[ ${#ipa_files[@]} -gt 0 ]]; then
                rm -f "$APPS_DIR"/*.ipa
                separator
                echo "$(t AppsCleared)"
            else
                show_error "ErrorNoApps"
            fi
            ;;
    esac
}

# ============================================================
# ПАКЕТНАЯ ЗАГРУЗКА
# ============================================================

bulk_download_all() {
    local action="$1"

    initialize_github_list
    if [[ ${#GITHUB_IDS[@]} -eq 0 ]]; then
        show_error "ErrorListLoadError"
        return
    fi

    local -a sel_args=()
    local i
    for ((i=0; i<${#GITHUB_NAMES[@]}; i++)); do
        sel_args+=("${GITHUB_NAMES[$i]}" "${GITHUB_IDS[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        show_error "NothingSelected"
        return
    fi

    local -a sel_names=()
    local -a sel_ids=()
    for idx in "${SELECTED_INDICES[@]}"; do
        sel_names+=("${GITHUB_NAMES[$((idx-1))]}")
        sel_ids+=("${GITHUB_IDS[$((idx-1))]}")
    done

    local total=${#sel_ids[@]}
    local action_label
    case "$action" in
        Purchase)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Покупка"; else action_label="Purchase"; fi
            ;;
        Download)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Загрузка"; else action_label="Download"; fi
            ;;
        DownloadVersion)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Загрузка (выбор версии)"; else action_label="Download (version select)"; fi
            ;;
    esac

    local counter=0
    for ((i=0; i<total; i++)); do
        ((counter++))
        separator
        printf "$(t BulkDownloadProgress)\n" "$counter" "$total" "${sel_names[$i]}" "${sel_ids[$i]}"
        echo "[$action_label] ${sel_names[$i]} (ID: ${sel_ids[$i]})"

        # Проверка на скачано/куплено:
        local skip=0
        if [[ "$action" == "Purchase" ]]; then
            if [[ -f "$PURCHASED_FILE" ]]; then
                local pdata
                pdata=$(read_app_list_json "$PURCHASED_FILE" "")
                if [[ -n "$pdata" ]]; then
                    local dup
                    dup=$(json_array_contains_appid "$pdata" "${sel_ids[$i]}")
                    if [[ "$dup" == "yes" ]]; then
                        printf "$(t AlreadyDownloaded)\n" "${sel_names[$i]}"
                        skip=1
                    fi
                fi
            fi
        else
            if ls "$APPS_DIR"/*"${sel_names[$i]}"* 2>/dev/null | head -1 > /dev/null; then
                printf "$(t AlreadyDownloaded)\n" "${sel_names[$i]}"
                skip=1
            fi
        fi

        if [[ $skip -eq 1 ]]; then continue; fi

        case "$action" in
            Purchase)
                "$IPATOOL_PATH" purchase -i "${sel_ids[$i]}"
                save_app_to_list "${sel_ids[$i]}" "${sel_names[$i]}" "Purchased"
                ;;
            Download)
                "$IPATOOL_PATH" download -i "${sel_ids[$i]}" --purchase
                move_ipa_files "${sel_ids[$i]}" "${sel_names[$i]}"
                ;;
            DownloadVersion)
                ipatool_download_with_version "${sel_ids[$i]}" "${sel_names[$i]}"
                ;;
        esac
    done

    separator
    printf "$(t BulkDownloadComplete)\n" "$total"
}

# ============================================================
# ЗАГРУЗКА БАНКОВСКИХ ПРИЛОЖЕНИЙ
# ============================================================

download_banks() {
    local action="$1"

    local banks_file="$LISTS_DIR/Banks_ID_List.txt"
    if [[ ! -f "$banks_file" ]]; then
        show_error "ErrorListLoadError"
        return
    fi

    local -a bank_names=()
    local -a bank_ids=()

    while IFS= read -r line; do
        if [[ "$line" =~ ^(.+):\ *([0-9]+)$ ]]; then
            bank_names+=("${match[1]}")
            bank_ids+=("${match[2]}")
        fi
    done < "$banks_file"

    if [[ ${#bank_ids[@]} -eq 0 ]]; then
        show_error "ErrorListLoadError"
        return
    fi

    separator
    printf "$(t BanksListLoaded)\n" "${#bank_ids[@]}"

    local -a sel_args=()
    local i
    for ((i=0; i<${#bank_names[@]}; i++)); do
        sel_args+=("${bank_names[$i]}" "${bank_ids[$i]}")
    done

    show_paginated_selection "${sel_args[@]}"

    if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
        show_error "NothingSelected"
        return
    fi

    local -a sel_names=()
    local -a sel_ids=()
    for idx in "${SELECTED_INDICES[@]}"; do
        sel_names+=("${bank_names[$((idx-1))]}")
        sel_ids+=("${bank_ids[$((idx-1))]}")
    done

    local total=${#sel_ids[@]}
    local action_label
    case "$action" in
        Purchase)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Покупка"; else action_label="Purchase"; fi
            ;;
        Download)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Загрузка"; else action_label="Download"; fi
            ;;
        DownloadVersion)
            if [[ "$CURRENT_LANG" == "RU" ]]; then action_label="Загрузка (выбор версии)"; else action_label="Download (version select)"; fi
            ;;
    esac

    local counter=0
    for ((i=0; i<total; i++)); do
        ((counter++))
        separator
        printf "$(t BulkDownloadProgress)\n" "$counter" "$total" "${sel_names[$i]}" "${sel_ids[$i]}"
        echo "[$action_label] ${sel_names[$i]} (ID: ${sel_ids[$i]})"

        local skip=0
        if [[ "$action" == "Purchase" ]]; then
            if [[ -f "$PURCHASED_FILE" ]]; then
                local pdata
                pdata=$(read_app_list_json "$PURCHASED_FILE" "")
                if [[ -n "$pdata" ]]; then
                    local dup
                    dup=$(json_array_contains_appid "$pdata" "${sel_ids[$i]}")
                    if [[ "$dup" == "yes" ]]; then
                        printf "$(t AlreadyDownloaded)\n" "${sel_names[$i]}"
                        skip=1
                    fi
                fi
            fi
        else
            if ls "$APPS_DIR"/*"${sel_names[$i]}"* 2>/dev/null | head -1 > /dev/null; then
                printf "$(t AlreadyDownloaded)\n" "${sel_names[$i]}"
                skip=1
            fi
        fi

        if [[ $skip -eq 1 ]]; then continue; fi

        case "$action" in
            Purchase)
                "$IPATOOL_PATH" purchase -i "${sel_ids[$i]}"
                save_app_to_list "${sel_ids[$i]}" "${sel_names[$i]}" "Purchased"
                ;;
            Download)
                "$IPATOOL_PATH" download -i "${sel_ids[$i]}" --purchase
                move_ipa_files "${sel_ids[$i]}" "${sel_names[$i]}"
                ;;
            DownloadVersion)
                ipatool_download_with_version "${sel_ids[$i]}" "${sel_names[$i]}"
                ;;
        esac
    done

    separator
    printf "$(t BulkDownloadComplete)\n" "$total"
}

# ============================================================
# РЕЖИМ INSTALLER
# ============================================================

invoke_installer_mode() {
    while true; do
        separator
        local -a installer_options=(
            "$(t InstallerMenu1)"
            "$(t InstallerMenu2)"
            "$(t InstallerMenu3)"
            "$(t InstallerMenu4)"
            "$(t InstallerMenu5)"
            "$(t InstallerMenu6)"
        )
        local choice
        choice=$(show_interactive_menu "$(t MenuTitle)" "" "${installer_options[@]}")

        case "$choice" in
            1)
                get_ios_min_version
                press_any_key
                ;;
            2)
                invoke_install_apps
                press_any_key
                ;;
            3)
                open "$REPO_URL#поддержка-проекта"
                ;;
            4)
                if [[ "$CURRENT_LANG" == "RU" ]]; then
                    CURRENT_LANG="EN"
                else
                    CURRENT_LANG="RU"
                fi
                load_lang "$CURRENT_LANG"
                set_setting "Language" "$CURRENT_LANG"
                separator
                echo "$(t LangChanged)"
                press_any_key
                ;;
            5)
                rm -f "$SETTINGS_FILE"
                WORK_MODE=""
                return
                ;;
            6)
                invoke_ipatool_version_prompt
                WORK_MODE="Downloader"
                return
                ;;
        esac
    done
}

# ============================================================
# ГЛАВНЫЙ ЦИКЛ
# ============================================================

# ============================================================
# АВТОУСТАНОВКА ЗАВИСИМОСТЕЙ
# ============================================================

install_dependencies() {
    local needs_brew=0
    local needs_python=0
    local needs_ipatool=0
    local needs_idevice=0
    local changes_made=0

    separator
    echo "Проверка зависимостей..."

    # --- Homebrew ---
    if ! which brew > /dev/null 2>&1; then
        echo "[!] Homebrew не найден."
        echo ""
        echo "Homebrew необходим для установки зависимостей."
        echo -n "Установить Homebrew? (Y/n): "
        read -r answer
        if [[ "$answer" == "n" || "$answer" == "N" ]]; then
            echo "Установка Homebrew пропущена."
            echo "Некоторые зависимости могут быть недоступны."
        else
            echo ""
            echo "Установка Homebrew..."
            echo "Это может занять несколько минут."
            echo ""
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Добавляем brew в PATH для текущей сессии:
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi

            if which brew > /dev/null 2>&1; then
                echo "[OK] Homebrew установлен."
                changes_made=1
            else
                echo "[!] Не удалось установить Homebrew."
                echo "    Установите вручную: https://brew.sh"
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
            fi
        fi
    else
        echo "[OK] Homebrew: $(brew --version | head -1)"
    fi

    # Если brew доступен — проверяем остальные зависимости:
    if which brew > /dev/null 2>&1; then

        # --- Python 3 ---
        if ! which python3 > /dev/null 2>&1; then
            echo ""
            echo "[!] Python 3 не найден."
            echo -n "Установить Python 3 через Homebrew? (Y/n): "
            read -r answer
            if [[ "$answer" != "n" && "$answer" != "N" ]]; then
                echo "Установка python3..."
                brew install python3
                if which python3 > /dev/null 2>&1; then
                    echo "[OK] Python 3 установлен: $(python3 --version)"
                    changes_made=1
                else
                    echo "[!] Не удалось установить Python 3."
                fi
            fi
        else
            echo "[OK] Python 3: $(python3 --version)"
        fi

        # --- curl ---
        if ! which curl > /dev/null 2>&1; then
            echo ""
            echo "[!] curl не найден."
            echo -n "Установить curl через Homebrew? (Y/n): "
            read -r answer
            if [[ "$answer" != "n" && "$answer" != "N" ]]; then
                echo "Установка curl..."
                brew install curl
                if which curl > /dev/null 2>&1; then
                    echo "[OK] curl установлен."
                    changes_made=1
                fi
            fi
        else
            echo "[OK] curl: $(curl --version | head -1 | awk '{print $2}')"
        fi

        # --- ipatool ---
        # Проверяем сначала в локальной папке, потом в системе:
        update_paths
        if [[ ! -f "$IPATOOL_PATH" ]] && ! which ipatool > /dev/null 2>&1; then
            echo ""
            echo "[!] ipatool не найден."
            echo -n "Установить ipatool через Homebrew? (Y/n): "
            read -r answer
            if [[ "$answer" != "n" && "$answer" != "N" ]]; then
                echo "Установка ipatool..."
                brew install ipatool
                if which ipatool > /dev/null 2>&1; then
                    echo "[OK] ipatool установлен: $(ipatool --version 2>&1 | head -1)"
                    changes_made=1
                    # Копируем в локальную папку для использования скриптом:
                    mkdir -p "$BINARY_DIR"
                    local sys_ipatool
                    sys_ipatool=$(which ipatool)
                    cp "$sys_ipatool" "$IPATOOL_PATH" 2>/dev/null
                    chmod +x "$IPATOOL_PATH" 2>/dev/null
                else
                    echo "[!] Не удалось установить ipatool."
                    echo "    Скачайте вручную: https://github.com/majd/ipatool/releases"
                fi
            fi
        elif [[ -f "$IPATOOL_PATH" ]]; then
            echo "[OK] ipatool: $IPATOOL_PATH"
        else
            echo "[OK] ipatool: $(which ipatool)"
        fi

        # --- ideviceinstaller ---
        if ! which ideviceinstaller > /dev/null 2>&1; then
            echo ""
            echo "[!] ideviceinstaller не найден."
            echo "    Необходим для установки IPA на iOS-устройства."
            echo -n "Установить libimobiledevice через Homebrew? (Y/n): "
            read -r answer
            if [[ "$answer" != "n" && "$answer" != "N" ]]; then
                echo "Установка libimobiledevice..."
                brew install libimobiledevice
                if which ideviceinstaller > /dev/null 2>&1; then
                    echo "[OK] ideviceinstaller установлен."
                    changes_made=1
                else
                    echo "[!] Не удалось установить ideviceinstaller."
                    echo "    Установка IPA на устройства будет недоступна."
                    echo "    Попробуйте: brew install libimobiledevice --HEAD"
                fi
            fi
        else
            echo "[OK] ideviceinstaller: $(which ideviceinstaller)"
        fi
    fi

    separator
    if [[ $changes_made -eq 1 ]]; then
        echo "Зависимости установлены."
    else
        echo "Все зависимости в порядке."
    fi
    separator
    echo ""
}

main() {
    # Создание базовых папок:
    mkdir -p "$APPS_DIR" "$LISTS_DIR" "$MAINAPP_DIR" "$IPATOOL_HOME"

    # Удаление временных файлов:
    rm -f ./*.ipa.tmp 2>/dev/null
    rm -f "$APPS_ID_TMP" 2>/dev/null

    # Информация о системе:
    separator
    echo "macOS $(sw_vers -productVersion) ($(uname -m))"
    echo "zsh $ZSH_VERSION"

    # Загрузка настроек:
    load_settings
    load_lang "$CURRENT_LANG"
    update_paths

    # Автоустановка зависимостей при первом запуске:
    local deps_file="$MAINAPP_DIR/.deps_installed"
    if [[ ! -f "$deps_file" ]]; then
        install_dependencies
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$deps_file"
    fi

    while true; do
        if [[ -z "$WORK_MODE" ]]; then
            setup_wizard
        else
            if [[ $UPDATE_CHECKED -eq 0 ]]; then
                check_update
                UPDATE_CHECKED=1
            fi
            show_mode_banner
        fi

        update_paths

        # Проверка ipatool:
        if [[ ! -f "$IPATOOL_PATH" ]]; then
            # Если нет в локальной папке, пробуем системный:
            if which ipatool > /dev/null 2>&1; then
                local sys_ipatool
                sys_ipatool=$(which ipatool)
                mkdir -p "$BINARY_DIR"
                cp "$sys_ipatool" "$IPATOOL_PATH" 2>/dev/null
                chmod +x "$IPATOOL_PATH" 2>/dev/null
            fi
        fi

        if [[ ! -f "$IPATOOL_PATH" ]]; then
            separator
            echo "$(t ErrorMissingFiles)"
            echo "$IPATOOL_PATH"
            echo ""
            echo "Установите ipatool:"
            echo "  brew install ipatool"
            echo "или скачайте: https://github.com/majd/ipatool/releases"
            press_any_key
            # Сбрасываем флаг чтобы повторить проверку зависимостей:
            rm -f "$deps_file"
            WORK_MODE=""
            continue
        fi

        # Права на запуск:
        xattr -cr "$BINARY_DIR" 2>/dev/null
        chmod +x "$IPATOOL_PATH" 2>/dev/null

        # Проверка ideviceinstaller:
        if ! which ideviceinstaller > /dev/null 2>&1; then
            echo "$(t ErrorIdeviceinstallerNotFound)"
            echo "  brew install libimobiledevice"
        fi

        if [[ "$WORK_MODE" == "Installer" ]]; then
            invoke_installer_mode
        else
            invoke_downloader_mode
        fi
    done
}

# Запуск:
main
