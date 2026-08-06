---
name: pyside6-gui-generator
description: 當使用者要求設計、撰寫或重構 PyQt6 / PySide6 桌面應用程式 GUI 畫面與架構時使用。
disable-model-invocation: false
---

# SKILL: PyQt6 / PySide6 Desktop GUI Generator

## 🎯 核心原則與目標

1. **邏輯與介面嚴格分離 (Separation of Concerns)**
   - 所有 UI 畫面配置與視覺呈現，統一在專屬 UI 類別（例如 `MainView(QMainWindow)` 或 `SettingsWidget(QWidget)`）中實作。
   - 業務邏輯、資料處理、網路通訊與背景任務 **嚴禁** 混在 UI 視窗類別中，需透過 `QThread` 與 `pyqtSignal` / `Signal` 拋出事件與狀態。

2. **禁止寫死絕對尺寸與座標 (No Absolute Geometries)**
   - **嚴禁** 對一般控制項 (QWidget) 使用 `move(x, y)` 或 `setGeometry(x, y, w, h)` 進行手動排版。
   - 必須 100% 採用 `QBoxLayout` (VBox/HBox)、`QGridLayout` 或 `QFormLayout` 來自動回應視窗縮放。

3. **現代化 QSS 樣式表規範 (Modern Design System)**
   - 必須透過獨立的 QSS 樣式表或 `setStyleSheet()` 管理視覺。
   - 採用 **Material Design 精神的科技黑白風格 (Tech Black & White)**：強調極簡配色、扁平化、高對比度，捨棄複雜漸層。

---

## 🧩 元件複用規範 (Component Reuse Standard)

當建立可複用的子元件 (Sub Widgets) 時，必須嚴格遵守以下守則：

1. **笨元件模式 (Dumb Components)**：
   - 複用元件內部 **嚴禁** 處理 API 請求、資料庫讀寫或複雜的業務邏輯。
   - 它只負責接收資料（透過方法）來顯示，並將使用者的操作（如點擊、輸入）原封不動地轉發出去。
2. **基於信號的通訊 (Signal-Based Communication)**：
   - 元件與外部（父元件或邏輯層）的溝通 **強制只能透過** `pyqtSignal` / `Signal`。
   - 嚴禁外部直接存取元件內部的 UI 控制項（例如 `widget.button.setText()`），降低耦合。
3. **建構子規範**：
   - 所有的元件初始化時，建構子必須包含 `parent=None` 作為預設參數（`def __init__(self, parent=None):`），以確保它可以被靈活嵌入任何 Layout 之中。

---

## 🚀 執行步驟 (Workflow Steps)

當收到產生 GUI 畫面的要求時，必須依序執行以下步驟：

1. **需求分析與佈局規劃 (Plan & Layout Tree)**：
   - **【決策點】** 在撰寫任何 UI 程式碼之前，先向使用者提出文字版的「UI 佈局樹 (Layout Tree)」規劃草案（參考下方的版面規劃指南）。
   - 與使用者確認佈局結構無誤後，才允許進入下一步寫 Code。
2. **生成元件與介面 (Generate UI Code)**：
   - 依照確認的佈局樹，生成遵循「元件複用規範」的骨架程式碼。
3. **套用樣式與檢驗 (Apply Styling & Self-Check)**：
   - 套用科技黑白風格 QSS。
   - 在輸出程式碼前，自行在心中跑過一遍下方的「自我檢查清單」。

---

## 📋 開發自我檢查清單 (GUI Self-Checklist)

在提供任何 GUI 程式碼或重構建議給使用者前，必須自行查核以下項目：
- [ ] **流程確認**：寫 Code 前是否已獲得使用者對「UI 佈局樹」的許可？
- [ ] **無絕對座標**：是否完全沒有使用 `move()` 或 `setGeometry()`？
- [ ] **通訊解耦**：元件對外溝通是否 100% 採用 `Signal`？沒有互相呼叫內部方法？
- [ ] **無業務邏輯**：UI 類別（Dumb Component）中是否不包含任何耗時運算或 I/O 操作？
- [ ] **建構子正確**：`__init__` 是否皆帶有 `parent=None` 並正確呼叫 `super().__init__(parent)`？

---

## 📐 版面規劃指南 (Layout Hierarchy Standard)

規劃 UI 佈局樹草案時，請參考此三層式架構：

```text
+-------------------------------------------------------------------+
| Top Action Bar / Toolbar (QHBoxLayout)                            |
+------------------------------+------------------------------------+
| Navigation / Sidebar Panel   | Main Content Area                  |
| (QVBoxLayout or QListWidget) | (QStackedWidget or QTabWidget)     |
|                              |                                    |
|                              |  +------------------------------+  |
|                              |  | Form / Data Grid (QGrid)     |  |
|                              |  +------------------------------+  |
|                              |  | Status Logs / Chart          |  |
|                              |  +------------------------------+  |
+------------------------------+------------------------------------+
| Bottom Status Bar (QHBoxLayout / QStatusBar)                      |
+-------------------------------------------------------------------+
```

### 控制項選擇對照表
- **表單與設定項目** ➔ 優先選用 `QFormLayout` (`addRow("標籤:", widget)`)。
- **多頁面切換** ➔ 優先選用 `QStackedWidget`（搭配導覽列切換）或 `QTabWidget`。
- **大量資料顯示** ➔ 優先選用 `QTableView` + 自訂 `QAbstractTableModel`，避免記憶體暴漲。

---

## 🎨 QSS 樣式表與樣板 (Templates)

### 1. 笨元件代碼樣板 (Dumb Component Boilerplate)
```python
from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton
from PySide6.QtCore import Signal

class ReusableWidget(QWidget):
    # 1. 定義對外信號
    action_requested = Signal(str)

    def __init__(self, parent=None):
        # 2. 建構子帶入 parent=None
        super().__init__(parent)
        self._setup_ui()

    def _setup_ui(self):
        # 3. 強制使用 Layout，禁止 move()
        layout = QVBoxLayout(self)
        self.btn = QPushButton("Action")
        
        # 4. 內部事件連接到對外信號 (不處理業務邏輯)
        self.btn.clicked.connect(lambda: self.action_requested.emit("data"))
        layout.addWidget(self.btn)
```

### 2. 科技黑白風格 QSS (Tech Black & White)
```css
/* --- 全局基礎設定 --- */
QWidget {
    background-color: #121212;
    color: #E0E0E0;
    font-family: "Segoe UI", "Roboto", sans-serif;
    font-size: 10pt;
}

/* --- 按鈕 --- */
QPushButton {
    background-color: #2D2D2D;
    color: #FFFFFF;
    border: 1px solid #404040;
    border-radius: 4px;
    padding: 6px 16px;
}
QPushButton:hover {
    background-color: #3D3D3D;
    border: 1px solid #5A5A5A;
}
QPushButton:pressed {
    background-color: #555555;
}

/* --- 輸入框與下拉選單 --- */
QLineEdit, QComboBox, QSpinBox {
    background-color: #1E1E1E;
    color: #FFFFFF;
    border: 1px solid #333333;
    border-radius: 4px;
    padding: 4px 8px;
}
QLineEdit:focus, QComboBox:focus, QSpinBox:focus {
    border: 1px solid #757575;
}

/* --- 面板與邊框 --- */
QFrame#NavigationPanel {
    background-color: #181818;
    border-right: 1px solid #282828;
}
```
