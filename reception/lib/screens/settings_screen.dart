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
import '../widgets/fade_in.dart';

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

  bool _working = false;

  @override
  void dispose() {
    _baseUrl.dispose();
    _hospital.dispose();
    super.dispose();
  }

  void _toast(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  Future<void> _saveConnection() async {
    await _services.settings.setBaseUrl(_baseUrl.text);
    _services.api.baseUrl = _baseUrl.text.trim();
    await _services.settings.setHospitalName(_hospital.text);
    await _services.settings.setRetentionDays(_retention);
    _toast('Settings saved successfully.');
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
      _toast('Backed up ${(bytes / 1024).toStringAsFixed(0)} KB to local storage.');
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
      _toast('Exported $rows record(s) to CSV successfully.');
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
      subtitle: 'Front desk station configuration & local archive maintenance',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 50),
            scaleFrom: 0.98,
            child: _section(
              'Connection & Station Info',
              Icons.cloud_outlined,
              [
                AppTextField(
                  label: 'Backend API Base URL',
                  controller: _baseUrl,
                  hint: 'http://localhost:4000/api',
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Hospital Name (Printed on Slips)',
                  controller: _hospital,
                  prefixIcon: Icons.local_hospital_outlined,
                ),
                const SizedBox(height: 20),
                _retentionField(),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    onPressed: _saveConnection,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save configuration', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 120),
            scaleFrom: 0.98,
            child: _section(
              'Local Archive & Backup Tools',
              Icons.storage_rounded,
              [
                _pathRow(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      onPressed: _working ? null : _backupDb,
                      icon: const Icon(Icons.backup_outlined, size: 18),
                      label: const Text('Backup SQLite database', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      onPressed: _working ? null : _exportCsv,
                      icon: const Icon(Icons.table_view_outlined, size: 18),
                      label: const Text('Export archive to CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (_working) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(minHeight: 3, color: AppColors.primary, backgroundColor: AppColors.mint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 180),
            scaleFrom: 0.98,
            child: _section(
              'Account Profile',
              Icons.person_outline_rounded,
              [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName.isEmpty ? 'Front Desk Staff' : auth.displayName,
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Session Role: ${auth.session?.role.toUpperCase() ?? 'RECEPTION'}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign out?'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          context.read<AuthProvider>().logout();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _retentionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Local retention window',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the duration (in days) to retain historical patient and slot data on this terminal.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.mint,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  valueIndicatorColor: AppColors.primary,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child: Slider(
                  value: _retention.toDouble().clamp(7, 1095),
                  min: 7,
                  max: 1095,
                  divisions: 109,
                  label: '$_retention days',
                  onChanged: (v) => setState(() => _retention = v.round()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Text(
                '$_retention days',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pathRow() {
    final path = BackupService.databasePath ?? 'Not opened';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Database File Path',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy path to clipboard',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              _toast('Database path copied to clipboard.');
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
