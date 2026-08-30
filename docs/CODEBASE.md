# Карта кода

## Порядок загрузки

Задаётся `BlackDiamonds.toc`. Модуль обязан быть объявлен раньше, чем его импортируют.

```
embeds.xml                      LibStub, CallbackHandler-1.0, AceLocale-3.0
Localization/Localization.xml   enUS, ruRU

Libs/BlackDiamondsLoader        CreateModule / ImportModule / PopulateGlobals
Libs/BlackDiamondsTimer         отложенные вызовы на одном OnUpdate

Core/BlackDiamondsConstants     ID камней, слоты, опкод, дефолты
Core/BlackDiamondsConfig        доступ к дефолтам и группам камней
Core/BlackDiamondsDatabase      BlackDiamondsDB, профиль по "Имя - Реалм"
Core/BlackDiamondsRuntime       контекст сессии

Api/BlackDiamondsServer         очередь ACMSG_REMOVE_SOCKET_FROM_ITEM
Api/BlackDiamondsMerchant       поиск товара по ID, определение ветки вендора

Domain/BlackDiamondsGems        классификация камней, сбор из сумок и экипировки
Domain/BlackDiamondsSockets     RemoveAll / InsertAll / SwapAll
Domain/BlackDiamondsEquipSet    обёртка EquipmentManager_EquipSet

UI/BlackDiamondsBuyButton       кнопка покупки одного камня
UI/BlackDiamondsVendorFrame     панель у MerchantFrame

Core/BlackDiamondsEventHandler  регистрация и привязка событий
Core/BlackDiamondsSlash         /bd
Core/BlackDiamondsBootstrap     старт

BlackDiamonds.lua               точка входа
```

## Инициализация

1. `BlackDiamonds.lua` создаёт фрейм, зовёт `BlackDiamondsLoader:PopulateGlobals()` и `Bootstrap:Start(frame, addonName)`.
2. `Bootstrap:Start` вычисляет `charKey`, регистрирует `ADDON_LOADED` и `PLAYER_LOGIN`.
3. По `ADDON_LOADED` своего имени плюс `IsLoggedIn()` вызывается `OnPlayerLogin` — ровно один раз, флаг `private.started`.
4. `OnPlayerLogin` открывает БД, инициализирует `Server`, ставит диспетчер событий, наполняет `Runtime`, зовёт `EventHandler:OnAddonReady` и регистрирует slash.
5. `EventHandler:OnAddonReady` подписывается на `MERCHANT_SHOW/CLOSED/UPDATE` и `BAG_UPDATE`, затем `EquipSet:ScheduleInstall()`.

## Потоки данных

**Покупка.** `BuyButton.onClick` → `Merchant:IsCuttingVendor()` → `Merchant:Buy(id, upgradeId, amount)` → `FindIndex` по `GetMerchantItemLink` → `BuyMerchantItem(index, 1)` нужное число раз.

**Вынимание.** `Sockets:RemoveAll(cb)` → `Gems:CollectSocketed()` собирает `{bag, slot, index}` по экипировке (`bag = -1`) и сумкам → `Server:RemoveSockets(entries, cb)` шлёт первый опкод, остальные по `CHAT_MSG_ADDON`, на опустошении дёргает `cb(true)`; при таймауте шага — `cb(false)`.

**Вставка.** `Sockets:InsertAll(cb)` → `Gems:CollectLoose()` раскладывает камни по трём пулам → на каждый занятый слот ставится таймер с шагом `SOCKET_STEP`; обработчик выходит сразу, если пулы пусты, иначе открывает гнёзда, заполняет свободные и закрывает окно.

**Смена сета.** `EquipmentManager_EquipSet(name)` перехвачен → `RemoveAll` → оригинал → пауза `EQUIP_SETTLE_DELAY` → `InsertAll`. Флаг `inProgress` не даёт рекурсии.

**Панель.** `MERCHANT_SHOW/UPDATE` → `VendorFrame:Update()` → проверка конфига и `IsCuttingVendor()` → ленивое создание фрейма → `Refresh()` обновляет счётчики и подсветку кнопок. `BAG_UPDATE` дёргает только `Refresh()`.
