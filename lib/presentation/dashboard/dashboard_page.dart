import 'package:flutter/material.dart';

import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/decision/decision_state.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../app/localization/l10n_extension.dart';
import '../../app/localization/language_manager.dart';
import 'automation_controller.dart';
import 'widgets/start_button.dart';

/// Dashboard entry point for the desktop automation console.
class DashboardPage extends StatefulWidget {
  /// Creates the dashboard page.
  const DashboardPage({super.key, this.controller, this.languageManager});

  /// Controller used to start automation.
  final AutomationController? controller;

  /// Manages runtime locale changes.
  final LanguageManager? languageManager;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AutomationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AutomationController();
    _controller.addListener(_onControllerChanged);
    _controller.initializeDesktopConsole();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AutomationSession> sessions = _controller.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.desktopConsoleTitle),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_controller.running ? context.l10n.runningPipeline : context.l10n.ready)),
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: 0,
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text(context.l10n.dashboard)),
              NavigationRailDestination(icon: Icon(Icons.extension), label: Text(context.l10n.plugins)),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text(context.l10n.settings)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ADBSettingsCard(controller: _controller),
                  const SizedBox(height: 16),
                  if (widget.languageManager != null) ...<Widget>[
                    _SettingsCard(languageManager: widget.languageManager!),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: <Widget>[
                      Text(context.l10n.deviceSessions, style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _controller.detecting ? null : _controller.initializeDesktopConsole,
                        icon: const Icon(Icons.refresh),
                        label: Text(_controller.detecting ? context.l10n.detecting : context.l10n.detectDevices),
                      ),
                      const SizedBox(width: 12),
                      StartButton(onPressed: _controller.running || sessions.isEmpty ? null : _controller.start),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: sessions.isEmpty
                        ? _EmptyDeviceState(detecting: _controller.detecting)
                        : GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.85,
                            children: sessions
                                .map((AutomationSession session) => _DeviceCard(session: session, controller: _controller))
                                .toList(growable: false),
                          ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _LogPanel(logs: _controller.logs),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }
}



class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.languageManager});

  final LanguageManager languageManager;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Text(context.l10n.settings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 24),
            Text(context.l10n.language),
            const SizedBox(width: 12),
            DropdownButton<AppLanguage>(
              value: languageManager.currentLanguage,
              onChanged: (AppLanguage? language) {
                if (language != null) languageManager.changeLanguage(language);
              },
              items: <DropdownMenuItem<AppLanguage>>[
                DropdownMenuItem<AppLanguage>(
                  value: AppLanguage.zhTw,
                  child: Text(context.l10n.traditionalChinese),
                ),
                DropdownMenuItem<AppLanguage>(
                  value: AppLanguage.zh,
                  child: Text(context.l10n.traditionalChinese),
                ),
                DropdownMenuItem<AppLanguage>(
                  value: AppLanguage.en,
                  child: Text(context.l10n.english),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ADBSettingsCard extends StatelessWidget {
  const _ADBSettingsCard({required this.controller});

  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final adbManager = controller.adbManager;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.adbSettings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(context.l10n.adbPath(adbManager.adbPath ?? context.l10n.notDiscovered)),
            Text(context.l10n.adbVersion(adbManager.adbVersion ?? context.l10n.unknown)),
            Text(context.l10n.connectionStatus(adbManager.connectionStatus)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _showADBPathDialog(context),
                  icon: const Icon(Icons.folder_open),
                  label: Text(context.l10n.browse),
                ),
                OutlinedButton.icon(
                  onPressed: controller.testADBConnection,
                  icon: const Icon(Icons.cable),
                  label: Text(context.l10n.testConnection),
                ),
                OutlinedButton.icon(
                  onPressed: controller.rescanADB,
                  icon: const Icon(Icons.search),
                  label: Text(context.l10n.rescan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showADBPathDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.adbManager.adbPath ?? '');
    final path = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n.adbPathTitle),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.adbExePath,
            hintText: r'C:\LDPlayer\LDPlayer9\adb.exe',
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: Text(context.l10n.save)),
        ],
      ),
    );
    textController.dispose();
    if (path != null && path.trim().isNotEmpty) {
      await controller.setADBPath(path);
    }
  }
}

class _EmptyDeviceState extends StatelessWidget {
  const _EmptyDeviceState({required this.detecting});

