# 电销CRM 移动端（Flutter）

复刻「电销帮」的自动外呼 / 电销管理 App，与 `server/` 下的 Spring Boot 后端对接，形成可运行闭环。

## 技术栈
Flutter 3.22+ / Dart 3.4+ · Riverpod 状态管理 · go_router 路由 · dio 网络 · file_picker 文件导入 · permission_handler 权限

## 运行步骤
1. `flutter pub get`
2. 配置后端地址：`lib/config/constants.dart` 中的 `baseUrl`
   - Android 模拟器访问本机后端：`http://10.0.2.2:8080/api`
   - 真机：改为电脑局域网 IP，如 `http://192.168.x.x:8080/api`
3. 先启动后端（见根目录 `README.md`：`docker compose up` 或 `mvn spring-boot:run`）
4. `flutter run`

## 演示账号（已预置 BCrypt 密码）
- `13800000001` / `123456`（团队主）
- `13800000002` / `123456`、`13800000003` / `123456`

## 主链路（已打通）
1. 登录 → 首页拉取「我的任务」（`/call-task/list`）
2. 首页「文件导入」→ 选 `xls/xlsx/csv/txt` → 上传 `/call-task/import` 生成任务
3. 点击任务 → 自动拨号页按明细顺序拨打（`/call-task/{id}/items`）
4. 每次拨打后弹窗标记（空号 / 未接通 / 已接通 / 添加客户 + 快捷备注）→ 提交 `/call-record`
5. 标记后自动刷新并推进下一条，顶部进度条同步
6. 「客户」页三 Tab（我的 / 团队 / 公海）对接 `/customer/list`
7. 「我的」页显示登录态，可退出登录

## 已对接接口
| 方法 | 路径 | 调用点 |
|---|---|---|
| POST | `/auth/login` | 登录页 |
| POST | `/call-task/import` | 文件导入页 |
| GET | `/call-task/list` | 首页任务列表 |
| GET | `/call-task/{id}/items` | 自动拨号明细 |
| POST | `/call-record` | 标记弹窗 |
| GET | `/customer/list?scope=mine|team|public` | 客户页 |
