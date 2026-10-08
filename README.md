# 电销CRM —— 飞牛OS（fnOS）应用中心安装包

飞牛 OS 应用中心的 `.fpk` 安装包，装完就是飞牛桌面上的一个正式应用：有图标、能启停、能卸载，
数据由飞牛统一托管。

- 应用名：**电销CRM**（`telecrm`）　当前版本：**1.0.1**
- 镜像：`jiankujidu/telecrm:1.0.1`（Java 后端 + 管理后台合一，单镜像；ARM 机型用 `1.0.1-arm64`）
- 端口：**18080**　后台账号：`13800000001` / `123456`
- 打包工具：飞牛官方 `fnpack 1.2.3`（手写包结构会被应用中心拒绝，必须用官方工具）

## v1.0.1 更新内容

1. **移动端登录页支持填写服务器地址**，并带「测试连接」，解决真机读不出数据的问题
   （旧版默认地址 `10.0.2.2` 只有安卓模拟器能用，真机不可达）。
2. **新增数据导出**：后台「客户」「通话记录」页各加了「导出 Excel」按钮，
   后端新增 `/api/export/customers`、`/api/export/call-records`（Apache POI 生成 .xlsx）。
3. **离线态提示**：未连接服务器时首页顶部有醒目提示条，点击直达设置。

---

## 一、下载哪个包

| 你的飞牛机型 | 文件 |
|---|---|
| 不确定 / 前两个都提示不符 | **[`fpk/telecrm_1.0.1_all.fpk`](fpk/telecrm_1.0.1_all.fpk)**（platform=all，跳过架构校验） |
| 常见 x86 主机 / x86 NAS | **[`fpk/telecrm_1.0.1_x86.fpk`](fpk/telecrm_1.0.1_x86.fpk)** |
| ARM 机型（ARM 盒子、瑞芯微/晶晨） | **[`fpk/telecrm_1.0.1_arm.fpk`](fpk/telecrm_1.0.1_arm.fpk)**（arm64 镜像） |

查机型：飞牛桌面 → 系统设置 → 关于/设备信息看处理器；或 SSH 执行 `uname -m`，
`x86_64` 选 x86 包，`aarch64` 选 arm 包。

## 二、安装（5 步，约 3 分钟）

1. 飞牛桌面 → **Docker** → 确认 Docker 已开启。
2. 把选好的 `.fpk` 拷到飞牛（网页上传 / SMB / U 盘都行）。
3. 飞牛桌面 → **应用中心** → 右上角 **手动安装** → 选该 `.fpk`。
4. 按提示确认权限与端口（默认 18080）。
5. 等状态变「**运行中**」（首次拉镜像 + 初始化数据库，1–3 分钟）。

桌面会出现「电销CRM」图标，点击直开后台；也可以直接访问 `http://飞牛IP:18080/`。

## 三、手机端

免登录版 APK 装好后，**登录页填写服务器地址**：

```
http://飞牛IP:18080/api
```

结尾必须是 `/api`，端口用实际部署端口（飞牛默认 18080），手机与飞牛需在同一局域网。
填完可点右侧信号图标「测试连接」，显示「连接成功」再登录。

## 四、数据导入与导出

- **导入**：后台客户模块的文件导入（xls / xlsx / csv / txt）。
- **导出**：客户页、通话记录页工具栏的「导出 Excel」，按当前筛选范围导出（我的 / 团队），
  导出字段见 `docs/电销CRM-改进设计方案.md`。

## 五、装不上怎么办

1. 换 **通用包**（`platform=all`）再试 —— 最常见原因就是架构不匹配。
2. 系统设置 → 更新 fnOS 到较新版本。
3. 应用中心 → 确认允许第三方 / 手动安装。
4. SSH 进飞牛看拒绝原因：`tail -f /var/log/trim_app_center/*`

## 六、方案B：不用 .fpk，直接 Compose 部署（一定可用）

飞牛桌面 → Docker → **Compose** → 新增项目，名称 `telecrm`，粘贴
[`compose/docker-compose.yml`](compose/docker-compose.yml) 的内容 → 确定。

访问同样是 `http://飞牛IP:18080/`。镜像和数据结构与 .fpk 完全相同，只是没有桌面图标。

## 七、目录说明

```
fpk/                     三个架构的安装包（直接用）
compose/                 方案B 的 docker-compose.yml
source_telecrm/          官方 fnpack 工程源码（改这里再重新打包）
  ├── manifest           应用身份（appname/version/platform/service_port/checksum…）
  ├── app/docker/        容器编排（mysql:8.0 + jiankujidu/telecrm）
  ├── app/ui/            桌面入口配置与图标
  ├── cmd/               生命周期脚本（main 及 install/upgrade/uninstall/config 钩子）
  ├── config/            privilege（运行用户）+ resource（数据目录、docker 项目）
  └── ICON.PNG / ICON_256.PNG
docs/                    改进设计方案（问题诊断 + 迭代路线）
tools/                   打包与图标脚本
```

## 八、自己重新打包

需要 Linux / macOS，会自动下载官方 `fnpack`：

```bash
cd tools
./build.sh            # 生成 x86 / all / arm 三个包到 ../build/
```

改端口：编辑 `source_telecrm/app/docker/docker-compose.yaml` 里的 `18080:8080`，
以及 `source_telecrm/app/ui/config` 里的 `"port": "18080"`。