  final bool detecting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.desktop_windows, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            detecting ? context.l10n.detectingDevicesMessage : context.l10n.noAdbDevicesDetected,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.startLdPlayerHint),
        ],
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.runtimeLogs, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: logs.isEmpty
                ? Text(context.l10n.waitingForEvents)
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (BuildContext context, int index) => Text(
                      logs[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.session, required this.controller});

  final AutomationSession session;
  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final DeviceScreenshot? screenshot = controller.screenshotRepository.latest(session.device.id);
    final DecisionStatus? decision = controller.decisionRepository.statusFor(session.device.id);
    final String pluginName = session.plugin?.name ?? '未指定';
    final String pluginRuntime = session.plugin?.implementation?.runtimeType.toString() ?? pluginName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(session.device.name, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                    tooltip: 'Rename device',
                    onPressed: () => _showRenameDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              Text(pluginName, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ScreenshotPreview(screenshot: screenshot),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: session.plugin?.id ?? 'unassigned',
                          decoration: const InputDecoration(labelText: '遊戲', isDense: true),
                          items: controller.availablePlugins
                              .map((plugin) => DropdownMenuItem<String>(value: plugin.id, child: Text(plugin.name)))
                              .toList(growable: false),
                          onChanged: (String? pluginId) {
                            if (pluginId != null) controller.assignPlugin(session, pluginId);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text('Plugin  $pluginRuntime'),
                        Text('Version  ${session.plugin?.version ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        const TabBar(
                          tabs: <Widget>[
                            Tab(text: '遊玩狀態'),
                            Tab(text: '裝置資訊'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _GameStatusTab(session: session, decision: decision),
                    _DeviceInfoTab(session: session, screenshot: screenshot),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(onPressed: () => controller.captureScreenshot(session), child: Text(context.l10n.screenshot)),
                  OutlinedButton(onPressed: () => controller.tapTest(session), child: Text(context.l10n.tapTest)),
                  OutlinedButton(onPressed: () => controller.swipeTest(session), child: Text(context.l10n.swipeTest)),
                  OutlinedButton(onPressed: () => controller.restartSession(session), child: Text(context.l10n.restartSession)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final textController = TextEditingController(text: session.device.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Device #1'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: Text(context.l10n.save)),
        ],
      ),
    );
    textController.dispose();
    if (name != null) controller.renameSessionDevice(session, name);
  }
}

class _GameStatusTab extends StatelessWidget {
  const _GameStatusTab({required this.session, required this.decision});

  final AutomationSession session;
  final DecisionStatus? decision;

  @override
  Widget build(BuildContext context) {
    final runtime = session.startedAt == null ? '00:00:00' : DateTime.now().difference(session.startedAt!).toString().split('.').first;
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: <Widget>[
        _InfoRow(label: '目前任務', value: decision?.currentGoal ?? context.l10n.deviceMonitor),
        _InfoRow(label: '下一步', value: decision?.currentAction ?? context.l10n.waiting),
        _InfoRow(label: '執行時間', value: runtime),
        _InfoRow(label: '目前狀態', value: session.state == AutomationState.idle ? context.l10n.idle : session.state.name),
        _InfoRow(label: '錯誤', value: context.l10n.none),
        const Divider(height: 16),
        const Text('今日收益'),
        const _InfoRow(label: '金幣', value: '0'),
        const _InfoRow(label: '礦石', value: '0'),
        const _InfoRow(label: '木材', value: '0'),
      ],
    );
  }
}

class _DeviceInfoTab extends StatelessWidget {
  const _DeviceInfoTab({required this.session, required this.screenshot});

  final AutomationSession session;
  final DeviceScreenshot? screenshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: <Widget>[
        _InfoRow(label: 'Android Version', value: session.device.androidVersion),
        _InfoRow(label: 'Resolution', value: session.device.resolution),
        _InfoRow(label: 'Brand', value: session.device.manufacturer),
        _InfoRow(label: 'Model', value: session.device.model),
        _InfoRow(label: 'Serial', value: session.device.id),
        _InfoRow(label: 'ADB', value: session.device.status.name),
        _InfoRow(label: 'Plugin', value: session.plugin?.name ?? '未指定'),
        const _InfoRow(label: 'Screenshot FPS', value: 'Live refresh'),
        _InfoRow(label: 'Last Update', value: screenshot?.updatedAt.toLocal().toString().split('.').first ?? context.l10n.never),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({required this.screenshot});

  final DeviceScreenshot? screenshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: screenshot == null
          ? Center(child: Text(context.l10n.noScreenshot))
          : Image.memory(screenshot!.pngBytes, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}
