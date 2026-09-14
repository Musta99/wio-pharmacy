import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/models/field_model.dart';
import '../../../../services/field_api_service.dart';

const Color _kNavy = Color(0xFF0E1B33);
const Color _kMint = Color(0xFF17A673);

String _formatBdt(num amount) => '৳${amount.toStringAsFixed(0)}';

/// Rider dispatch: hand a batch of orders to one rider as a single trip.
/// Flutter counterpart of the web `DispatchPanel` component
/// (`jobType="delivery"` side — the pharmacy app never dispatches lab
/// collectors).
///
/// Replaces the OLD per-order GPS broadcast entirely, matching the web
/// dashboard: that stream only ever tracked one order at a time and killed
/// itself when a second delivery started. Position now belongs to the
/// rider's shift, one stream for the whole bag, started here.
class DispatchPanel extends StatefulWidget {
  const DispatchPanel({super.key, required this.jobs});
  final List<DispatchableJob> jobs;

  @override
  State<DispatchPanel> createState() => _DispatchPanelState();
}

class _DispatchPanelState extends State<DispatchPanel> {
  final _api = FieldApiService();
  Timer? _pollTimer;

  List<FieldWorker> _workers = [];
  List<BoardShift> _board = [];
  final List<String> _selected = []; // job ids, in visiting order
  String? _workerId;
  StartShiftResult? _issued;
  FieldReconciliation? _settlement;
  bool _busy = false;
  String? _error;
  bool _linkJustCopied = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final board = await _api.fetchBoard();
    if (!mounted) return;
    setState(() {
      _workers = board.workers;
      _board = board.shifts;
    });
  }

  Set<String> get _onRoute =>
      _board.expand((b) => b.stops.map((s) => s.refId)).toSet();

  List<DispatchableJob> get _available =>
      widget.jobs.where((j) => !_onRoute.contains(j.id)).toList();

  List<FieldWorker> get _roster =>
      _workers
          .where((w) => w.active && w.kind == FieldWorkerKind.rider)
          .toList();

  Set<String> get _busyWorkerIds => _board.map((b) => b.shift.workerId).toSet();

  bool get _selectedBusy =>
      _workerId != null && _busyWorkerIds.contains(_workerId);

  void _toggle(String jobId) {
    setState(() {
      if (_selected.contains(jobId)) {
        _selected.remove(jobId);
      } else {
        _selected.add(jobId);
      }
    });
  }

  Future<void> _dispatch(String authMethod) async {
    if (_workerId == null || _selected.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _issued = null;
    });
    try {
      final result = await _api.startShift(
        workerId: _workerId!,
        authMethod: authMethod,
        stops: [
          for (var i = 0; i < _selected.length; i++)
            {'jobType': 'delivery', 'refId': _selected[i], 'sequence': i},
        ],
      );
      setState(() {
        _issued = result;
        _selected.clear();
        _workerId = null;
      });
      await _load();
    } catch (e) {
      setState(
        () =>
            _error =
                e is FieldApiException
                    ? e.message
                    : 'Could not start the shift.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(String shiftId) async {
    setState(() => _busy = true);
    try {
      final rec = await _api.endShift(shiftId);
      if (mounted) setState(() => _settlement = rec);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FieldApiException ? e.message : 'Could not end the shift.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    setState(() => _linkJustCopied = true);
    Fluttertoast.showToast(msg: 'Link has been copied');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkJustCopied = false);
    });
  }

  Future<void> _openInMaps(LatLngModel loc) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _shiftLinkFrom(String token) {
    return '${ApiConstants.backendBaseUrl}/field?token=$token';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rider Dispatch',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            'One rider, one trip, many orders.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),

          // ── Roster — shown unconditionally, so an empty roster reads
          // differently from an empty order queue. ──
          _sectionLabel('RIDERS · TAP TO PICK ONE'),
          const SizedBox(height: 8),
          if (_roster.isEmpty)
            _dashedNote(
              'No riders on the roster yet. They are added centrally under '
              'Users → Riders, then appear here for every shop.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _roster.map((w) {
                    final onRound = _busyWorkerIds.contains(w.id);
                    final picked = _workerId == w.id;
                    return InkWell(
                      onTap:
                          onRound
                              ? null
                              : () => setState(
                                () => _workerId = picked ? null : w.id,
                              ),
                      borderRadius: BorderRadius.circular(12),
                      child: Opacity(
                        opacity: onRound ? 0.55 : 1,
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: picked ? _kNavy : Colors.grey.shade300,
                              width: picked ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                picked
                                    ? _kNavy.withOpacity(0.05)
                                    : Colors.white,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey.shade200,
                                child: Text(
                                  w.name.trim().isNotEmpty
                                      ? w.name.trim()[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      onRound ? 'Out on a round' : w.phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (picked)
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: _kNavy,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          const SizedBox(height: 14),

          // ── Build a route ──
          if (_available.isEmpty)
            _dashedNote('No orders are ready to send out yet.')
          else ...[
            _sectionLabel('PICK ORDERS · TAP IN VISITING ORDER'),
            const SizedBox(height: 8),
            ..._available.map((job) {
              final index = _selected.indexOf(job.id);
              final picked = index >= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => _toggle(job.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: picked ? _kNavy : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: picked ? _kNavy.withOpacity(0.05) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              picked ? _kNavy : Colors.grey.shade200,
                          child: Text(
                            picked ? '${index + 1}' : '·',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  picked ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.patientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                job.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (job.unpaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COD',
                              style: TextStyle(fontSize: 9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      (_busy ||
                              _workerId == null ||
                              _selectedBusy ||
                              _selected.isEmpty)
                          ? null
                          : () => _dispatch('otp'),
                  icon:
                      _busy
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send, size: 16),
                  label: Text(
                    'Dispatch ${_selected.isEmpty ? '' : _selected.length}',
                  ),
                ),
                OutlinedButton(
                  onPressed:
                      (_busy ||
                              _workerId == null ||
                              _selectedBusy ||
                              _selected.isEmpty)
                          ? null
                          : () => _dispatch('token'),
                  child: const Text('Send a link'),
                ),
              ],
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          // ── Shown once, never recoverable ──
          if (_issued != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy this now — it cannot be shown again.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (_issued!.token != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _shiftLinkFrom(_issued!.token!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _linkJustCopied ? Icons.check : Icons.copy,
                            size: 16,
                            color: _linkJustCopied ? _kMint : null,
                          ),
                          onPressed:
                              () => _copyLink(_shiftLinkFrom(_issued!.token!)),
                        ),
                      ],
                    ),
                  ],
                  if (_issued!.deliveryCodes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Delivery codes — the patient reads these to the rider:',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._issued!.deliveryCodes.entries.map(
                      (e) => Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Shift closed ──
          if (_settlement != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shift closed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _settlement = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                  Text(
                    '${_settlement!.delivered} delivered · ${_settlement!.failed} failed · '
                    '${_settlement!.unworked} not attempted',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cash to hand over: ${_formatBdt(_settlement!.collected)}',
                  ),
                  if (_settlement!.shortfall != 0)
                    Text(
                      _settlement!.shortfall > 0
                          ? 'Short by ${_formatBdt(_settlement!.shortfall)} against ${_formatBdt(_settlement!.expected)} due.'
                          : 'Holding ${_formatBdt(-_settlement!.shortfall)} more than the route explains.',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],

          // ── Who is out ──
          if (_board.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._board.map((entry) {
              final done =
                  entry.stops
                      .where((s) => s.status == FieldStopStatus.done)
                      .length;
              final name =
                  _workers
                      .where((w) => w.id == entry.shift.workerId)
                      .map((w) => w.name)
                      .cast<String?>()
                      .firstWhere((_) => true, orElse: () => null) ??
                  'Rider';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.podcasts,
                          size: 16,
                          color: entry.stale ? Colors.grey.shade500 : _kMint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$done/${entry.stops.length} delivered · '
                                '${_formatBdt(entry.shift.cashCollected)} collected · '
                                '${entry.stale ? 'location paused' : 'location live'}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (entry.shift.lastLocation != null)
                          IconButton(
                            icon: const Icon(Icons.map_outlined, size: 18),
                            tooltip: 'Open in Maps',
                            onPressed:
                                () => _openInMaps(entry.shift.lastLocation!),
                          ),
                        TextButton(
                          onPressed:
                              _busy ? null : () => _finish(entry.shift.id),
                          child: const Text('End shift'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...(entry.stops.toList()
                          ..sort((a, b) => a.sequence.compareTo(b.sequence)))
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  s.status == FieldStopStatus.done
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 13,
                                  color:
                                      s.status == FieldStopStatus.done
                                          ? _kMint
                                          : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${s.sequence + 1}. ${s.patientName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ),
                                Text(
                                  s.status == FieldStopStatus.failed
                                      ? (s.failureReason ?? 'failed')
                                      : s.status.value,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
      color: Colors.grey.shade600,
    ),
  );

  Widget _dashedNote(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
    ),
  );
}
