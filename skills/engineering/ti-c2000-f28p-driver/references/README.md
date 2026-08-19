# TI C2000 F28P References & Register Definitions

此目錄用於存放 TI C2000 F28P 系列 (如 F28P550x, F28P650x) 的暫存器描述檔與硬體參考資料，供 AI 在生成/審查底層驅動與暫存器操作時進行事實查證 (Fact Check)。

### 建議放置檔案：
1. **TargetDB XML 檔**：來自 Code Composer Studio (CCS) `ccs/ccs_base/common/targetdb/devices/` 及 `modules/`（如 `TMS320F28P650x.xml`、`TMS320F28P550x.xml`）。
2. **C2000Ware Register Headers**：`f28p650x_*.h`、`f28p550x_*.h` 或 `inc/hw_*.h`。
