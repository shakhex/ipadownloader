# Глобальный перехват всех необработанных ошибок:
trap {
	Write-Host ""
	Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor DarkRed
	if ($_.Exception.InnerException) {
		Write-Host "Подробности: $($_.Exception.InnerException.Message)" -ForegroundColor DarkYellow
	}
	Read-Host "Нажмите Enter для продолжения..."
	continue
}

# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Версия скрипта:
$ScriptVersion = "4.0b (t.me/shakhex edit)"

# GitHub репозиторий:
$RepoUrl = "https://github.com/shakhex/ipadownloader"
$RawBase = "https://raw.githubusercontent.com/shakhex/ipadownloader/main"
$SelfUpdateUrl = "$RawBase/IPA_Downloader.ps1"
$AppsListUrl = "$RawBase/Lists/Apps_ID_List.txt"
$CommitApiUrl = "https://api.github.com/repos/shakhex/ipadownloader/commits/main"

# Папка MainApp и единый файл настроек (язык, режим работы, версия ipatool):
$MainAppFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "MainApp"
$SettingsFilePath = Join-Path -Path $MainAppFolderPath -ChildPath "Settings.txt"

# Функция чтения всех настроек из Settings.txt:
function Get-Settings {
	$Settings = @{}
	if (Test-Path $SettingsFilePath) {
		Get-Content $SettingsFilePath -ErrorAction SilentlyContinue | ForEach-Object {
			if ($_ -match '^\s*([^=]+?)\s*=\s*(.*)$') {
				$Settings[$Matches[1]] = $Matches[2].Trim()
			}
		}
	}
	return $Settings
}

# Функция сохранения одной настройки:
function Set-Setting {
	param ([string]$Key, [string]$Value)
	$Settings = Get-Settings
	$Settings[$Key] = $Value
	$Lines = foreach ($K in $Settings.Keys) { "$K=$($Settings[$K])" }
	Set-Content -Path $SettingsFilePath -Value $Lines -Force
}

# Загрузка сохраненных настроек (язык, режим работы, версия ipatool) или значений по умолчанию:
$SavedSettings = Get-Settings
$Global:CurrentLang = if ($SavedSettings['Language'] -match '^(RU|EN)$') { $SavedSettings['Language'] } else { "RU" }
$Global:WorkMode = if ($SavedSettings['Mode'] -in @('Downloader', 'Installer')) { $SavedSettings['Mode'] } else { $null }
$IpatoolVersion = if ($SavedSettings['IpatoolVersion'] -eq 'v3') { 'v3' } else { 'v2' }

# Функция вычисления имени папки с ipatool:
function Get-ArchSubFolder {
	param ([ValidateSet("v2", "v3")][string]$Version)
	if ($Version -eq "v3") { return "windows_amd64_v3" } else { return "windows_amd64_v2" }
}

# Определение системы и архитектуры:
$ArchSubFolder = Get-ArchSubFolder -Version $IpatoolVersion

# Определение основных папок и переменных:
$OSVersion = [System.Environment]::OSVersion
$WindowsVersion = [System.Environment]::OSVersion.Version
$PSVersion = $PSVersionTable.PSVersion.ToString()
$BinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $ArchSubFolder
$ListsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Lists"
$DownloadedIDsFilePath = Join-Path -Path $ListsFolderPath -ChildPath "Downloaded_IDs.json"
$PurchasedIDsFilePath = Join-Path -Path $ListsFolderPath -ChildPath "Purchased_IDs.json"
$AppsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Apps"
$ipatoolHomePath = Join-Path -Path $HOME -ChildPath ".ipatool"
$AccountFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "account"
$CookiesFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "cookies"
$TempFolderPath = [System.IO.Path]::GetTempPath()
$TempIpaFilePath = Join-Path -Path $TempFolderPath -ChildPath "Temp.ipa"
$AppsIDListPath = Join-Path -Path $ListsFolderPath -ChildPath "Apps_ID_List.txt"
$AppsIDTempListPath = Join-Path -Path $MainAppFolderPath -ChildPath "Apps_ID_List_tmp.txt"

# Настройка консоли:
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ConsoleFont {
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct CONSOLE_FONT_INFO_EX {
		public uint cbSize;
		public uint nFont;
		public short dwFontSizeX;
		public short dwFontSizeY;
		public int FontFamily;
		public int FontWeight;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
		public string FaceName;
	}
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr GetStdHandle(int nStdHandle);
	public static void SetFont(string fontName, short fontSize = 12) {
		IntPtr hConsole = GetStdHandle(-11); // STD_OUTPUT_HANDLE
		CONSOLE_FONT_INFO_EX fontInfo = new CONSOLE_FONT_INFO_EX();
		fontInfo.cbSize = (uint)Marshal.SizeOf(fontInfo);
		fontInfo.FaceName = fontName;
		fontInfo.dwFontSizeY = fontSize;
		SetCurrentConsoleFontEx(hConsole, false, ref fontInfo);
	}
}
"@

[ConsoleFont]::SetFont("Consolas", 16)
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# Подключение системных сборок для работы с Zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Глобальная переменная для кэширования структурированного списка с GitHub:
$Global:GitHubParsedList = $null

