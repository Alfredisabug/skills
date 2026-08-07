---
name: python-clean-architecture-gui
description: 針對 Python 桌面應用程式（如 PySide6 / PyQt6）的 Clean Architecture 與 DDD (Domain-Driven Design) 實作指引，強調領域邏輯與 UI 框架的絕對解耦。
---

# 核心架構原則 (Core Architecture Principles)

當開發 Python GUI 應用程式時，必須嚴格遵守以下 Clean Architecture 與 DDD 規範。目的是確保核心商業邏輯（Domain Layer）完全不依賴於任何特定的 UI 框架（如 PySide/PyQt），從而實現高可測試性與可重用性。

## 1. 嚴禁全域變數 (No Global State)
- **禁止使用全域變數**來傳遞系統狀態、資料庫連線或配置設定。
- 所有的依賴項與狀態，必須在應用程式的進入點（Composition Root，通常是 `main.py`）進行初始化。
- 必須透過**建構子注入 (Constructor Injection)** 的方式，將依賴項從上而下傳遞給各個 Controller、UseCase 或 Service。

## 2. 純淨的領域層 (Pure Domain Layer)
- Domain Model 與 UseCase 內部**絕對不允許**引入 `PySide6`、`PyQt6` 或是任何 UI 相關的模組。
- 業務邏輯必須是純 Python (Pure Python) 實作。
- UseCase 不應該知道是誰呼叫了它，也不應該直接操作 UI 元件。

## 3. 解耦的事件驅動 (Observer Pattern & Signal Adapter)
- GUI 的更新必須基於事件驅動，但 Domain 不能使用 Qt 的 Signal/Slot。
- Domain/UseCase 處理完畢後，應透過純 Python 的 Callbacks 或 Observer 模式（如 `threading.Event`、標準 callback functions）來發送通知。
- **GUI Controller 扮演轉接器 (Adapter)**：它負責將 Domain 傳來的純 Python Callback，轉換並觸發對應的 Qt Signal，最後再由 Qt Signal 在主執行緒 (Main Thread) 中安全地更新 UI 畫面。

---

# 程式碼範例 (Code Examples)

## ❌ 不正確的寫法 (Incorrect)
在 UI 元件中直接寫入商業邏輯、查詢資料庫，甚至在 Domain 中耦合了 Qt Signal，並依賴全域變數。

```python
# global_state.py
db_connection = None  # ❌ 依賴全域狀態

# usecase.py
from PySide6.QtCore import Signal  # ❌ Domain 層依賴了 UI 框架

class LoginUseCase:
    success_signal = Signal()
    
    def execute(self, username, password):
        from global_state import db_connection # ❌ 存取全域變數
        # 直接執行邏輯...
        self.success_signal.emit()

# main_window.py
class MainWindow(QMainWindow):
    def on_login_clicked(self):
        # ❌ UI 直接處理邏輯，未透過 UseCase
        if self.username_input.text() == "admin": 
            print("Login success")
```

## ✅ 正確的寫法 (Correct)
使用建構子注入，並將純 Python Callback 轉換為 Qt Signal 以更新 UI。

```python
# --- Domain Layer (Pure Python) ---
class LoginUseCase:
    def __init__(self, auth_repository):
        # ✅ 建構子注入依賴
        self.auth_repository = auth_repository

    def execute(self, username, password, on_success_callback, on_fail_callback):
        # ✅ 使用純 Python Callback，不依賴任何 Qt 模組
        if self.auth_repository.login(username, password):
            on_success_callback(username)
        else:
            on_fail_callback("Invalid credentials")


# --- Presentation / Infrastructure Layer (PySide6) ---
from PySide6.QtCore import QObject, Signal

class LoginController(QObject):
    # ✅ 在 Controller 層定義 Qt Signal，用於跨執行緒安全更新 UI
    login_success = Signal(str)
    login_failed = Signal(str)

    def __init__(self, usecase: LoginUseCase, view):
        super().__init__()
        self.usecase = usecase
        self.view = view
        
        # 綁定 UI 事件到 Controller
        self.view.login_button.clicked.connect(self.handle_login)
        # 綁定 Signal 到 UI 更新方法
        self.login_success.connect(self.view.show_success_message)
        self.login_failed.connect(self.view.show_error_message)

    def handle_login(self):
        username = self.view.username_input.text()
        password = self.view.password_input.text()
        
        # ✅ 定義 Python Callback，轉換發送為 Qt Signal
        def on_success(user):
            self.login_success.emit(user)
            
        def on_fail(error_msg):
            self.login_failed.emit(error_msg)
            
        # ✅ 將 UI 請求委託給 Domain
        self.usecase.execute(username, password, on_success, on_fail)


# --- Composition Root (main.py) ---
def main():
    app = QApplication([])
    
    # ✅ 在最外層統一初始化與注入 (No Global Variables)
    repo = AuthRepository() 
    usecase = LoginUseCase(auth_repository=repo)
    view = LoginWindow()
    controller = LoginController(usecase=usecase, view=view)
    
    view.show()
    app.exec()
```
