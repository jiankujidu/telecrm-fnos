/// 全局常量配置
class Constants {
  /// 主题色（与截图一致 绿色）
  static const int primaryColorValue = 0xFF21C17A;

  /// 后端接口基址（首次安装时的默认值，仅作占位）
  /// 真机必须在登录页或「我的 - 服务器地址」里改成飞牛/服务器的实际地址，例如：
  ///   http://192.168.1.100:18080/api
  /// 注意：必须以 /api 结尾，端口用部署时实际端口（飞牛默认 18080）
  static const String baseUrl = 'http://192.168.1.100:18080/api';

  /// 登录页服务器地址输入框的示例文案
  static const String serverUrlExample = 'http://192.168.1.100:18080/api';

  /// 免登录开关：false = 打开 App 必须先登录（服务器地址 + 账号密码）
  /// 连不上服务器时会明确提示，不再静默进入离线态
  static const bool autoLogin = false;

  /// 免登录自动使用的演示账号
  static const String demoPhone = '13800000001';
  static const String demoPassword = '123456';

  /// 离线体验态使用的本地占位 token（不写盘，下次启动仍会重试真实登录）
  static const String offlineToken = 'offline-demo-token';

  /// 快捷备注默认上限
  static const int maxQuickNotes = 8;

  /// 单个快捷备注最大汉字数
  static const int maxQuickNoteLength = 4;

  /// 文件导入单次上限
  static const int maxImportCount = 5000;

  /// 支持导入的文件后缀
  static const List<String> importExtensions = ['xls', 'xlsx', 'csv', 'txt'];
}