# Перевод текста:
$LangStrings = @{
	"RU" = @{
		"AccountCleared" = "Готово. Данные аккаунта {0} удалены."
		"AddedToDownloadedList" = "Добавлено в список: {0} - {1}"
		"AddedToPurchasedList" = "Добавлено в список покупок: {0} - {1}"
		"AlreadyInList" = "Уже есть в списке: {0} - {1}"
		"AppsCleared" = "Готово. Приложения в папке Apps удалены."
		"AskAppNum" = "Введите номера приложений"
		"AskIdDownload" = "Введите ID приложения для загрузки"
		"AskIdSearch" = "Введите ID приложения для поиска"
		"AskIdPurchase" = "Введите ID приложения для покупки"
		"AskSearch" = "Введите название приложения для поиска"
		"AskVerCount" = "Введите количество версий для отображения"
		"AskVerNum" = "Введите номера версий для загрузки"
		"AuthFail" = "Вход в Apple ID не выполнен."
		"AuthSuccess" = "Вход в Apple ID выполнен.`nДанные аккаунта:"
		"CancelStep" = "(0: Отмена/Возврат в главное меню)"
		"ClearAccountMenuTitle" = "Выберите аккаунты для очистки:"
		"ClearAllAccounts" = "Все аккаунты"
		"ClearMenu1" = "Список приобретенных приложений"
		"ClearMenu2" = "Список загруженных приложений"
		"ClearMenu3" = "Приложения в папке Apps"
		"ClearMenuTitle" = "Выберите данные для очистки:"
		"DownloadedListCleared" = "Готово. Список загруженных приложений очищен."
		"DownloadedListMenu1" = "Полный список приложений (GitHub)"
		"DownloadedListMenu2" = "Список загруженных приложений"
		"DownloadedListMenu3" = "Список не загруженных приложений"
		"ErrorDownloadedEmpty" = "Ошибка: История загрузок пуста."
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorListLoadError" = "Ошибка загрузки списка приложений."
		"ErrorMissingFiles" = "Ошибка. Следующие файлы не найдены:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"ErrorNoAppsFound" = "Ошибка: Приложения не найдены."
		"ErrorPurchasedEmpty" = "Ошибка: История покупок пуста."
		"ErrorUpdateCheck" = "Ошибка: Не удалось проверить наличие обновлений."
		"FileName" = "Имя файла:"
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"HeaderFileName" = "Имя файла"
		"HeaderMinIOS" = "Мин. iOS"
		"HeaderVerID" = "ID версии"
		"HeaderVersion" = "Версия"
		"InstallApp" = "Установка:"
		"InstallerMenu1" = "Проверка минимальной версии iOS для приложений в папке Apps"
		"InstallerMenu2" = "Установка приложений из папки Apps"
		"InstallerMenu3" = "Поддержка проекта"
		"InstallerMenu4" = "Сменить язык (Change Language)"
		"InstallerMenu5" = "Сброс настроек"
		"InstallerMenu6" = "Перейти в Загрузчик IPA"
		"IpatoolVersionMenuTitle" = "Выберите версию ipatool:"
		"LangChanged" = "Язык успешно изменен на Русский."
		"LanguageMenu1" = "Русский"
		"LanguageMenu2" = "English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"ListMenuTitle" = "Выберите список для отображения:"
		"LoggedOut" = "Выполнен выход из Apple ID."
		"Menu1" = "Поиск приложения"
		"Menu2" = "Поиск по ID"
		"Menu3" = "Список приложений"
		"Menu4" = "Банковские приложения"
		"Menu5" = "Проверка минимальной версии iOS"
		"Menu6" = "Установка приложений из папки Apps"
		"MenuTitle" = "Выберите пункт:"
		"ActionMenuTitle" = "Выберите действие:"
		"ActionPurchase" = "Покупка (без загрузки)"
		"ActionDownload" = "Загрузка последней версии"
		"ActionDownloadVer" = "Загрузка (с выбором версии)"
		"MinIOS" = "Минимальная версия iOS:"
		"ModeMenu1" = "Загрузчик IPA"
		"ModeMenu2" = "Установщик IPA"
		"ModeMenuTitle" = "Выберите режим работы:"
		"PurchasedListCleared" = "Готово. Список приобретенных приложений очищен."
		"PurchasedListMenu1" = "Полный список приложений (GitHub)"
		"PurchasedListMenu2" = "Список приобретенных приложений"
		"PurchasedListMenu3" = "Список не приобретенных приложений"
		"SelectedApp" = "Выбрано приложение:"
		"SelectedVer" = "Выбрана версия:"
		"UpdateAvailableTitle" = "Доступно обновление (версия {0}). Перейти на страницу GitHub для загрузки?"
		"UpdateMenu1" = "Да"
		"UpdateMenu2" = "Нет"
		"Menu7" = "Очистка данных"
		"Menu8" = "Выход из Apple ID + сброс настроек"
		"Menu9" = "Поддержка проекта"
		"Menu10" = "Сменить язык (Change Language)"
		"BulkDownloadProgress" = "[{0}/{1}] {2} (ID: {3})"
		"BulkDownloadComplete" = "Готово. Обработано приложений: {0}"
		"ConfirmBulkDownload" = "Будет обработано {0} приложений. Продолжить?"
		"AlreadyDownloaded" = "Уже скачано, пропускаю: {0}"
		"BanksListLoaded" = "Загружено банковских приложений: {0}"
		"PageHeader" = "Страница {0}/{1}"
		"PageNext" = "N: следующая"
		"PagePrev" = "P: предыдущая"
		"PageSelectAll" = "A: выбрать стр"
		"PageDeselectAll" = "D: снять стр"
		"PageDone" = "0: завершить выбор"
		"PagePrompt" = "Введите номера"
		"SelectedCount" = "Выбрано: {0}"
		"NothingSelected" = "Ничего не выбрано."
		"MarkSelected" = "[x]"
		"MarkEmpty" = "[ ]"
		"HelpNavigate" = "Up/Down: навигация"
		"HelpToggle" = "Space: выбор"
		"HelpConfirm" = "Enter: подтвердить"
		"HelpCancel" = "Esc: отмена"
		"HelpPages" = "Left/Right: страницы"
		"HelpPageSelect" = "A/D: выбрать/снять стр"
		"HelpMenuNav" = "Up/Down: навигация | Enter: выбор"
		"HelpMenuNavCancel" = "Up/Down: навигация | Enter: выбор | Esc: отмена"
		"ModeLabelDownloader" = "Загрузчик IPA"
		"ModeLabelInstaller" = "Установщик IPA"
		"PressEnterToContinue" = "Нажмите Enter для продолжения..."
	}
	"EN" = @{
		"AccountCleared" = "Done. Account {0} data cleared."
		"AddedToDownloadedList" = "Added to list: {0} - {1}"
		"AddedToPurchasedList" = "Added to purchased list: {0} - {1}"
		"AlreadyInList" = "Already in list: {0} - {1}"
		"AppsCleared" = "Done. Apps folder has been cleared."
		"AskAppNum" = "Enter app index numbers"
		"AskIdDownload" = "Enter app IDs to download"
		"AskIdSearch" = "Enter app IDs to search"
		"AskIdPurchase" = "Enter app IDs to purchase"
		"AskSearch" = "Enter app name to search"
		"AskVerCount" = "Enter number of versions to display"
		"AskVerNum" = "Enter version numbers to download"
		"AuthFail" = "Not authenticated with Apple ID."
		"AuthSuccess" = "Apple ID login successful.`nAccount details:"
		"CancelStep" = "(0: Cancel/Return to main menu)"
		"ClearAccountMenuTitle" = "Select accounts to clear:"
		"ClearAllAccounts" = "All accounts"
		"ClearMenu1" = "Purchased apps list"
		"ClearMenu2" = "Downloaded apps list"
		"ClearMenu3" = "Apps in Apps folder"
		"ClearMenuTitle" = "Select data to clear:"
		"DownloadedListCleared" = "Done. Downloaded apps list cleared."
		"DownloadedListMenu1" = "Full apps list (GitHub)"
		"DownloadedListMenu2" = "Downloaded apps list"
		"DownloadedListMenu3" = "Not downloaded apps list"
		"ErrorDownloadedEmpty" = "Error: Download history is empty."
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorListLoadError" = "Failed to load apps list."
		"ErrorMissingFiles" = "Error. Following files were not found:"
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"ErrorNoAppsFound" = "Error: No apps found."
		"ErrorPurchasedEmpty" = "Error: Purchase history is empty."
		"ErrorUpdateCheck" = "Error: Failed to check for updates."
		"FileName" = "File name:"
		"FileSaved" = "Done. File saved to Apps folder."
		"HeaderFileName" = "File name"
		"HeaderMinIOS" = "Min. iOS"
		"HeaderVerID" = "Version ID"
		"HeaderVersion" = "Version"
		"InstallApp" = "Installing:"
		"InstallerMenu1" = "Check minimum iOS version for apps in Apps folder"
		"InstallerMenu2" = "Install apps from Apps folder"
		"InstallerMenu3" = "Project support"
		"InstallerMenu4" = "Change Language (Сменить язык)"
		"InstallerMenu5" = "Reset settings"
		"InstallerMenu6" = "Switch to IPA Downloader"
		"IpatoolVersionMenuTitle" = "Select ipatool version:"
		"LangChanged" = "Language successfully changed to English."
		"LanguageMenu1" = "Русский"
		"LanguageMenu2" = "English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"ListMenuTitle" = "Select list to display:"
		"LoggedOut" = "Successfully logged out of Apple ID."
		"Menu1" = "Search for app"
		"Menu2" = "Search by ID"
		"Menu3" = "Apps list"
		"Menu4" = "Bank apps"
		"Menu5" = "Check minimum iOS version"
		"Menu6" = "Install apps from Apps folder"
		"MenuTitle" = "Select an option:"
		"ActionMenuTitle" = "Select action:"
		"ActionPurchase" = "Purchase (without downloading)"
		"ActionDownload" = "Download latest version"
		"ActionDownloadVer" = "Download (with version selection)"
		"MinIOS" = "Minimum iOS version:"
		"ModeMenu1" = "IPA Downloader"
		"ModeMenu2" = "IPA Installer"
		"ModeMenuTitle" = "Select operating mode:"
		"PurchasedListCleared" = "Done. Purchased apps list cleared."
		"PurchasedListMenu1" = "Full apps list (GitHub)"
		"PurchasedListMenu2" = "Purchased apps list"
		"PurchasedListMenu3" = "Not purchased apps list"
		"SelectedApp" = "Selected app:"
		"SelectedVer" = "Selected version:"
		"UpdateAvailableTitle" = "Update available (version {0}). Go to GitHub page to download?"
		"UpdateMenu1" = "Yes"
		"UpdateMenu2" = "No"
		"Menu7" = "Clear data"
		"Menu8" = "Log out of Apple ID + reset settings"
		"Menu9" = "Project support"
		"Menu10" = "Change Language (Сменить язык)"
		"BulkDownloadProgress" = "[{0}/{1}] {2} (ID: {3})"
		"BulkDownloadComplete" = "Done. Apps processed: {0}"
		"ConfirmBulkDownload" = "{0} apps will be processed. Continue?"
		"AlreadyDownloaded" = "Already downloaded, skipping: {0}"
		"BanksListLoaded" = "Bank apps loaded: {0}"
		"PageHeader" = "Page {0}/{1}"
		"PageNext" = "N: next page"
		"PagePrev" = "P: prev page"
		"PageSelectAll" = "A: select page"
		"PageDeselectAll" = "D: deselect page"
		"PageDone" = "0: finish selection"
		"PagePrompt" = "Enter numbers"
		"SelectedCount" = "Selected: {0}"
		"NothingSelected" = "Nothing selected."
		"MarkSelected" = "[x]"
		"MarkEmpty" = "[ ]"
		"HelpNavigate" = "Up/Down: navigate"
		"HelpToggle" = "Space: toggle"
		"HelpConfirm" = "Enter: confirm"
		"HelpCancel" = "Esc: cancel"
		"HelpPages" = "Left/Right: pages"
		"HelpPageSelect" = "A/D: select/deselect page"
		"HelpMenuNav" = "Up/Down: navigate | Enter: select"
		"HelpMenuNavCancel" = "Up/Down: navigate | Enter: select | Esc: cancel"
		"ModeLabelDownloader" = "IPA Downloader"
		"ModeLabelInstaller" = "IPA Installer"
		"PressEnterToContinue" = "Press Enter to continue..."
	}
}

# Функция разделителя:
function Separator {
	Write-Host "================================================" -ForegroundColor Green
}

# Функция перевода текста:
function Get-Lang($Key) {
	return $LangStrings[$Global:CurrentLang][$Key]
}

# Функция вывода ошибки:
function Show-Error {
	param ([string]$Key = "ErrorInvalidInput")
	Separator
	Write-Host (Get-Lang $Key) -ForegroundColor DarkRed
	Read-Host (Get-Lang 'PressEnterToContinue')
}

# Глобальная переменная для хранения текущего Apple ID:
$Global:CurrentAppleID = "UnknownAccount"

# Функция получения текущего Apple ID:
function Get-Current-AppleID {
	$AuthInfo = & "$ipatoolFilePath" auth info 2>&1 | Out-String
	if ($AuthInfo -match 'email=([^\s]+)') {
		$Global:CurrentAppleID = $Matches[1].Trim()
	} else {
		$Global:CurrentAppleID = "UnknownAccount"
	}
}

# Функция получения имени приложения по ID:
function Resolve-AppDisplayName {
	param ([string]$AppId)
	$GitHubName = Get-GitHub-AppName -AppId $AppId
	return @{
		Display = if ([string]::IsNullOrWhiteSpace($GitHubName)) { $AppId } else { $GitHubName }
		Final = if ([string]::IsNullOrWhiteSpace($GitHubName)) { "Unknown" } else { $GitHubName }
	}
}

# Функция чтения JSON-файла списка приложений с учетом аккаунта:
function Read-AppList-Json {
	param ([string]$FilePath, [string]$EmptyError)
	if (!(Test-Path $FilePath)) {
		Show-Error $EmptyError
		return $null
	}
	$JsonRaw = Get-Content $FilePath -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw) -or $JsonRaw -eq '{}') {
		Show-Error $EmptyError
		return $null
	}
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data) {
		Show-Error $EmptyError
		return $null
	}
	
	# Поддержка старого формата (простой массив без привязки к аккаунту):
	if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [System.Management.Automation.PSCustomObject]) {
		return $Data
	}
	
	# Получение данных конкретного аккаунта:
	if ($Data.psobject.properties.match($Global:CurrentAppleID).Count -gt 0) {
		$AccountApps = $Data."$Global:CurrentAppleID"
		if ($AccountApps -isnot [System.Collections.IEnumerable]) { $AccountApps = @($AccountApps) }
		if ($AccountApps.Count -eq 0) {
			Show-Error $EmptyError
			return $null
		}
		return $AccountApps
	} else {
		Show-Error $EmptyError
		return $null
	}
}

# Функция проверки авторизации через ipatool:
function Test-IpatoolAuth {
	$AuthInfo = & "$ipatoolFilePath" auth info 2>&1 | Out-String
	return ($AuthInfo -match 'email=([^\s]+)')
}

# Функция входа в Apple ID:
function Connect-AppleID {
	while (!(Test-IpatoolAuth)) {
		Remove-Item "$CookiesFilePath" -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host (Get-Lang "AuthFail")
		& "$ipatoolFilePath" auth login
	}
	Get-Current-AppleID
}

