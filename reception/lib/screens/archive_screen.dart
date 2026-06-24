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
      subtitle: '${archive.total} record(s) · permanent on-disk history',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: archive.setQuery,
                    decoration: const InputDecoration(
                      hintText:
                          'Search archived patients, phone, doctor, token…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _DayDropdown(archive: archive),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  _statusChip(archive, 'All', null),
                  _statusChip(archive, 'Completed', StatusUi.completed),
                  _statusChip(archive, 'Cancelled', StatusUi.cancelled),
                  _statusChip(archive, 'Upcoming', StatusUi.upcoming),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _body(archive)),
        ],
      ),
    );
  }

  Widget _statusChip(ArchiveProvider archive, String label, int? status) {
    final sel = archive.status == status;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => archive.setStatus(status),
    );
  }

  Widget _body(ArchiveProvider archive) {
    if (archive.loading && archive.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (archive.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: archive.days.isEmpty ? 'Archive is empty' : 'No matches',
        message: archive.days.isEmpty
            ? 'Completed days appear here after the end-of-day job archives them.'
            : 'Try a different search or filter.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      itemCount: archive.rows.length + (archive.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= archive.rows.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final a = archive.rows[i];
        return AppointmentTile(
          appt: a,
          showDate: true,
          onTap: () => _reprint(context, a),
          trailing: IconButton(
            tooltip: 'Reprint slip',
            icon: const Icon(Icons.print_outlined, size: 18),
            color: AppColors.textSecondary,
            onPressed: () => _reprint(context, a),
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
          hint: const Text('All days'),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All days')),
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
