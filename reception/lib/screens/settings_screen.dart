import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';

import '../db/backup_service.dart';
import '../state/auth_provider.dart';
import '../state/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/day_key.dart';
import '../widgets/app_text_field.dart';
import '../widgets/screen_scaffold.dart';

/// Station settings: backend URL, hospital identity, local-archive retention,
/// and the on-disk backup / CSV export tools.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Services _services = context.read<Services>();
  late final _baseUrl =
      TextEditingController(text: _services.settings.baseUrl);
  late final _hospital =
      TextEditingController(text: _services.settings.hospitalName);
  late int _retention = _services.settings.retentionDays;
  String? _savedNote;
  bool _working = false;

  @override
  void dispose() {
    _baseUrl.dispose();
    _hospital.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    setState(() => _savedNote = msg);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveConnection() async {
    await _services.settings.setBaseUrl(_baseUrl.text);
    _services.api.baseUrl = _baseUrl.text.trim();
    await _services.settings.setHospitalName(_hospital.text);
    await _services.settings.setRetentionDays(_retention);
    _toast('Settings saved.');
  }

  Future<void> _backupDb() async {
    final stamp = DayKey.format(DateTime.now());
    final location = await getSaveLocation(
      suggestedName: BackupService.suggestedBackupName(stamp),
    );
    if (location == null) return;
    setState(() => _working = true);
    try {
      final bytes = await _services.backup.backupDatabase(location.path);
      _toast('Backed up ${(bytes / 1024).toStringAsFixed(0)} KB to disk.');
    } catch (e) {
      _toast('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _exportCsv() async {
    final stamp = DayKey.format(DateTime.now());
    final location = await getSaveLocation(
      suggestedName: BackupService.suggestedCsvName('all_$stamp'),
    );
    if (location == null) return;
    setState(() => _working = true);
    try {
      final rows = await _services.backup.exportRangeCsv(destPath: location.path);
      _toast('Exported $rows record(s) to CSV.');
    } catch (e) {
      _toast('Export failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ScreenScaffold(
      title: 'Settings',
      subtitle: 'Station configuration & local archive tools',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        children: [
          _section(
            'Connection',
            Icons.cloud_outlined,
            [
              AppTextField(
                label: 'Backend API base URL',
                controller: _baseUrl,
                hint: 'http://localhost:4000/api',
                prefixIcon: Icons.link_rounded,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Hospital name (on slips)',
                controller: _hospital,
                prefixIcon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 18),
              _retentionField(),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _saveConnection,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _section(
            'Local archive',
            Icons.storage_rounded,
            [
              _pathRow(),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _working ? null : _backupDb,
                    icon: const Icon(Icons.backup_outlined, size: 18),
                    label: const Text('Back up database'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _working ? null : _exportCsv,
                    icon: const Icon(Icons.table_view_outlined, size: 18),
                    label: const Text('Export all to CSV'),
                  ),
                ],
              ),
              if (_working) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _section(
            'Account',
            Icons.person_outline_rounded,
            [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName.isEmpty
                            ? 'Reception'
                            : auth.displayName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('Role: ${auth.session?.role ?? '—'}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
          if (_savedNote != null) ...[
            const SizedBox(height: 16),
            Text(_savedNote!,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }

  Widget _retentionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Local retention window',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'How many days of full records to keep on disk. Cloud summaries keep '
          'the long-term trend regardless.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _retention.toDouble().clamp(7, 1095),
                min: 7,
                max: 1095,
                divisions: 109,
                label: '$_retention days',
                onChanged: (v) => setState(() => _retention = v.round()),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text('$_retention days',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pathRow() {
    final path = BackupService.databasePath ?? 'Not opened';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGreenTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Database file',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy path',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              _toast('Path copied.');
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