# Функция извлечения метаданных из ipa:
function Get-IPA-Metadata {
	param ([string]$IpaPath)
	if (!(Test-Path $IpaPath)) { return $null }
	
	$Metadata = [PSCustomObject]@{
		AppName = "App"
		Version = "0"
		MinIOS = "NA"
	}
	
	try {
		$Zip = [System.IO.Compression.ZipFile]::OpenRead($IpaPath)
		$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match 'Payload/.*\.app/Info\.plist$' } | Select-Object -First 1
		if ($PlistEntry) {
			try {
				$Reader = New-Object System.IO.StreamReader($PlistEntry.Open(), [System.Text.Encoding]::UTF8)
				$Content = $Reader.ReadToEnd()
			} finally {
				if ($null -ne $Reader) { $Reader.Dispose() }
			}
			
			if ($Content -match '<key>CFBundleName</key>\s*<string>([^<]+)</string>') {
				$Metadata.AppName = $Matches[1]
			}
			if (($Metadata.AppName -eq "App") -and ($Content -match '<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>')) {
				$Metadata.AppName = $Matches[1]
			}
			if ($Content -match '<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>') {
				$Metadata.Version = $Matches[1]
			}
			if ($Content -match '<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>') {
				$Metadata.MinIOS = $Matches[1]
			}
		}
	} catch {
		return $null
	} finally {
		if ($null -ne $Zip) { $Zip.Dispose() }
	}
	
	$Metadata.AppName = $Metadata.AppName -replace '[\\/:*?"<>|]', ''
	return $Metadata
}

# Функция сохранения списков с привязкой к аккаунту и сортировкой:
function Save-App-To-List {
	param (
		[string]$AppId,
		[string]$AppNameOnly,
		[ValidateSet("Downloaded", "Purchased")][string]$Type
	)
	
	if ([string]::IsNullOrWhiteSpace($AppNameOnly) -or $AppNameOnly -eq "Unknown") {
		return
	}
	
	$HistoryFile = if ($Type -eq "Purchased") { "$PurchasedIDsFilePath" } else { "$DownloadedIDsFilePath" }
	
	# Создание файла, если его нет:
	if (!(Test-Path $HistoryFile)) {
		$null = New-Item -Path $HistoryFile -ItemType "File" -Value '{}'
	}
	
	$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw)) { $JsonRaw = '{}' }
	
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data) {
		$Data = New-Object PSCustomObject
	}
	
	# Конвертация старого формата (массив) в новый (объект с аккаунтами):
	if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [System.Management.Automation.PSCustomObject]) {
		$OldArray = $Data
		$Data = New-Object PSCustomObject
		$Data | Add-Member -MemberType NoteProperty -Name "UnknownAccount" -Value $OldArray
	}
	
	# Получение списка приложений для текущего аккаунта:
	$AccountApps = @()
	if ($Data.psobject.properties.match($Global:CurrentAppleID).Count -gt 0) {
		$AccountApps = $Data."$Global:CurrentAppleID"
	} else {
		$Data | Add-Member -MemberType NoteProperty -Name $Global:CurrentAppleID -Value @()
	}
	
	if ($AccountApps -isnot [System.Collections.IEnumerable]) { $AccountApps = @($AccountApps) }

	# Загрузка списка:
	Initialize-GitHub-List
	
	# Создание хэш-таблицы для поиска актуальных имен и индексов:
	$ReferenceMap = @{}
	for ($i = 0; $i -lt $Global:GitHubParsedList.Count; $i++) {
		$RefApp = $Global:GitHubParsedList[$i]
		$ReferenceMap[$RefApp.Id] = @{ Index = $i; Name = $RefApp.Name }
	}

	$IsDuplicate = $false

	# Синхронизация имен сохраненных приложений с Apps_ID_List.txt и поиск дубликатов:
	foreach ($Item in $AccountApps) {
		if ($ReferenceMap.ContainsKey($Item.appid)) {
			$Item.name = $ReferenceMap[$Item.appid].Name
		}
		if ($Item.appid -eq $AppId) {
			$IsDuplicate = $true
		}
	}

	# Добавление нового приложения, если это не дубликат:
	if (-not $IsDuplicate) {
		$NewItem = [PSCustomObject]@{ name = $AppNameOnly; appid = $AppId }
		$AccountApps = @($AccountApps) + $NewItem
	}
	
	# Сортировка: 
	$AccountApps = $AccountApps | Sort-Object `
		@{ Expression = { if ($ReferenceMap.ContainsKey($_.appid)) { $ReferenceMap[$_.appid].Index } else { [int]::MaxValue } } }, `
		@{ Expression = { 
			$name = [regex]::Replace("$($_.name)".ToUpper().Replace('Ё','Е'), '\d+', { $args[0].Value.PadLeft(10, '0') })
			[BitConverter]::ToString([Text.Encoding]::BigEndianUnicode.GetBytes($name))
		} }
	
	# Сохранение обновленных данных:
	$Data."$Global:CurrentAppleID" = $AccountApps
	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8

	# Вывод сообщений:
	if ($IsDuplicate) {
		$CurrentName = if ($ReferenceMap.ContainsKey($AppId)) { $ReferenceMap[$AppId].Name } else { $AppNameOnly }
		Write-Host ((Get-Lang "AlreadyInList") -f $CurrentName, $AppId)
	} else {
		$MsgKey = if ($Type -eq "Purchased") { "AddedToPurchasedList" } else { "AddedToDownloadedList" }
		Write-Host ((Get-Lang $MsgKey) -f $AppNameOnly, $AppId)
	}
}

# Функция инициализации и кэширования GitHub списка:
function Initialize-GitHub-List {
	if ($null -ne $Global:GitHubParsedList) { return }
	try {
		# Если файла нет, скачиваем синхронно:
		if (!(Test-Path "$AppsIDListPath")) {
			Invoke-RestMethod -Uri $AppsListUrl -OutFile "$AppsIDListPath" -ErrorAction SilentlyContinue
		}
		
		# Защита от сбоя сети при первом запуске:
		if (!(Test-Path "$AppsIDListPath")) {
			$Global:GitHubParsedList = @()
			return
		}
		
		# Чтение данных из локального файла:
		$Raw = Get-Content -Path "$AppsIDListPath" -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
		if ([string]::IsNullOrWhiteSpace($Raw)) { 
			$Global:GitHubParsedList = @()
			return 
		}
		
		$Global:GitHubParsedList = $Raw -split "`n" | Where-Object { $_ -match '^(.+?):\s*(\d+)' } | ForEach-Object {
			[PSCustomObject]@{
				Name = $Matches[1].Trim()
				Id = $Matches[2].Trim()
			}
		}
	} catch {
		$Global:GitHubParsedList = @()
	}
}

# Функция поиска имени приложения по кэшу:
function Get-GitHub-AppName {
	param ([string]$AppId)
	Initialize-GitHub-List
	$App = $Global:GitHubParsedList | Where-Object { $_.Id -eq $AppId } | Select-Object -First 1
	if ($App) { return $App.Name } else { return $null }
}

# Функция перемещения и автоматического переименования:
function Move-IPA-Files {
	param (
		[string]$AppId,
		[string]$AppName
	)
	$IpaFiles = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.ipa" -File
	if ($IpaFiles) {
		foreach ($File in $IpaFiles) {
			$DestPath = Join-Path -Path $AppsFolderPath -ChildPath $File.Name
			Move-Item -Path $File.FullName -Destination $DestPath -Force
			Separator
			Write-Host (Get-Lang "FileSaved")
			
			$Meta = Get-IPA-Metadata -IpaPath $DestPath
			if ($Meta) {
				$FinalAppName = $Meta.AppName
				
				# Проверяем GitHub список, если имя неизвестно или не было передано:
				if ([string]::IsNullOrWhiteSpace($AppName) -or $AppName -eq "Unknown") {
					$GitHubName = Get-GitHub-AppName -AppId $AppId
					if (![string]::IsNullOrWhiteSpace($GitHubName)) {
						$AppName = $GitHubName
					}
				}
				
				# Применение найденного имени, очищенного от недопустимых символов:
				if (![string]::IsNullOrWhiteSpace($AppName) -and $AppName -ne "Unknown") {
					$FinalAppName = $AppName -replace '[\\/:*?"<>|]', ''
				}
				
				# Формирование имени файла и замена всех пробелов на "_":
				$NewName = "$($FinalAppName)_$($Meta.Version)_iOS_$($Meta.MinIOS)+_$($Global:CurrentAppleID).ipa" -replace '\s+', '_'
				$TargetFile = Join-Path -Path $AppsFolderPath -ChildPath $NewName
				
				if (Test-Path $TargetFile) {
					Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue
				}
				
				Rename-Item -Path $DestPath -NewName $NewName -Force
				Write-Host "$(Get-Lang 'FileName') $NewName"
				Write-Host "$(Get-Lang 'MinIOS') $($Meta.MinIOS)+"

				if (![string]::IsNullOrEmpty($AppId)) {
					Save-App-To-List -AppId $AppId -AppNameOnly $FinalAppName -Type "Downloaded"
				}
			}
		}
	}
}

# Функция валидации числового ввода:
function Test-NumericInput {
	param ([string]$InputValue)
	if ([string]::IsNullOrWhiteSpace($InputValue) -or $InputValue -notmatch '^\d+$') {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor DarkRed
		return $false
	}
	return $true
}

