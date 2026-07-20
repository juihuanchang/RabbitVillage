# B 組功能實作說明

## 完成內容

本次使用 **GDScript** 建立兔子資料、森林活動、活動執行流程，以及真實時間判斷功能。

建立的架構如下：

```text
models/
├── rabbit_data.gd
├── activity_data.gd
└── active_activity_data.gd

systems/
├── rabbit/
│   └── rabbit_manager.gd
├── activity/
│   └── activity_manager.gd
└── game/
    └── time_manager.gd
```

## 1. RabbitData

檔案：`models/rabbit_data.gd`

記錄每隻兔子的基本狀態：

- `rabbit_name`：名字
- `hunger`：飢餓／飽食程度，範圍為 0～100
- `mood`：心情，範圍為 0～100
- `energy`：體力，範圍為 0～100
- `is_away`：是否正在外出

心情、飢餓與體力會自動限制在 0～100，不會出現負數或超過 100。

## 2. ActivityData

檔案：`models/activity_data.gd`

記錄活動的設定：

- 活動名稱
- 活動所需秒數
- 體力變化
- 心情變化

已提供森林散步活動：

| 項目 | 數值 |
| --- | ---: |
| 名稱 | 森林散步 |
| 時間 | 30 秒 |
| 體力 | -5 |
| 心情 | +3 |

可以使用 `ActivityData.create_forest_walk()` 建立森林散步資料。

## 3. ActiveActivityData

檔案：`models/active_activity_data.gd`

記錄目前正在進行的活動：

- 哪一隻兔子正在活動
- 正在進行哪一個活動
- 活動開始時間
- 活動結束時間
- 剩餘秒數

結束時間使用真實世界的 Unix 時間，因此不是單純依靠畫面上的計時器。

## 4. ActivityManager

檔案：`systems/activity/activity_manager.gd`

負責完整活動流程：

```text
開始活動
    ↓
檢查兔子是否已外出、體力是否足夠
    ↓
標記兔子為外出
    ↓
依真實時間倒數
    ↓
活動完成，套用體力與心情變化
    ↓
取消外出狀態，兔子回村
```

提供的主要方法：

- `start_activity(rabbit, activity)`：開始指定活動
- `start_forest_walk(rabbit)`：直接開始森林散步
- `check_for_completion()`：讀取存檔或回到遊戲時，立即檢查活動是否完成

活動開始前會檢查：

- 目前是否已有活動進行中
- 兔子是否已經外出
- 兔子的體力是否足以支付活動消耗

提供的訊號：

- `activity_started`：活動開始
- `countdown_changed`：倒數時間更新
- `activity_completed`：活動完成
- `rabbit_returned`：兔子回村

介面可以連接這些訊號來顯示倒數、更新兔子數值或播放回村動畫。

## 5. TimeManager

檔案：`systems/game/time_manager.gd`

負責：

- `get_now()`：取得現在的真實時間
- `is_completed(ends_at)`：判斷指定的結束時間是否已經到達

因為使用系統真實時間，即使玩家暫時離開遊戲，重新進入後仍可判斷活動是否已經完成。

## 6. RabbitManager

檔案：`systems/rabbit/rabbit_manager.gd`

負責管理村莊內的兔子資料：

- 新增兔子
- 按名字取得兔子
- 取得全部兔子
- 移除兔子
- 防止加入同名兔子

## 基本使用範例

```gdscript
var rabbit := RabbitData.new("小麥", 80, 70, 20)
var activity_manager := ActivityManager.new()

add_child(activity_manager)

if activity_manager.start_forest_walk(rabbit):
	print("小麥開始森林散步")
else:
	print("目前無法開始活動")
```

森林散步完成後，範例中的兔子會：

- 體力由 20 變成 15
- 心情由 70 變成 73
- `is_away` 恢復為 `false`

## 檢查結果

已使用 Godot 4.7 的無視窗模式載入專案，所有新增的 GDScript 均可通過解析，沒有語法錯誤。

## 7. 套用到兔子角色

檔案：`player/player.gd`

`Player.tscn` 已改用 GDScript，角色建立時會自動：

- 建立自己的 `RabbitData`
- 建立 `ActivityManager`
- 連接活動開始、倒數、完成與回村訊號
- 按下 `F` 時開始森林散步
- 外出時隱藏角色並停用碰撞
- 30 秒後套用體力與心情變化，重新顯示角色

角色使用俯視角四方向移動，不包含重力與跳躍。方向鍵可控制上下左右。

也可以讓介面按鈕呼叫角色的 `start_forest_walk()` 方法，不一定要使用鍵盤。

## 8. 遊戲內資料介面

主場景左上角會顯示兔子資料與森林散步資料：

- 名字、飢餓、心情、體力、是否外出
- 森林散步、30 秒、體力 -5、心情 +3
- 活動進行時的剩餘秒數

玩家可以點擊「開始森林散步」按鈕或按下 `F` 開始活動。數值、外出狀態和按鈕會隨活動流程自動更新。
