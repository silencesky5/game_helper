import '../../domain/automation/automation_state.dart';
import '../../infrastructure/adb/adb_manager.dart';

/// Centralized Traditional Chinese dashboard copy.
///
/// UI widgets consume these constants instead of embedding display strings so a
/// future locale-backed implementation can replace this class without touching
/// dashboard layout logic.
class DashboardStrings {
  const DashboardStrings._();

  static const String platformTitle = 'Game Helper 平台';
  static const String statistics = '統計';
  static const String logs = '紀錄';
  static const String adbStatus = 'ADB 狀態';
  static const String version = '版本';
  static const String connectedDevices = '已連線裝置';
  static const String executablePath = '執行檔位置';
  static const String lastScan = '最後掃描時間';
  static const String rescanAdb = '重新掃描 ADB';
  static const String startAllAutomation = '全部開始';
  static const String stopAll = '全部停止';
  static const String restartAll = '全部重新啟動';
  static const String adbConnected = 'ADB 已連線';
  static const String adbNotFoundMessage = '找不到 ADB 執行檔，請設定 adb.exe 路徑。';
  static const String adbAvailableNoDeviceMessage = 'ADB 可用，但尚未偵測到 Android 裝置。';
  static const String adbExecutionFailedMessage = 'ADB 執行失敗，請檢查 ADB 路徑與權限。';
  static const String screenshotReady = '截圖完成';
  static const String screenshotMissing = '尚無截圖';
  static const String deviceName = '裝置名稱';
  static const String deviceNameHint = '裝置 #1';
  static const String taskLogic = '運行邏輯';
  static const String noAutomationActions = '目前插件尚未提供自動化動作。';
  static const String priority = '優先順序';
  static const String moveUp = '上移';
  static const String moveDown = '下移';
  static const String selectAll = '全部勾選';
  static const String clearAll = '全部取消';
  static const String settings = '設定';
  static const String settingsWithIcon = '⚙ 設定';
  static const String deviceId = '裝置 ID';
  static const String yes = '是';
  static const String no = '否';
  static const String internalName = '內部名稱';
  static const String author = '作者';
  static const String pluginLog = '插件紀錄';
  static const String seeRuntimeLogs = '請見執行紀錄';
  static const String debug = '除錯';
  static const String enabledFromDashboard = '可由儀表板動作啟用';
  static const String reloadPlugin = '重新載入插件';
  static const String comingSoon = '即將推出';
  static const String ocrTest = 'OCR 測試';
  static const String imageTest = '圖片測試';
  static const String close = '關閉';
  static const String deviceInfo = '裝置資訊';
  static const String androidVersion = 'Android 版本';
  static const String resolution = '解析度';
  static const String brand = '品牌';
  static const String model = '型號';
  static const String serial = '序號';
  static const String screenshot = '畫面截圖';
  static const String captureFailed = '擷取失敗';
  static const String ready = '完成';
  static const String cpu = 'CPU';
  static const String na = '不適用';
  static const String memory = '記憶體';
  static const String pluginVersion = '插件版本';
  static const String lastCapture = '最後截圖時間';
  static const String imageSize = '圖片尺寸';
  static const String renameDevice = '重新命名裝置';
  static const String runtime = '執行狀態';
  static const String automationNotStarted = '自動化尚未開始。\n按下全部開始即可開始。';
  static const String currentTask = '目前任務';
  static const String nextTask = '下一步';
  static const String currentScene = '目前畫面';
  static const String elapsedTime = '執行時間';
  static const String noActiveTask = '沒有進行中的任務';
  static const String unknown = '未知';
  static const String automationError = '自動化錯誤';
  static const String noRuntimeErrors = '沒有執行錯誤';
  static const String reason = '原因';
  static const String runtimeReportedFailure = '執行狀態回報失敗';
  static const String retryCount = '重試次數';
  static const String lastAction = '最後動作';
  static const String timestamp = '時間';
  static const String todaysProgress = '今日任務進度';
  static const String completed = '已完成';
  static const String completionRate = '完成率';
  static const String unableToLoadScreenshot = '無法載入截圖。';
  static const String screenshotViewer = '截圖檢視器';
  static const String shotTime = '拍攝時間';
  static const String refreshScreenshot = '重新截圖';
  static const String viewOriginal = '檢視原圖';
  static const String saveImage = '儲存圖片';
  static const String screenshotFailed = '截圖失敗';
  static const String noScreenshotAvailable = '尚無畫面截圖';
  static const String recentEvents = '最近事件';
  static const String noRecentEvents = '沒有最近事件';
  static const String performance = '效能';
  static const String ocr = 'OCR';
  static const String pluginStatus = '插件狀態';
  static const String reservedDiagnostics = '預留給未來平台診斷。';
  static const String automationDebug = '進階除錯';
  static const String debugMode = '除錯模式';
  static const String detectScene = '偵測畫面';
  static const String detectGrowStone = '偵測成長石';
  static const String testTap = '測試點擊';
  static const String found = '已找到';
  static const String confidence = '信心值';
  static const String left = '左';
  static const String top = '上';
  static const String right = '右';
  static const String bottom = '下';
  static const String adbScreenshot = 'ADB 截圖';
  static const String startAutomation = '開始自動化';
  static const String detectCharacter = '偵測角色';
  static const String currentStatus = '目前狀態';
  static const String zoomOriginalSize = '縮放 / 原始尺寸';

  static String adbMessage(String message) => switch (message) {
        'ADB executable not found. Please configure adb.exe path.' => adbNotFoundMessage,
        'ADB is available. No Android device detected.' => adbAvailableNoDeviceMessage,
        'ADB execution failed. Check adb path and permissions.' => adbExecutionFailedMessage,
        _ => message,
      };

  static String adbStatusLabel(AdbRuntimeStatus status) => switch (status) {
        AdbRuntimeStatus.notFound => '找不到 ADB',
        AdbRuntimeStatus.invalid => 'ADB 無效',
        AdbRuntimeStatus.available => 'ADB 可用',
        AdbRuntimeStatus.connected => adbConnected,
        AdbRuntimeStatus.noDevice => '未連接裝置',
      };

  static String automationState(AutomationState state) => switch (state) {
        AutomationState.running => '執行中',
        AutomationState.paused => '已暫停',
        AutomationState.completed => completed,
        AutomationState.failed => '錯誤',
        AutomationState.stopped => '等待中',
        AutomationState.idle => '待命',
      };

  static String automationBadge(AutomationState state) => switch (state) {
        AutomationState.failed => automationError,
        AutomationState.paused => '自動化暫停',
        AutomationState.running => '自動化執行中',
        AutomationState.stopped => '自動化等待中',
        AutomationState.completed => '自動化已完成',
        AutomationState.idle => '自動化待命',
      };
}