# Функция пагинированного отображения списка с выбором галочками (стрелки + пробел):
function Show-Paginated-Selection {
	param (
		[array]$Items,
		[int]$PageSize = 20,
		[string]$NameProperty = "Name",
		[string]$IdProperty = "Id"
	)

	if ($Items.Count -eq 0) { return $null }

	$TotalItems = $Items.Count
	$TotalPages = [math]::Ceiling($TotalItems / $PageSize)
	$CurrentPage = 1
	$CursorPos = 0
	$SelectedSet = [System.Collections.Generic.HashSet[int]]::new()

	function Redraw-Page {
		[Console]::Clear()
		[Console]::CursorVisible = $false

		$StartIdx = ($CurrentPage - 1) * $PageSize
		$EndIdx = [math]::Min($StartIdx + $PageSize, $TotalItems)

		# Заголовок:
		$header = "=== {0} ===" -f ((Get-Lang 'PageHeader') -f $CurrentPage, $TotalPages)
		Write-Host $header -ForegroundColor Cyan

		# Элементы списка:
		for ($i = $StartIdx; $i -lt $EndIdx; $i++) {
			$Num = $i + 1
			$IsSelected = $SelectedSet.Contains($Num)
			$IsCursor = ($i - $StartIdx) -eq $CursorPos
			$Mark = if ($IsSelected) { Get-Lang 'MarkSelected' } else { Get-Lang 'MarkEmpty' }
			$CMark = if ($IsCursor) { " > " } else { "   " }
			$line = "{0}{1} {2} (ID: {3})" -f $CMark, $Mark, $Items[$i].$NameProperty, $Items[$i].$IdProperty
			if ($IsCursor) {
				Write-Host $line -ForegroundColor Black -BackgroundColor Gray
			} elseif ($IsSelected) {
				Write-Host $line -ForegroundColor Green
			} else {
				Write-Host $line
			}
		}

		# Подвал:
		Write-Host "================================================" -ForegroundColor Green
		$selInfo = ((Get-Lang 'SelectedCount') -f $SelectedSet.Count)
		Write-Host "$selInfo | $(Get-Lang 'HelpConfirm') | $(Get-Lang 'HelpCancel')" -ForegroundColor Yellow
		Write-Host "$(Get-Lang 'HelpNavigate') | $(Get-Lang 'HelpToggle') | $(Get-Lang 'HelpPages') | $(Get-Lang 'HelpPageSelect')" -ForegroundColor DarkCyan
		[Console]::CursorVisible = $true
	}

	Redraw-Page

	while ($true) {
		$key = [Console]::ReadKey($true)
		$needRedraw = $true

		switch ($key.Key) {
			'UpArrow' {
				if ($CursorPos -gt 0) { $CursorPos-- } else { $needRedraw = $false }
			}
			'DownArrow' {
				$maxIdx = [math]::Min($PageSize, $TotalItems - ($CurrentPage - 1) * $PageSize) - 1
				if ($CursorPos -lt $maxIdx) { $CursorPos++ } else { $needRedraw = $false }
			}
			'LeftArrow' {
				if ($CurrentPage -gt 1) { $CurrentPage--; $CursorPos = 0 } else { $needRedraw = $false }
			}
			'RightArrow' {
				if ($CurrentPage -lt $TotalPages) { $CurrentPage++; $CursorPos = 0 } else { $needRedraw = $false }
			}
			'Spacebar' {
				$gi = ($CurrentPage - 1) * $PageSize + $CursorPos + 1
				if ($SelectedSet.Contains($gi)) { $null = $SelectedSet.Remove($gi) } else { $null = $SelectedSet.Add($gi) }
			}
			'Enter' {
				[Console]::CursorVisible = $true
				return $(if ($SelectedSet.Count -eq 0) { $null } else { $SelectedSet | Sort-Object })
			}
			'Escape' {
				[Console]::CursorVisible = $true
				return $null
			}
			default {
				$needRedraw = $false
				$ch = $key.KeyChar
				if ($ch -eq 'a' -or $ch -eq 'A' -or $ch -eq [char]0x444 -or $ch -eq [char]0x424) {
					$s = ($CurrentPage - 1) * $PageSize + 1; $e = [math]::Min($CurrentPage * $PageSize, $TotalItems)
					for ($i = $s; $i -le $e; $i++) { $null = $SelectedSet.Add($i) }; $needRedraw = $true
				}
				elseif ($ch -eq 'd' -or $ch -eq 'D' -or $ch -eq [char]0x432 -or $ch -eq [char]0x412) {
					$s = ($CurrentPage - 1) * $PageSize + 1; $e = [math]::Min($CurrentPage * $PageSize, $TotalItems)
					for ($i = $s; $i -le $e; $i++) { $null = $SelectedSet.Remove($i) }; $needRedraw = $true
				}
			}
		}

		if ($needRedraw) { Redraw-Page }
	}
}

# Функция пагинированного просмотра списка (без выбора):
function Show-Paginated-List {
	param (
		[array]$Items,
		[int]$PageSize = 20,
		[scriptblock]$RenderRow,
		[string]$Header
	)

	if ($Items.Count -eq 0) { return }

	$TotalItems = $Items.Count
	$TotalPages = [math]::Ceiling($TotalItems / $PageSize)
	$CurrentPage = 1
	$CursorPos = 0

	function Redraw-Page {
		[Console]::Clear()
		[Console]::CursorVisible = $false

		$StartIdx = ($CurrentPage - 1) * $PageSize
		$EndIdx = [math]::Min($StartIdx + $PageSize, $TotalItems)

		$header = "=== {0} ===" -f ((Get-Lang 'PageHeader') -f $CurrentPage, $TotalPages)
		Write-Host $header -ForegroundColor Cyan
		if ($Header) { Write-Host $Header -ForegroundColor Cyan }

		for ($i = $StartIdx; $i -lt $EndIdx; $i++) {
			$IsCursor = ($i - $StartIdx) -eq $CursorPos
			$CMark = if ($IsCursor) { " > " } else { "   " }
			$row = & $RenderRow $Items[$i] ($i + 1)
			$line = "$CMark$row"
			if ($IsCursor) {
				Write-Host $line -ForegroundColor Black -BackgroundColor Gray
			} else {
				Write-Host $line
			}
		}

		Write-Host "================================================" -ForegroundColor Green
		Write-Host "$(Get-Lang 'HelpNavigate') | $(Get-Lang 'HelpPages') | Enter/Esc: $(Get-Lang 'HelpCancel')" -ForegroundColor DarkCyan
		[Console]::CursorVisible = $true
	}

	Redraw-Page

	while ($true) {
		$key = [Console]::ReadKey($true)
		$needRedraw = $true

		switch ($key.Key) {
			'UpArrow' {
				if ($CursorPos -gt 0) { $CursorPos-- } else { $needRedraw = $false }
			}
			'DownArrow' {
				$maxIdx = [math]::Min($PageSize, $TotalItems - ($CurrentPage - 1) * $PageSize) - 1
				if ($CursorPos -lt $maxIdx) { $CursorPos++ } else { $needRedraw = $false }
			}
			'LeftArrow' {
				if ($CurrentPage -gt 1) { $CurrentPage--; $CursorPos = 0 } else { $needRedraw = $false }
			}
			'RightArrow' {
				if ($CurrentPage -lt $TotalPages) { $CurrentPage++; $CursorPos = 0 } else { $needRedraw = $false }
			}
			default {
				$needRedraw = $false
			}
		}

		if ($key.Key -eq 'Enter' -or $key.Key -eq 'Escape') {
			[Console]::CursorVisible = $true
			return
		}

		if ($needRedraw) { Redraw-Page }
	}
}

# Функция выбора действия (покупка/загрузка/загрузка с версией):
function Show-Action-Submenu {
	$Options = @(
		(Get-Lang 'ActionDownload'),
		(Get-Lang 'ActionDownloadVer'),
		(Get-Lang 'ActionPurchase')
	)
	$Choice = Show-Interactive-Menu -Title (Get-Lang 'ActionMenuTitle') -Options $Options -AllowCancel
	if ($Choice -eq '0') { return $null }
	switch ($Choice) {
		"1" { return "Download" }
		"2" { return "DownloadVersion" }
		"3" { return "Purchase" }
	}
	return $null
}

# Функция интерактивного меню с выбором стрелками (одиночный выбор):
function Show-Interactive-Menu {
	param (
		[string]$Title,
		[array]$Options,
		[switch]$AllowCancel
	)

	$CursorPos = 0
	$OptionCount = $Options.Count

	function Redraw-Menu {
		[Console]::Clear()
		[Console]::CursorVisible = $false

		# Восстановление заголовка:
		if (![string]::IsNullOrEmpty($Global:MenuHeader)) {
			Write-Host $Global:MenuHeader
		}

		# Заголовок меню:
		Write-Host $Title -ForegroundColor Cyan

		# Пункты меню:
		for ($i = 0; $i -lt $OptionCount; $i++) {
			$mark = if ($i -eq $CursorPos) { " > " } else { "   " }
			$line = "$mark$($Options[$i])"
			if ($i -eq $CursorPos) {
				Write-Host $line -ForegroundColor Black -BackgroundColor Gray
			} else {
				Write-Host $line
			}
		}

		# Подсказка:
		$helpText = if ($AllowCancel) { Get-Lang 'HelpMenuNavCancel' } else { Get-Lang 'HelpMenuNav' }
		Write-Host $helpText -ForegroundColor DarkCyan
		[Console]::CursorVisible = $true
	}

	Redraw-Menu

	while ($true) {
		$key = [Console]::ReadKey($true)
		switch ($key.Key) {
			'UpArrow' {
				if ($CursorPos -gt 0) { $CursorPos-- }
				Redraw-Menu
			}
			'DownArrow' {
				if ($CursorPos -lt $OptionCount - 1) { $CursorPos++ }
				Redraw-Menu
			}
			'Enter' {
				[Console]::CursorVisible = $true
				return ($CursorPos + 1).ToString()
			}
			'Escape' {
				if ($AllowCancel) {
					[Console]::CursorVisible = $true
					return '0'
				}
			}
		}
	}
}

# Функция перевода ошибок ipatool в понятный текст:
function Translate-IpaError {
	param ([string]$Output)
	if ([string]::IsNullOrWhiteSpace($Output)) { return $null }

	$ErrorMap = @(
		@{ Pattern = 'Timeout was reached';                         Text = 'Не удалось подключиться к серверам Apple, проверьте интернет-соединение' }
		@{ Pattern = 'license is required';                         Text = 'Приложение не было приобретено на этом Apple ID ранее' }
		@{ Pattern = 'Purchase error:\s*app not found';             Text = 'Покупка не удалась — приложение удалено из App Store' }
		@{ Pattern = 'item is temporarily unavailable';             Text = 'Приложение удалено из App Store, покупка невозможна' }
		@{ Pattern = 'No device found';                             Text = 'Устройство не найдено. Убедитесь, что драйвер Apple Mobile Device Support установлен' }
		@{ Pattern = 'could not locate Payload.*SC_Info.*\.sinf';   Text = 'В IPA-файле не найдена подпись приложения' }
		@{ Pattern = 'anisette.*iTunes Not Found';                  Text = 'Не установлен iTunes с сайта Apple (не Microsoft Store)' }
		@{ Pattern = 'anisette.*iCloud Not Found';                  Text = 'Не установлен iCloud с сайта Apple (не Microsoft Store)' }
		@{ Pattern = 'GSA SRP exception.*-27952';                   Text = 'Необходимо отключить расширенную защиту данных: Настройки → Аккаунт → iCloud → Расширенная защита данных' }
		@{ Pattern = 'GSA SRP exception';                           Text = 'Ошибка авторизации Apple ID. Обновите iCloud for Windows до последней версии' }
		@{ Pattern = 'HTTP request failed';                         Text = 'Не удалось подключиться к серверам Apple, проверьте интернет-соединение' }
	)

	foreach ($entry in $ErrorMap) {
		if ($Output -match $entry.Pattern) {
			return $entry.Text
		}
	}
	return $null
}

