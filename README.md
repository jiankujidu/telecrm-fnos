# 电销CRM —— 飞牛OS（fnOS）应用 + 全套源码

飞牛 OS 应用中心的 `.fpk` 安装包 + 完整源码（Java 后端 / Vue3 管理后台 / Flutter 手机 App）。
装完就是飞牛桌面上的一个正式应用：有图标、能启停、能卸载，数据由飞牛统一托管。

- 应用名：**电销CRM**（`telecrm`）　当前版本：**1.1.0**
- 镜像：`jiankujidu/telecrm:1.1.0`（Java 后端 + 管理后台合一，单镜像；ARM 机型用 `1.1.0-arm64`）
- 端口：**18080**　后台账号：`13800000001` / `123456`
- 打包工具：飞牛官方 `fnpack 1.2.3`（手写包结构会被应用中心拒绝，必须用官方工具）

---

## v1.1.0 更新内容

| 问题 | 原因 | 处理 |
|---|---|---|
| **画像表不能编辑、不能删** | 后端 `CustomerController` 只有列表/转让接口，**根本没有增删改** | 新增 `customer_profile` 画像表 + 完整增删改接口；后台与 App 都能编辑、删除、批量删除 |
| **电话打不了** | ①Dart 的 `NavigatorService.context` 是 `late` 变量**从未赋值**，点拨号就抛异常；②Manifest 声明 `CALL_PHONE` 却**从未动态申请权限** | 重写拨号服务：先申请权限 → 有权限直拨 / 无权限自动降级唤起拨号界面，保证点了一定有反应；失败有明确提示与「去授权」入口 |
| **只有导入没导出** | 后端缺导出接口 | 客户 / 话单导出 Excel；**客户导出含 30 列画像字段** |
| **APK 免登录** | 之前按要求做的免登录 | **改回强制登录**：必须先填服务器地址 + 账号密码，去掉「先离线看看」 |
| **怕数据丢失** | 没有全量备份 | 新增**数据备份与恢复**：一键导出全库 JSON（15 张表），换机器/重装后上传即恢复，支持覆盖/追加 |

---

## 一、下载哪个包

| 你的飞牛机型 | 文件 |
|---|---|
| 不确定 / 前两个都提示不符 | **[`fpk/telecrm_1.1.0_all.fpk`](fpk/telecrm_1.1.0_all.fpk)**（platform=all，跳过架构校验） |
| 常见 x86 主机 / x86 NAS | **[`fpk/telecrm_1.1.0_x86.fpk`](fpk/telecrm_1.1.0_x86.fpk)** |
| ARM 机型（ARM 盒子、瑞芯微/晶晨） | **[`fpk/telecrm_1.1.0_arm.fpk`](fpk/telecrm_1.1.0_arm.fpk)**（arm64 镜像） |

手机 App：**[`apk/TeleCRM-v1.1.0.apk`](apk/TeleCRM-v1.1.0.apk)**（需登录版，23.5 MB）

查机型：飞牛桌面 → 系统设置 → 关于/设备信息看处理器；或 SSH 执行 `uname -m`，
`x86_64` 选 x86 包，`aarch64` 选 arm 包。

## 二、安装（5 步，约 3 分钟）

1. 飞牛桌面 → **Docker** → 确认 Docker 已开启。
2. 把选好的 `.fpk` 拷到飞牛（网页上传 / SMB / U 盘都行）。
3. 飞牛桌面 → **应用中心** → 右上角 **手动安装** → 选该 `.fpk`。
4. 按提示确认权限与端口（默认 18080）。
5. 等状态变「**运行中**」（首次拉镜像 + 初始化数据库，1–3 分钟）。

桌面会出现「电销CRM」图标，点击直开后台；也可以直接访问 `http://飞牛IP:18080/`。

## 三、手机端（需登录）

装好 APK 后打开，登录页第一项填**服务器地址**：

```
http://飞牛IP:18080/api
```

结尾必须是 `/api`，端口用实际部署端口（飞牛默认 18080），手机与飞牛需在同一局域网。
填完点右侧信号图标「**测试连接**」→ 显示「连接成功」→ 再输入账号密码登录。

## 四、核心功能

### 客户画像（新增）

后台左侧菜单 **客户画像** = 独立的画像表：意向等级 / 行业 / 职位 / 微信 / 预算 / 决策人 /
拨打次数 / 画像标签 / 画像小结，可按意向等级筛选，可编辑、删除、导出。

完整字段：性别、年龄、生日、行业、职位、微信、邮箱、备用电话、省份、城市、意向等级 A–D、
预算、是否决策人、来源渠道、感兴趣产品、客户痛点、在用竞品、下次跟进时间、画像标签、画像小结。

