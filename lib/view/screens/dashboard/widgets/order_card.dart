import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/utils/format.dart';
import 'quote_sheet.dart';
import 'rx_viewer_sheet.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onUpdate,
    this.onSendQuote,
    this.onAssignRider,
    this.onVerifyRx,
    this.canVerifyRx,
    this.gpsLive = false,
    this.activeDeliveryId,
  });

  final PharmaOrder order;
  final VoidCallback? onAccept;
  final void Function(OrderStatus status)? onUpdate;
  final void Function(double subtotal)? onSendQuote;
  final void Function(DeliveryInfo patch)? onAssignRider;
  final Future<void> Function(String orderId, {String? notes})? onVerifyRx;
  final bool? canVerifyRx;
  final bool gpsLive;
  final String? activeDeliveryId;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late final TextEditingController _riderNameCtrl = TextEditingController(
    text: widget.order.delivery?.riderName ?? '',
  );
  late final TextEditingController _riderPhoneCtrl = TextEditingController(
    text: widget.order.delivery?.riderPhone ?? '',
  );

  @override
  void dispose() {
    _riderNameCtrl.dispose();
    _riderPhoneCtrl.dispose();
    super.dispose();
  }

  bool get _isPrescriptionImage {
    final url = widget.order.prescriptionUrl;
    if (url == null) return false;
    return url.startsWith('data:image/') ||
        RegExp(r'\.(jpe?g|gif|png)$', caseSensitive: false).hasMatch(url);
  }

  void _openRxViewer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => RxViewerSheet(
            patientName: widget.order.patientName,
            prescriptionUrl: widget.order.prescriptionUrl!,
          ),
    );
  }

  void _openQuoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => QuoteSheet(
            onSend: (subtotal) => widget.onSendQuote?.call(subtotal),
          ),
    );
  }

  void _showVerifyRxDialog(BuildContext context) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Verify Prescription'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm the attached prescription is legitimate and matches the ordered items.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  widget.onVerifyRx?.call(
                    widget.order.id,
                    notes: notesCtrl.text,
                  );
                },
                child: const Text('Verify'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0E1B33);
    const coral = Color(0xFFFF5A45);
    const mint = Color(0xFF17A673);
    final order = widget.order;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mint.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${order.id.substring(order.id.length - 5)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.paymentMethod,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(order.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _statusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient / contact / address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoBlock(
                        'PATIENT',
                        order.patientName,
                        Icons.person_outline,
                        mint,
                      ),
                    ),
                    Expanded(
                      child: _infoBlock(
                        'CONTACT',
                        order.phone,
                        Icons.phone_outlined,
                        mint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoBlock(
                  'ADDRESS',
                  order.address,
                  Icons.location_on_outlined,
                  mint,
                  italic: true,
                ),

                // Prescription
                if (order.prescriptionUrl != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mint.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: mint.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ATTACHED Rx',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: mint,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    order.pharmacistVerifiedAt != null
                                        ? Colors.green
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.pharmacistVerifiedAt != null
                                    ? 'VERIFIED'
                                    : 'UNVERIFIED',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (order.needsRxVerification &&
                            widget.canVerifyRx != null) ...[
                          const SizedBox(height: 8),
                          if (widget.canVerifyRx == true)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showVerifyRxDialog(context),
                                icon: const Icon(
                                  Icons.verified_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'VERIFY PRESCRIPTION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: mint,
                                  side: const BorderSide(color: mint),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.amber.shade800,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Waiting for pharmacist verification.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_isPrescriptionImage)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openRxViewer(context),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'VIEW Rx',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'DOC FILE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => Fluttertoast.showToast(
                                      msg: 'Downloading prescription file...',
                                    ),
                                icon: const Icon(
                                  Icons.download_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'GET FILE',
                                  style: TextStyle(fontSize: 10),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Items
                const SizedBox(height: 14),
                if (order.items.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final item = order.items[i];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${item.quantity}x ',
                                            style: const TextStyle(color: mint),
                                          ),
                                          TextSpan(text: item.name),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatBdt(item.totalPrice),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.expiryDate != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'EXP: ${item.expiryDate}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.black38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Quoting required for Rx request.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                      if (order.unmatchedMeds != null &&
                          order.unmatchedMeds!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'UNMATCHED FROM Rx — QUOTE MANUALLY',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.unmatchedMeds!.join(', '),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: mint.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: mint,
                        ),
                      ),
                      Text(
                        formatBdt(order.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: mint,
                        ),
                      ),
                    ],
                  ),
                ),
                // Failed delivery attempt — the order stays exactly where it
                // was (nothing settled or refunded), so this is what turns
                // it back into a decision instead of leaving it stuck.
                if (order.status == OrderStatus.outForDelivery &&
                    (order.delivery?.attempts.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final attempts = order.delivery!.attempts;
                      final last = attempts.last;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DELIVERY FAILED · ATTEMPT ${attempts.length}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              last.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (last.note != null && last.note!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                last.note!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            const Text(
                              'Nothing was settled or refunded. Dispatch again, or cancel to refund.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // Rider assignment (only when out for delivery)
                if (order.status == OrderStatus.outForDelivery &&
                    widget.onAssignRider != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RIDER / COURIER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _riderNameCtrl,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Name',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _riderPhoneCtrl,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Phone',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () {
                                widget.onAssignRider?.call(
                                  DeliveryInfo(
                                    riderName: _riderNameCtrl.text,
                                    riderPhone: _riderPhoneCtrl.text,
                                    dispatchedAt:
                                        order.delivery?.dispatchedAt ??
                                        DateTime.now().toIso8601String(),
                                  ),
                                );
                                Fluttertoast.showToast(
                                  msg: 'Rider details saved.',
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildFooterAction(context, navy, coral, mint, order),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(
    BuildContext context,
    Color navy,
    Color coral,
    Color mint,
    PharmaOrder order,
  ) {
    if (order.status == OrderStatus.pending) {
      if (order.items.isNotEmpty) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              widget.onAccept?.call();
              Fluttertoast.showToast(msg: 'Order validated.');
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'VALIDATE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: mint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => _openQuoteSheet(context),
          icon: const Icon(Icons.attach_money, size: 18),
          label: const Text(
            'SEND QUOTE',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: coral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.processing) {
      final rxNeedsSignOff = order.needsRxVerification;
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed:
                  rxNeedsSignOff
                      ? null
                      : () {
                        widget.onUpdate?.call(OrderStatus.outForDelivery);
                        Fluttertoast.showToast(msg: 'Order dispatched.');
                      },
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text(
                'DISPATCH',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (rxNeedsSignOff) ...[
            const SizedBox(height: 6),
            Text(
              'Rx sign-off required before dispatch',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (order.status == OrderStatus.outForDelivery) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            widget.onAssignRider?.call(
              DeliveryInfo(deliveredAt: DateTime.now().toIso8601String()),
            );
            widget.onUpdate?.call(OrderStatus.completed);
            Fluttertoast.showToast(msg: 'Order marked completed.');
          },
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text(
            'COMPLETED',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: mint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.quoted) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'AWAITING PATIENT APPROVAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoBlock(
    String label,
    String value,
    IconData icon,
    Color accent, {
    bool italic = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.black38,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  color: italic ? Colors.black54 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.grey.shade700;
      case OrderStatus.quoted:
        return Colors.blueGrey;
      case OrderStatus.processing:
        return const Color(0xFF17A673);
      case OrderStatus.outForDelivery:
        return const Color(0xFFFF5A45);
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
