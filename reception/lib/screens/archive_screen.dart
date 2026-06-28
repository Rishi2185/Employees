import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reception_appointment.dart';
import '../models/slip.dart';
import '../services/slip_printer.dart';
import '../state/archive_provider.dart';
import '../state/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/day_key.dart';
import '../utils/formatters.dart';
import '../utils/status_ui.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/fade_in.dart';

/// The local archive browser — fast, offline search over the permanent SQLite
/// record of every past appointment, plus per-day filtering and slip reprints.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArchiveProvider>().init();
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        context.read<ArchiveProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveProvider>();

    return ScreenScaffold(
      title: 'Local archive',
      subtitle: '${archive.total} records archived locally on-disk',
      child: Column(
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 50),
            offsetY: -10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                      ),
                        ],
                      ),
                      child: TextField(
                        controller: _search,
                        onChanged: archive.setQuery,
                        decoration: const InputDecoration(
                          hintText: 'Search archived patients, phone, doctor, or token…',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _DayDropdown(archive: archive),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeIn(
            delay: const Duration(milliseconds: 100),
            offsetY: -5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip(archive, 'All status', null),
                    _statusChip(archive, 'Completed', StatusUi.completed, color: AppColors.success),
                    _statusChip(archive, 'Cancelled', StatusUi.cancelled, color: AppColors.danger),
                    _statusChip(archive, 'Upcoming', StatusUi.upcoming, color: AppColors.info),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _body(archive)),
        ],
      ),
    );
  }

  Widget _statusChip(ArchiveProvider archive, String label, int? status, {Color? color}) {
    final sel = archive.status == status;
    final c = color ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: c,
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
        color: sel ? AppColors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      side: BorderSide(color: sel ? c : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => archive.setStatus(status),
    );
  }

  Widget _body(ArchiveProvider archive) {
    if (archive.loading && archive.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (archive.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: archive.days.isEmpty ? 'Archive is empty' : 'No records found',
        message: archive.days.isEmpty
            ? 'Completed days appear here after the end-of-day job archives them.'
            : 'Try modifying your search or filters.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      itemCount: archive.rows.length + (archive.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i >= archive.rows.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final a = archive.rows[i];
        return FadeIn(
          delay: Duration(milliseconds: (i % 8) * 35),
          scaleFrom: 0.97,
          child: AppointmentTile(
            appt: a,
            showDate: true,
            onTap: () => _reprint(context, a),
            trailing: _ReprintAction(onPrint: () => _reprint(context, a)),
          ),
        );
      },
    );
  }

  Future<void> _reprint(BuildContext context, ReceptionAppointment a) async {
    final services = context.read<Services>();
    final slip = Slip.fromAppointment(a, statusLabel: StatusUi.label(a.status));
    await SlipPrinter.print(slip, hospitalName: services.settings.hospitalName);
  }
}

class _ReprintAction extends StatefulWidget {
  final VoidCallback onPrint;
  const _ReprintAction({required this.onPrint});

  @override
  State<_ReprintAction> createState() => _ReprintActionState();
}

class _ReprintActionState extends State<_ReprintAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: 'Reprint slip',
        child: AnimatedScale(
          scale: _hovered ? 1.15 : 1.0,
          duration: AppTheme.fast,
          child: InkWell(
            onTap: widget.onPrint,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: AppTheme.fast,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hovered ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.print_rounded,
                size: 16,
                color: _hovered ? AppColors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDropdown extends StatelessWidget {
  final ArchiveProvider archive;
  const _DayDropdown({required this.archive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: archive.dayKey,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          hint: const Text('All days', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Poppins'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All days'),
            ),
            ...archive.days.map((d) => DropdownMenuItem<String?>(
                  value: d,
                  child: Text(Fmt.shortDate(DayKey.parse(d))),
                )),
          ],
          onChanged: archive.setDay,
        ),
      ),
    );
  }
}