> 第一次点「编辑画像」会自动生成一条空画像。

### 拨号（已修复）

- 客户列表每行右侧有绿色**电话图标**，点击直接拨号
- 客户详情页顶部有 **「拨打电话」** 大按钮
- 自动拨号任务、悬浮窗连拨、未接通重拨均走同一套拨号服务
- 首次拨号会申请「电话」权限；拒绝也能用（会唤起系统拨号界面，手动点一下拨出）

### 数据备份与恢复（新增）

后台 → **数据备份**：

1. **立即备份下载** → `telecrm-backup-日期.json`，含 15 张表全部数据
2. 换机器/重装后选该文件 → **预览文件内容**（核对条数）→ **确认恢复**
   - **覆盖**：清空现有数据后写入，与备份完全一致
   - **追加**：只补进缺失记录，保留现有数据

建议每周备份一次；批量导入、批量删除前先备份。

### 导入 / 导出

- **导入**：后台客户模块文件导入（xls / xlsx / csv / txt）
- **导出**：客户页、通话记录页「导出 Excel」，按当前筛选条件导出

## 五、装不上怎么办

1. 换 **通用包**（`platform=all`）再试 —— 最常见原因就是架构不匹配。
2. 系统设置 → 更新 fnOS 到较新版本。
3. 应用中心 → 确认允许第三方 / 手动安装。
4. SSH 进飞牛看拒绝原因：`tail -f /var/log/trim_app_center/*`

## 六、方案B：不用 .fpk，直接 Compose 部署（一定可用）

飞牛桌面 → Docker → **Compose** → 新增项目，名称 `telecrm`，粘贴
[`compose/docker-compose.yml`](compose/docker-compose.yml) 的内容 → 确定。

## 七、源码目录

```
server/                  Java 后端（Spring Boot 3 + MyBatis-Plus + JWT）
  ├── pom.xml
  ├── Dockerfile
  └── src/main/java/com/telecrm/
        ├── controller/   14 个控制器（Customer / Backup / Export / CallRecord / Report …）
        ├── entity/       16 个实体（含 CustomerProfile 客户画像）
        ├── service/      业务逻辑（含客户增删改与画像读写）
        └── resources/db/ schema.sql + data.sql（启动自动建表 + 演示数据）

admin/                   Vue3 + Element Plus 管理后台
  └── src/
        ├── api/          customer.ts / backup.ts / export.ts …
        ├── views/        customer / profile / backup / records / report / team …
        └── router/

app/                     Flutter 手机端（Android + iOS）
  ├── lib/
  │     ├── api/         customer_api.dart（含画像与增删改）
  │     ├── pages/       customer/customer_edit_page.dart（画像编辑）、dialer …
  │     ├── services/    dialer_service.dart（已修复拨号）
  │     └── models/      customer_profile.dart
  └── android/           原生拨号 MethodChannel（权限降级处理）

deploy/                  一体化运行镜像 Dockerfile
fnos/                    飞牛官方 fnpack 工程源码 + 打包脚本
fpk/                     三个架构的安装包
apk/                     手机 App
docs/                    安装说明与改进设计方案
```

## 八、本地开发

```bash
# 后端
cd server && mvn spring-boot:run          # 需要本地 MySQL

# 前端
cd admin && pnpm install && pnpm dev      # http://localhost:5173

# 手机端
cd app && flutter pub get && flutter run

# 一体化镜像（先打 jar，再构建镜像）
cd server && mvn package -DskipTests && cp target/*.jar ../deploy/app.jar
cd ../deploy && docker build -f Dockerfile.runtime -t jiankujidu/telecrm:1.1.0 .

# 飞牛包（需要 fnpack）
cd fnos && ./build-fpk.sh
```

## 九、API 一览（新增部分）

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/customer/create` | 新建客户（手机号团队内判重） |
| POST | `/api/customer/update` | 编辑客户（null 字段不覆盖） |
| POST | `/api/customer/delete` | 删除 / 批量删除（含画像） |
| GET | `/api/customer/{id}/profile` | 读画像（无则自动建空画像） |
| POST | `/api/customer/{id}/profile` | 保存画像 |
| GET | `/api/customer/profile/list` | 画像表分页（可按意向等级筛选） |
| POST | `/api/customer/{id}/touch-call` | 拨打累计 |
| GET | `/api/backup/export` | 导出全库备份 JSON |
| POST | `/api/backup/preview` | 预览备份文件内容 |
| POST | `/api/backup/import?mode=` | 恢复（overwrite / append） |