# Функция вывода ошибки ipatool с переводом:
function Show-IpaError {
	param ([string]$Output)
	$Translated = Translate-IpaError -Output $Output
	if ($Translated) {
		Write-Host $Translated -ForegroundColor DarkRed
	} else {
		Write-Host $Output -ForegroundColor DarkRed
	}
}

# Функция загрузки приложений:
function IPA-Download {
	param (
		[string]$AppId,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	Separator
	try {
		$dlOutput = & "$ipatoolFilePath" download -i $AppId --purchase 2>&1 | Out-String
		if ($LASTEXITCODE -ne 0 -or $dlOutput -match "Error:" -or $dlOutput -match "error" -or $dlOutput -match "WARNING:") {
			Show-IpaError -Output $dlOutput
			Read-Host (Get-Lang 'PressEnterToContinue')
			return
		}
		Move-IPA-Files -AppId $AppId -AppName $AppName
	} catch {
		Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkRed
		Read-Host (Get-Lang 'PressEnterToContinue')
	}
}

# Функция загрузки приложений с выбором версии:
function IPA-Download-With-Version {
	param (
		[string]$AppId,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	
	Separator
	$RawOutput = & "$ipatoolFilePath" list-versions -i $AppId 2>&1

	if ($LASTEXITCODE -ne 0 -or $RawOutput -match "Error:" -or $RawOutput -match "error") {
		Show-IpaError -Output $RawOutput
		Read-Host (Get-Lang 'PressEnterToContinue')
		return
	}

	if ([string]::IsNullOrEmpty($RawOutput)) { return }

	$RawVersions = [regex]::Matches($RawOutput, '(?<=")\d+(?=")') | ForEach-Object { $_.Value }

	$VerQty = 0
	while ($true) {
		$VersionsQuantity = Read-Host "$(Get-Lang 'AskVerCount') $(Get-Lang 'CancelStep')`n"
		
		if ($VersionsQuantity -eq '0') { return }
		
		if ([int]::TryParse($VersionsQuantity, [ref]$VerQty) -and $VerQty -gt 0) {
			break
		}
		
		Show-Error "ErrorInvalidInput"
		Separator
	}

	$RecentVersions = $RawVersions | Select-Object -Last $VerQty | Sort-Object -Descending
	
	$VersionMapping = @()
	foreach ($VersionId in $RecentVersions) {
		$Meta = & "$ipatoolFilePath" get-version-metadata -i $AppId --external-version-id $VersionId 2>$null
		$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
		$VersionMapping += [PSCustomObject]@{ Name = "$DisplayVersion (ID: $VersionId)"; Id = $VersionId; Version = $DisplayVersion }
	}
	Separator
	
	$SelectedIndices = Show-Paginated-Selection -Items $VersionMapping -NameProperty "Version" -IdProperty "Id"
	if ($null -eq $SelectedIndices) { return }
	
	$SelectedVersions = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedVersions += $VersionMapping[$Idx - 1]
	}

	foreach ($SelectedObject in $SelectedVersions) {
		Separator
		Write-Host "$(Get-Lang 'SelectedVer') $($SelectedObject.Version)"
		Separator
		$FinalId = $SelectedObject.ID
		try {
			$dlOutput = & "$ipatoolFilePath" download -i $AppId --external-version-id $FinalId 2>&1 | Out-String
			if ($LASTEXITCODE -ne 0 -or $dlOutput -match "Error:" -or $dlOutput -match "error" -or $dlOutput -match "WARNING:") {
				Show-IpaError -Output $dlOutput
				Write-Host "Пропуск версии $($SelectedObject.Version)..." -ForegroundColor DarkYellow
				continue
			}
			Move-IPA-Files -AppId $AppId -AppName $AppName
		} catch {
			Write-Host "Error downloading version $($SelectedObject.Version): $_" -ForegroundColor DarkYellow
			continue
		}
	}
}

# Функция выполнения действия с приложением:
function Invoke-AppAction {
	param (
		[string]$AppId,
		[string]$AppName,
		[string]$DisplayName,
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action
	)
	Separator
	Write-Host "$(Get-Lang 'SelectedApp') $DisplayName"
	switch ($Action) {
		"Purchase" {
			Separator
			try {
				$purchaseOutput = & "$ipatoolFilePath" purchase -i $AppId 2>&1 | Out-String
				if ($LASTEXITCODE -ne 0 -or $purchaseOutput -match "Error:" -or $purchaseOutput -match "error") {
					Show-IpaError -Output $purchaseOutput
					Read-Host (Get-Lang 'PressEnterToContinue')
					return
				}
				Save-App-To-List -AppId $AppId -AppNameOnly $AppName -Type "Purchased"
			} catch {
				Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkRed
				Read-Host (Get-Lang 'PressEnterToContinue')
			}
		}
		"Download" {
			IPA-Download -AppId $AppId -AppName $AppName
		}
		"DownloadVersion" {
			IPA-Download-With-Version -AppId $AppId -AppName $AppName
		}
	}
}

# Функция поиска приложений:
function Search-Apps-Menu {
	while ($true) {
		Separator
		$AppName = Read-Host "$(Get-Lang 'AskSearch') $(Get-Lang 'CancelStep')`n"
		
		if ($AppName -eq '0') { return $null }
		if (![string]::IsNullOrWhiteSpace($AppName)) { break }
		
		Show-Error "ErrorInvalidInput"
	}

	# Инициализация списка из Apps_ID_List.txt:
	Initialize-GitHub-List

	# Поиск в списке приложений:
	$FoundApps = @()
	if ($null -ne $Global:GitHubParsedList) {
		$FoundApps += @($Global:GitHubParsedList | Where-Object { $_.Name -match [regex]::Escape($AppName) } | ForEach-Object {
			[PSCustomObject]@{
				name = $_.Name
				id = $_.Id
			}
		})
	}

	# Поиск в App Store:
	$SearchOutput = & "$ipatoolFilePath" search $AppName --limit 10 *>&1 | Out-String
	if ($SearchOutput -match 'apps=(\[.*?\])') {
		$JsonString = $Matches[1]
		if ($JsonString -ne '[]') {
			$ParsedApps = $JsonString | ConvertFrom-Json
			foreach ($Item in $ParsedApps) {
				$FoundApps += $Item
			}
		}
	}

	# Проверка на пустой результат:
	if ($FoundApps.Count -eq 0) {
		Show-Error "ErrorNoAppsFound"
		return $null
	}

	# Интерактивный выбор приложений:
	$Indices = Show-Paginated-Selection -Items $FoundApps -NameProperty "name" -IdProperty "id"
	if ($null -eq $Indices) { return $null }

	$SelectedApps = @()
	foreach ($Idx in $Indices) {
		$SelectedApps += $FoundApps[$Idx - 1]
	}
	return $SelectedApps
}

# Функция получения списка ID:
function Get-Multiple-AppIds {
	param ([string]$PromptKey)
	
	while ($true) {
		Separator
		$InputRaw = Read-Host "$(Get-Lang $PromptKey) $(Get-Lang 'CancelStep')`n"
		if ($InputRaw -eq '0') { return $null }
		
		if ([string]::IsNullOrWhiteSpace($InputRaw)) {
			Show-Error "ErrorInvalidInput"
			continue
		}
		
		$RawParts = $InputRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
		$AppIds = @()
		$AllValid = $true
		
		foreach ($Part in $RawParts) {
			if ($Part -notmatch '^\d+$') {
				$AllValid = $false
				break
			}
			$AppIds += $Part
		}
		
		if ($AllValid -and $AppIds.Count -gt 0) {
			return $AppIds
		}
		
		Show-Error "ErrorInvalidInput"
	}
}

# Функция получения списка выбранных приложений:
function Get-Apps-From-List {
	param (
		[string]$ListMode = "Download"
	)
	
	$MenuTitle = Get-Lang 'ListMenuTitle'
	$Menu1 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu1' } else { Get-Lang 'DownloadedListMenu1' }
	$Menu2 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu2' } else { Get-Lang 'DownloadedListMenu2' }
	$Menu3 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu3' } else { Get-Lang 'DownloadedListMenu3' }
	$TargetFile = if ($ListMode -eq "Purchase") { "$PurchasedIDsFilePath" } else { "$DownloadedIDsFilePath" }
	$EmptyError = if ($ListMode -eq "Purchase") { "ErrorPurchasedEmpty" } else { "ErrorDownloadedEmpty" }

	$ListOptions = @($Menu1, $Menu2, $Menu3)
	$ListChoice = Show-Interactive-Menu -Title $MenuTitle -Options $ListOptions -AllowCancel

	if ($ListChoice -eq '0') { return $null }

	$AppItems = @()

	switch ($ListChoice) {
		"1" {
			Initialize-GitHub-List
			if ($Global:GitHubParsedList.Count -eq 0) {
				Show-Error "ErrorListLoadError"
				return $null
			}
			foreach ($App in $Global:GitHubParsedList) {
				$AppItems += [PSCustomObject]@{ Name = $App.Name; Id = $App.Id }
			}
		}
		
		"2" {
			$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
			if ($null -eq $HistoryData) { return $null }
			
			foreach ($Item in $HistoryData) {
				$AppItems += [PSCustomObject]@{ Name = $Item.name; Id = $Item.appid }
			}
		}
		
		"3" {
			Initialize-GitHub-List
			if ($Global:GitHubParsedList.Count -eq 0) {
				Show-Error "ErrorListLoadError"
				return $null
			}

			$SavedIds = @()
			if (Test-Path $TargetFile) {
				$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
				if ($null -ne $HistoryData) {
					$SavedIds = $HistoryData.appid
				}
			}

			foreach ($App in $Global:GitHubParsedList) {
				if ($App.Id -and $SavedIds -notcontains $App.Id) {
					$AppItems += [PSCustomObject]@{ Name = $App.Name; Id = $App.Id }
				}
			}
		}
	}

	if ($AppItems.Count -eq 0) {
		Show-Error "ErrorNoAppsFound"
		return $null
	}

	$SelectedIndices = Show-Paginated-Selection -Items $AppItems
	if ($null -eq $SelectedIndices) { return $null }

	$SelectedApps = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedApps += $AppItems[$Idx - 1]
	}
	return $SelectedApps
}

# Функция проверки минимальной версии iOS:
function Get-iOS-MinVersion {
	$FilesToProcess = Get-ChildItem -Path "$AppsFolderPath" -Filter "*.ipa" -File -ErrorAction SilentlyContinue

	if (-not $FilesToProcess) {
		Show-Error "ErrorNoApps"
		return $null
	}

	$Rows = @()
	foreach ($File in $FilesToProcess) {
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "Error" }
		$PrintName = if ($File.Name.Length -gt 30) { $File.Name.Substring(0,27) + "..." } else { $File.Name }
		$Rows += [PSCustomObject]@{ Name = $PrintName; MinIOS = $MinOs }
	}

	Show-Paginated-List -Items $Rows -Header ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderFileName"), (Get-Lang "HeaderMinIOS")) -RenderRow {
		param($Item, $Num)
		"{0,-3} {1,-30} {2}" -f $Num, $Item.Name, $Item.MinIOS
	}

	return @($FilesToProcess)
}

# Функция вывода ошибки об отсутствующих файлах:
function Confirm-RequiredFiles {
	param ([array]$MissingFiles)
	if ($MissingFiles) {
		Separator
		Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor DarkRed
		$MissingFiles | ForEach-Object { Write-Host "$_" -ForegroundColor DarkRed }
		Separator
		exit
	}
}

# Функция добавления папки с ipatool в PATH текущего процесса:
function Update-PathFolder {
	param ([string]$NewFolder)
	
	$PathEntries = $env:Path -split [regex]::Escape(';')
	
	# Добавляем папку, только если её ещё нет в PATH:
	if ($NewFolder -notin $PathEntries) {
		$env:Path = $env:Path + ';' + $NewFolder
	}
}

# Функция установки путей к ipatool/ideviceinstaller и применения PATH/прав запуска:
function Set-IpatoolBinaryPaths {
	param ([string]$FolderPath)
	
	$script:ipatoolFilePath = Join-Path -Path $FolderPath -ChildPath "ipatool.exe"
	$script:ideviceinstallerFilePath = Join-Path -Path $FolderPath -ChildPath "ideviceinstaller.exe"

	# Добавление папки с ipatool в PATH текущего процесса:
	Update-PathFolder -NewFolder $FolderPath
}

# Функция проверки наличия необходимых файлов:
function Get-MissingBinaryFiles {
	param ([string]$FolderPath)

	$RequiredFiles = @("ideviceinstaller.exe", "ipatool.exe")
	$ExistingFiles = @()
	if (Test-Path -Path $FolderPath) {
		$ExistingFiles = Get-ChildItem -Path $FolderPath -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
	}
	$MissingFiles = foreach ($File in $RequiredFiles) {
		if ($File -notin $ExistingFiles) {
			Join-Path -Path $FolderPath -ChildPath $File
		}
	}
	return $MissingFiles
}

# Функция установки конкретной версии ipatool:
function Set-IpatoolVersion {
	param ([ValidateSet("v2", "v3")][string]$Version)
	
	$OldBinaryFolderPath = $script:BinaryFolderPath
	$NewArchSubFolder = Get-ArchSubFolder -Version $Version
	$NewBinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $NewArchSubFolder
	
	# Проверка наличия необходимых файлов в папке выбранной версии:
	$MissingVersionFiles = Get-MissingBinaryFiles -FolderPath $NewBinaryFolderPath
	if ($MissingVersionFiles) {
		Separator
		Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor DarkRed
		$MissingVersionFiles | ForEach-Object { Write-Host "$_" -ForegroundColor DarkRed }
		return $false
	}
	
	# Применение выбранной версии ipatool:
	$script:IpatoolVersion = $Version
	$script:ArchSubFolder = $NewArchSubFolder
	$script:BinaryFolderPath = $NewBinaryFolderPath
	
	Set-IpatoolBinaryPaths -FolderPath $script:BinaryFolderPath
	
	return $true
}

# Функция запроса версии ipatool с проверкой наличия файлов:
function Invoke-IpatoolVersionPrompt {
	$V2Label = "ipatool_$(Get-ArchSubFolder -Version 'v2')"
	$V3Label = "ipatool_$(Get-ArchSubFolder -Version 'v3')"
	
	while ($true) {
		Separator
		$VersionOptions = @($V2Label, $V3Label)
		$VersionChoice = Show-Interactive-Menu -Title (Get-Lang 'IpatoolVersionMenuTitle') -Options $VersionOptions
		$SelectedVersion = if ($VersionChoice -eq '2') { 'v3' } else { 'v2' }
		
		if (Set-IpatoolVersion -Version $SelectedVersion) {
			return
		}
	}
}

# Функция установки приложений из папки Apps:
function Invoke-InstallApps {
	if ([string]::IsNullOrWhiteSpace($script:ideviceinstallerFilePath)) {
		Show-Error "ErrorMissingFiles"
		return
	}
	
	$RawFiles = Get-ChildItem -Path "$AppsFolderPath" -Filter "*.ipa" -File -ErrorAction SilentlyContinue
	if (-not $RawFiles) {
		Show-Error "ErrorNoApps"
		return
	}

	# Формирование объектов с метаданными для интерактивного выбора:
	$IpaItems = @()
	foreach ($File in $RawFiles) {
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "NA" }
		$IpaItems += [PSCustomObject]@{
			Name = "$($File.Name) [$MinOs]"
			Id = $File.Name
			FullName = $File.FullName
		}
	}

	$SelectedIndices = Show-Paginated-Selection -Items $IpaItems
	if ($null -eq $SelectedIndices) { return }

	foreach ($Idx in $SelectedIndices) {
		$SelectedItem = $IpaItems[$Idx - 1]
		Separator
		Write-Host "$(Get-Lang 'InstallApp') $($SelectedItem.Id)"
		$TempFile = "$TempIpaFilePath"
		Copy-Item -Path $SelectedItem.FullName -Destination $TempFile -Force
		& "$ideviceinstallerFilePath" install $TempFile
		Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
	}
}

# Функция проверки и автоматического обновления:
function Check-Update {
	try {
		# Принудительно включаем TLS 1.2 для GitHub:
		[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

		# Получаем информацию о последнем коммите:
		$CommitResponse = Invoke-WebRequest -Uri $CommitApiUrl -UseBasicParsing -ErrorAction SilentlyContinue -TimeoutSec 10
		if (-not $CommitResponse) { return }

		$CommitData = $CommitResponse.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
		if (-not $CommitData -or -not $CommitData.sha) { return }

		$RemoteSha = $CommitData.sha

		# Читаем сохранённый хеш (сначала пробуем git, затем файл):
		$LastCommitFile = Join-Path -Path $MainAppFolderPath -ChildPath ".last_commit"
		$LocalSha = ""
		$GitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
		if ($GitExe -and (Test-Path (Join-Path $PSScriptRoot ".git"))) {
			$LocalSha = (& $GitExe -C $PSScriptRoot rev-parse HEAD 2>$null).Trim()
			# Синхронизируем .last_commit с git:
			if (-not [string]::IsNullOrWhiteSpace($LocalSha)) {
				Set-Content -Path $LastCommitFile -Value $LocalSha -Force
			}
		}
		if ([string]::IsNullOrWhiteSpace($LocalSha) -and (Test-Path $LastCommitFile)) {
			$LocalSha = (Get-Content $LastCommitFile -Raw -ErrorAction SilentlyContinue).Trim()
		}

		# Если хеши совпадают — обновление не нужно:
		if ($LocalSha -eq $RemoteSha) { return }

		# Получаем список изменённых файлов:
		$ChangedFiles = @()
		if ($CommitData.files) {
			$ChangedFiles = $CommitData.files | ForEach-Object { $_.filename }
		}

		if ($ChangedFiles.Count -eq 0) { return }

		# Показываем что обновляется:
		Separator
		Write-Host "Доступно обновление!" -ForegroundColor Cyan
		Write-Host "Изменённые файлы:"
		foreach ($f in $ChangedFiles) {
			Write-Host "  - $f"
		}
		Write-Host ""

		$UpdateOptions = @((Get-Lang 'UpdateMenu1'), (Get-Lang 'UpdateMenu2'))
		$Choice = Show-Interactive-Menu -Title "Обновить?" -Options $UpdateOptions

		if ($Choice -ne '1') {
			return
		}

		Separator
		Write-Host "Загрузка обновлений..." -ForegroundColor Cyan

		# Скачиваем каждый изменённый файл:
		$Count = 0
		foreach ($File in $ChangedFiles) {
			if ([string]::IsNullOrWhiteSpace($File)) { continue }

			$FileUrl = "$RawBase/$File"
			$LocalPath = Join-Path -Path $PSScriptRoot -ChildPath $File
			$LocalDir = Split-Path -Path $LocalPath -Parent

			# Создаём директорию если нужно:
			if (-not (Test-Path $LocalDir)) {
				$null = New-Item -Path $LocalDir -ItemType Directory -Force
			}

			# Скачиваем файл:
			Write-Host "  $File"
			Invoke-WebRequest -Uri $FileUrl -OutFile $LocalPath -ErrorAction SilentlyContinue
			$Count++
		}

		# Сохраняем новый хеш:
		Set-Content -Path $LastCommitFile -Value $RemoteSha -Force

		Write-Host ""
		Write-Host "[OK] Обновлено файлов: $Count" -ForegroundColor Green
		Write-Host "Перезапуск..." -ForegroundColor Cyan

		# Перезапуск скрипта:
		$SelfPath = Join-Path -Path $PSScriptRoot -ChildPath "IPA_Downloader.ps1"
		$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
		if (-not $pwshPath) { $pwshPath = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
		if ($pwshPath) {
			Start-Process $pwshPath -ArgumentList "-ExecutionPolicy Bypass -File `"$SelfPath`"" -WorkingDirectory $PSScriptRoot
		}
		exit
	} catch {
		# Проверка обновлений не критична — молча пропускаем
		return
	}
}

# Функция вывода баннера с текущим режимом работы, версией скрипта и системой/архитектурой:
function Show-ModeBanner {
	$ModeLabel = if ($Global:WorkMode -eq "Installer") { Get-Lang 'ModeLabelInstaller' } else { Get-Lang 'ModeLabelDownloader' }
	Separator
	Write-Host "$ModeLabel $ScriptVersion ($ArchSubFolder)"
}

# Функция первоначальной настройки (язык, режим работы, версия ipatool):
function Invoke-SetupWizard {
	# Удаление содержимого папки .ipatool:
	Get-ChildItem -Path $ipatoolHomePath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

	# Запрос на выбор языка:
	Separator
	$LanguageOptions = @((Get-Lang 'LanguageMenu1'), (Get-Lang 'LanguageMenu2'))
	$LanguageChoice = Show-Interactive-Menu -Title (Get-Lang 'LanguageMenuTitle') -Options $LanguageOptions
	$Global:CurrentLang = if ($LanguageChoice -eq '1') { "RU" } else { "EN" }
	Set-Setting -Key "Language" -Value $Global:CurrentLang
	
	# Проверка обновлений после выбора языка:
	if (-not $Global:UpdateChecked) {
		Check-Update
		$Global:UpdateChecked = $true
	}
	
	# Запрос на выбор режима работы:
	Separator
	$ModeOptions = @((Get-Lang 'ModeMenu1'), (Get-Lang 'ModeMenu2'))
	$ModeChoice = Show-Interactive-Menu -Title (Get-Lang 'ModeMenuTitle') -Options $ModeOptions
	$Global:WorkMode = if ($ModeChoice -eq '2') { "Installer" } else { "Downloader" }
	
	# Сохранение режима IPA_Installer:
	if ($Global:WorkMode -eq "Installer") {
		Set-Setting -Key "Mode" -Value $Global:WorkMode
	}
	
	# Версия ipatool запрашивается только для режима IPA_Downloader:
	if ($Global:WorkMode -eq "Downloader") {
		Invoke-IpatoolVersionPrompt
	}
	
	Show-ModeBanner
}

# Операционная система:
Separator
Write-Host "$OSVersion"

# Версия PowerShell:
Write-Host "PowerShell $PSVersion"

# Проверка на наличие базовых папок:
foreach ($Dir in @("$AppsFolderPath", "$ListsFolderPath", "$MainAppFolderPath", "$ipatoolHomePath")) {
	if (!(Test-Path $Dir)) {
		$null = New-Item -Path $Dir -ItemType "Directory"
	}
}

# Удаление временных файлов при запуске:
Get-ChildItem -Path $PSScriptRoot -Filter "*.ipa.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path $AppsIDTempListPath) { Remove-Item $AppsIDTempListPath -Force -ErrorAction SilentlyContinue }

# Включение TLS 1.2 для GitHub:
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Асинхронное фоновое обновление списка приложений с GitHub:
$AppsIDListDownload = {
	param($Url, $FinalPath, $TempPath)
	try {
		if ([System.Environment]::OSVersion.Version.Major -eq 6 -and [System.Environment]::OSVersion.Version.Minor -eq 1) {
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		}
		
		# Скачиваем список приложений во временный файл в папку MainApp:
		Invoke-RestMethod -Uri $Url -OutFile $TempPath -ErrorAction SilentlyContinue
		
		if (Test-Path $TempPath) {
			# Проверка на то, что файл загрузился:
			if ((Get-Item $TempPath).Length -gt 10) {
				Move-Item -Path $TempPath -Destination $FinalPath -Force
			} else {
				Remove-Item $TempPath -Force
			}
		}
	} catch {
	}
}

$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()
$PSInstance = [powershell]::Create().AddScript($AppsIDListDownload).AddArgument($AppsListUrl).AddArgument($AppsIDListPath).AddArgument($AppsIDTempListPath)
$PSInstance.Runspace = $Runspace
$null = $PSInstance.BeginInvoke()

# Функция пакетной загрузки приложений из Apps_ID_List.txt (с пагинированным выбором):
function Bulk-Download-All {
	param (
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action
	)

	Initialize-GitHub-List
	if ($null -eq $Global:GitHubParsedList -or $Global:GitHubParsedList.Count -eq 0) {
		Show-Error "ErrorListLoadError"
		return
	}

	# Пагинированный выбор приложений:
	$SelectedIndices = Show-Paginated-Selection -Items $Global:GitHubParsedList -PageSize 20
	if ($null -eq $SelectedIndices) {
		Show-Error "NothingSelected"
		return
	}

	$SelectedApps = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedApps += $Global:GitHubParsedList[$Idx - 1]
	}
	$TotalApps = $SelectedApps.Count

	$ActionLabel = switch ($Action) {
		"Purchase"      { if ($Global:CurrentLang -eq "RU") { "Покупка" } else { "Purchase" } }
		"Download"      { if ($Global:CurrentLang -eq "RU") { "Загрузка" } else { "Download" } }
		"DownloadVersion" { if ($Global:CurrentLang -eq "RU") { "Загрузка (выбор версии)" } else { "Download (version select)" } }
	}

	$Counter = 0
	foreach ($App in $SelectedApps) {
		$Counter++
		Separator
		$ProgressMsg = "$(Get-Lang 'BulkDownloadProgress')"
		$ProgressMsg = $ProgressMsg -f $Counter, $TotalApps, $App.Name, $App.Id
		Write-Host $ProgressMsg
		Write-Host "[$ActionLabel] $($App.Name) (ID: $($App.Id))" -ForegroundColor Cyan

		# Проверка: уже скачано / куплено?
		$SkipApp = $false
		if ($Action -eq "Purchase") {
			if (Test-Path $PurchasedIDsFilePath) {
				$PurchasedData = Read-AppList-Json -FilePath $PurchasedIDsFilePath -EmptyError $null
				if ($null -ne $PurchasedData -and ($PurchasedData.appid -contains $App.Id)) {
					Write-Host ((Get-Lang 'AlreadyDownloaded') -f $App.Name) -ForegroundColor DarkYellow
					$SkipApp = $true
				}
			}
		} else {
			$ExistingFile = Get-ChildItem -Path $AppsFolderPath -Filter "*.ipa" -File -ErrorAction SilentlyContinue |
				Where-Object { $_.Name -like "*$($App.Name)*" } | Select-Object -First 1
			if ($ExistingFile) {
				Write-Host ((Get-Lang 'AlreadyDownloaded') -f $App.Name) -ForegroundColor DarkYellow
				$SkipApp = $true
			}
		}
		if ($SkipApp) { continue }

		try {
			switch ($Action) {
				"Purchase" {
					& "$ipatoolFilePath" purchase -i $App.Id
					Save-App-To-List -AppId $App.Id -AppNameOnly $App.Name -Type "Purchased"
				}
				"Download" {
					& "$ipatoolFilePath" download -i $App.Id --purchase
					Move-IPA-Files -AppId $App.Id -AppName $App.Name
				}
				"DownloadVersion" {
					IPA-Download-With-Version -AppId $App.Id -AppName $App.Name
				}
			}
		} catch {
			Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
			continue
		}
	}

	Separator
	$DoneMsg = (Get-Lang 'BulkDownloadComplete') -f $TotalApps
	Write-Host $DoneMsg -ForegroundColor Green
}

# Функция загрузки банковских приложений из Banks_ID_List.txt (с пагинированным выбором):
function Download-Banks {
	param (
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action
	)

	$BanksListPath = Join-Path -Path $ListsFolderPath -ChildPath "Banks_ID_List.txt"
	if (!(Test-Path $BanksListPath)) {
		Show-Error "ErrorListLoadError"
		return
	}

	$Raw = Get-Content -Path $BanksListPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
	if ([string]::IsNullOrWhiteSpace($Raw)) {
		Show-Error "ErrorListLoadError"
		return
	}

	$BankApps = $Raw -split "`n" | Where-Object { $_ -match '^(.+?):\s*(\d+)' } | ForEach-Object {
		[PSCustomObject]@{
			Name = $Matches[1].Trim()
			Id = $Matches[2].Trim()
		}
	}

	if ($BankApps.Count -eq 0) {
		Show-Error "ErrorListLoadError"
		return
	}

	Separator
	Write-Host ((Get-Lang 'BanksListLoaded') -f $BankApps.Count)

	# Пагинированный выбор банков:
	$SelectedIndices = Show-Paginated-Selection -Items $BankApps -PageSize 20
	if ($null -eq $SelectedIndices) {
		Show-Error "NothingSelected"
		return
	}

	$SelectedApps = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedApps += $BankApps[$Idx - 1]
	}
	$TotalApps = $SelectedApps.Count

	$ActionLabel = switch ($Action) {
		"Purchase"      { if ($Global:CurrentLang -eq "RU") { "Покупка" } else { "Purchase" } }
		"Download"      { if ($Global:CurrentLang -eq "RU") { "Загрузка" } else { "Download" } }
		"DownloadVersion" { if ($Global:CurrentLang -eq "RU") { "Загрузка (выбор версии)" } else { "Download (version select)" } }
	}

	$Counter = 0
	foreach ($App in $SelectedApps) {
		$Counter++
		Separator
		$ProgressMsg = "$(Get-Lang 'BulkDownloadProgress')"
		$ProgressMsg = $ProgressMsg -f $Counter, $TotalApps, $App.Name, $App.Id
		Write-Host $ProgressMsg
		Write-Host "[$ActionLabel] $($App.Name) (ID: $($App.Id))" -ForegroundColor Cyan

		# Проверка: уже скачано / куплено?
		$SkipApp = $false
		if ($Action -eq "Purchase") {
			if (Test-Path $PurchasedIDsFilePath) {
				$PurchasedData = Read-AppList-Json -FilePath $PurchasedIDsFilePath -EmptyError $null
				if ($null -ne $PurchasedData -and ($PurchasedData.appid -contains $App.Id)) {
					Write-Host ((Get-Lang 'AlreadyDownloaded') -f $App.Name) -ForegroundColor DarkYellow
					$SkipApp = $true
				}
			}
		} else {
			$ExistingFile = Get-ChildItem -Path $AppsFolderPath -Filter "*.ipa" -File -ErrorAction SilentlyContinue |
				Where-Object { $_.Name -like "*$($App.Name)*" } | Select-Object -First 1
			if ($ExistingFile) {
				Write-Host ((Get-Lang 'AlreadyDownloaded') -f $App.Name) -ForegroundColor DarkYellow
				$SkipApp = $true
			}
		}
		if ($SkipApp) { continue }

		try {
			switch ($Action) {
				"Purchase" {
					& "$ipatoolFilePath" purchase -i $App.Id
					Save-App-To-List -AppId $App.Id -AppNameOnly $App.Name -Type "Purchased"
				}
				"Download" {
					& "$ipatoolFilePath" download -i $App.Id --purchase
					Move-IPA-Files -AppId $App.Id -AppName $App.Name
				}
				"DownloadVersion" {
					IPA-Download-With-Version -AppId $App.Id -AppName $App.Name
				}
			}
		} catch {
			Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
			continue
		}
	}

	Separator
	$DoneMsg = (Get-Lang 'BulkDownloadComplete') -f $TotalApps
	Write-Host $DoneMsg -ForegroundColor Green
}

# Функция режима IPA_Downloader:
function Invoke-DownloaderMode {
	# Проверка осуществленного входа с Apple ID:
	if (Test-IpatoolAuth) {
		Separator
		Write-Host (Get-Lang "AuthSuccess")
		& "$ipatoolFilePath" auth info
		Get-Current-AppleID
	}
	
	# Вход с Apple ID:
	Connect-AppleID
	
	# Сохранение режима IPA_Downloader после успешной авторизации с Apple ID:
	Set-Setting -Key "Mode" -Value "Downloader"
	Set-Setting -Key "IpatoolVersion" -Value $script:IpatoolVersion
	
	# Сохранение заголовка для восстановления после очистки экрана:
	$ModeLabel = if ($Global:WorkMode -eq "Installer") { Get-Lang 'ModeLabelInstaller' } else { Get-Lang 'ModeLabelDownloader' }
	$Global:MenuHeader = "================================================`n$ModeLabel $ScriptVersion ($ArchSubFolder)`n================================================`n$(Get-Lang 'AuthSuccess')`n$Global:CurrentAppleID`n================================================"
	
	# Основной цикл:
	while (Test-IpatoolAuth) {
	
		Separator
		$MainMenuOptions = @(
			(Get-Lang 'Menu1'), (Get-Lang 'Menu2'), (Get-Lang 'Menu3'),
			(Get-Lang 'Menu4'), (Get-Lang 'Menu5'), (Get-Lang 'Menu6'),
			(Get-Lang 'Menu7'), (Get-Lang 'Menu8'), (Get-Lang 'Menu9'),
			(Get-Lang 'Menu10')
		)
		$SwitchValue = Show-Interactive-Menu -Title (Get-Lang 'MenuTitle') -Options $MainMenuOptions
		switch ($SwitchValue) {

			# 1. Поиск приложения:
			"1" {
				$Action = Show-Action-Submenu
				if ($null -ne $Action) {
					$AppsToProcess = Search-Apps-Menu
					if ($null -ne $AppsToProcess) {
						foreach ($App in $AppsToProcess) {
							Invoke-AppAction -AppId $App.id -AppName $App.name -DisplayName $App.name -Action $Action
						}
					}
				}
			}

			# 2. Поиск по ID:
			"2" {
				$Action = Show-Action-Submenu
				if ($null -ne $Action) {
					$AppIds = Get-Multiple-AppIds -PromptKey 'AskIdSearch'
					if ($null -ne $AppIds) {
						foreach ($Id in $AppIds) {
							$AppNames = Resolve-AppDisplayName -AppId $Id
							Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action $Action
						}
					}
				}
			}

			# 3. Список приложений:
			"3" {
				$Action = Show-Action-Submenu
				if ($null -ne $Action) {
					Separator
					$SelectedApps = Get-Apps-From-List -ListMode "Download"
					if ($null -ne $SelectedApps) {
						foreach ($App in $SelectedApps) {
							Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action $Action
						}
					}
				}
			}

			# 4. Банковские приложения:
			"4" {
				$Action = Show-Action-Submenu
				if ($null -ne $Action) {
					Download-Banks -Action $Action
				}
			}

			# 5. Проверка минимальной версии iOS:
			"5" {
				$null = Get-iOS-MinVersion
			}

			# 6. Установка приложений из папки Apps:
			"6" {
				Invoke-InstallApps
			}

			# 7. Очистка данных скрипта:
			"7" {
				Separator
				$ClearOptions = @((Get-Lang 'ClearMenu1'), (Get-Lang 'ClearMenu2'), (Get-Lang 'ClearMenu3'))
				$ClearChoice = Show-Interactive-Menu -Title (Get-Lang 'ClearMenuTitle') -Options $ClearOptions -AllowCancel
				
				if ($ClearChoice -eq '0') { continue }
				
				switch ($ClearChoice) {					
					"1" {
						if (!(Test-Path "$PurchasedIDsFilePath")) {
							Separator
							Write-Host (Get-Lang "ErrorPurchasedEmpty") -ForegroundColor DarkRed
						} else {
							$RawData = Get-Content "$PurchasedIDsFilePath" -Raw -Encoding UTF8
							
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "ErrorPurchasedEmpty") -ForegroundColor DarkRed
								continue
							}

							$Data = $RawData | ConvertFrom-Json
							
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedListCleared")
								continue
							}

							$Accounts = @($Data.psobject.properties.Name)
							$AccOptions = @()
							$Counter = 1
							foreach ($Acc in $Accounts) {
								$AccOptions += "$Counter. $Acc"
								$Counter++
							}
							$AccOptions += "$Counter. $(Get-Lang 'ClearAllAccounts')"
							
							Separator
							$AccChoice = Show-Interactive-Menu -Title (Get-Lang 'ClearAccountMenuTitle') -Options $AccOptions -AllowCancel
							if ($AccChoice -eq '0') { continue }
							
							if ([int]$AccChoice -eq $Counter) {
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedListCleared")
							} else {
								$SelectedAcc = $Accounts[[int]$AccChoice - 1]
								if ($Accounts.Count -le 1) {
									Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAcc)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$PurchasedIDsFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAcc)
							}
						}
					}
					
					"2" {
						if (!(Test-Path "$DownloadedIDsFilePath")) {
							Separator
							Write-Host (Get-Lang "ErrorDownloadedEmpty") -ForegroundColor DarkRed
						} else {
							$RawData = Get-Content "$DownloadedIDsFilePath" -Raw -Encoding UTF8
							
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "ErrorDownloadedEmpty") -ForegroundColor DarkRed
								continue
							}

							$Data = $RawData | ConvertFrom-Json
							
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedListCleared")
								continue
							}

							$Accounts = @($Data.psobject.properties.Name)
							$AccOptions = @()
							$Counter = 1
							foreach ($Acc in $Accounts) {
								$AccOptions += "$Counter. $Acc"
								$Counter++
							}
							$AccOptions += "$Counter. $(Get-Lang 'ClearAllAccounts')"
							
							Separator
							$AccChoice = Show-Interactive-Menu -Title (Get-Lang 'ClearAccountMenuTitle') -Options $AccOptions -AllowCancel
							if ($AccChoice -eq '0') { continue }
							
							if ([int]$AccChoice -eq $Counter) {
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedListCleared")
							} else {
								$SelectedAcc = $Accounts[[int]$AccChoice - 1]
								if ($Accounts.Count -le 1) {
									Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAcc)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$DownloadedIDsFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAcc)
							}
						}
					}
					
					"3" {
						$ipaFilesToRemove = Get-ChildItem -Path $AppsFolderPath -Filter "*.ipa" -File -ErrorAction SilentlyContinue
						if ($ipaFilesToRemove) {
							$ipaFilesToRemove | Remove-Item -Force -ErrorAction SilentlyContinue
							Separator
							Write-Host (Get-Lang "AppsCleared")
						} else {
							Show-Error "ErrorNoApps"
						}
					}
				}
			}
			
			# 8. Выход из Apple ID + сброс настроек:
			"8" {
				Separator
				Write-Host (Get-Lang "LoggedOut")
				& "$ipatoolFilePath" auth revoke

				Remove-Item -Path $SettingsFilePath -Force -ErrorAction SilentlyContinue
				$Global:WorkMode = $null
				return
			}

			# 9. Поддержка проекта:
			"9" {
				Start-Process "$RepoUrl#поддержка-проекта"
			}

			# 10. Сменить язык (Change Language):
			"10" {
				$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $Global:CurrentLang
				Separator
				Write-Host (Get-Lang "LangChanged")
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Функция режима IPA_Installer:
function Invoke-InstallerMode {
	while ($true) {
		Separator
		$InstallerOptions = @(
			(Get-Lang 'InstallerMenu1'), (Get-Lang 'InstallerMenu2'), (Get-Lang 'InstallerMenu3'),
			(Get-Lang 'InstallerMenu4'), (Get-Lang 'InstallerMenu5'), (Get-Lang 'InstallerMenu6')
		)
		$SwitchValue = Show-Interactive-Menu -Title (Get-Lang 'MenuTitle') -Options $InstallerOptions
		switch ($SwitchValue) {
			
			# 1. Проверка минимальной версии iOS для приложений в папке Apps:
			"1" {
				$null = Get-iOS-MinVersion
			}
			
			# 2. Установка приложений из папки Apps:
			"2" {
				Invoke-InstallApps
			}
			
			# 3. Поддержка проекта:
			"3" {
				Start-Process "$RepoUrl#поддержка-проекта"
			}
			
			# 4. Сменить язык (Change Language):
			"4" {
				$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $Global:CurrentLang
				Separator
				Write-Host (Get-Lang "LangChanged")
			}
			
			# 5. Сброс настроек:
			"5" {
				Remove-Item -Path $SettingsFilePath -Force -ErrorAction SilentlyContinue
				$Global:WorkMode = $null
				return
			}
			
			# 6. Перейти в IPA_Downloader:
			"6" {
				Invoke-IpatoolVersionPrompt
				$Global:WorkMode = "Downloader"
				return
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Смена режима работы:
$Global:UpdateChecked = $false

while ($true) {
	
	# Если режим работы не выбран, то запускаем мастер настройки, иначе показываем баннер:
	if ($null -eq $Global:WorkMode) {
		Invoke-SetupWizard
	} else {
		if (-not $Global:UpdateChecked) {
			Check-Update
			$Global:UpdateChecked = $true
		}
		
		Show-ModeBanner
	}
	
	# Проверка наличия необходимых файлов:
	$MissingMainAppFiles = Get-MissingBinaryFiles -FolderPath $BinaryFolderPath
	Confirm-RequiredFiles -MissingFiles $MissingMainAppFiles
	Set-IpatoolBinaryPaths -FolderPath $BinaryFolderPath
	
	if ($Global:WorkMode -eq "Installer") {
		Invoke-InstallerMode
	} else {
		Invoke-DownloaderMode
	}
}