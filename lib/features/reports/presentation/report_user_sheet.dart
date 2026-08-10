import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/domain/entities/moderation_report.dart';
import 'providers/report_providers.dart';

/// Shows the "report user" bottom sheet. Call this from anywhere a
/// [targetUserId] is known (e.g. during or right after a call).
Future<void> showReportUserSheet(
  BuildContext context, {
  required String targetUserId,
  String? callId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportUserSheet(targetUserId: targetUserId, callId: callId),
  );
}

class _ReportUserSheet extends ConsumerStatefulWidget {
  const _ReportUserSheet({required this.targetUserId, this.callId});

  final String targetUserId;
  final String? callId;

  @override
  ConsumerState<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<_ReportUserSheet> {
  ReportReason? _reason;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guard against double-tap / repeat submission while a request is
    // already in flight or has already succeeded.
    if (_reason == null || _submitting || _submitted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(reportRepositoryProvider).submitReport(
            targetUserId: widget.targetUserId,
            reason: _reason!,
            description: _descriptionController.text,
            callId: widget.callId,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('already-exists')) {
      return 'لقد أبلغت عن هذا المستخدم مؤخرًا بالفعل.';
    }
    if (msg.contains('unauthenticated')) {
      return 'يجب تسجيل الدخول للإبلاغ عن مستخدم.';
    }
    if (msg.contains('invalid-argument')) {
      return 'لا يمكن إتمام هذا البلاغ.';
    }
    return 'تعذر إرسال البلاغ. حاول مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: _submitted ? _buildSuccess(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 12),
        const Text(
          'تم إرسال البلاغ بنجاح',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'سيقوم فريقنا بمراجعته.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإبلاغ عن مستخدم',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'اختر السبب الأنسب',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ...ReportReason.values.map(
          (r) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              _reason == r
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _reason == r ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(r.label),
            onTap: _submitting ? null : () => setState(() => _reason = r),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          enabled: !_submitting,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'وصف إضافي (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_reason == null || _submitting) ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('إرسال البلاغ'),
          ),
        ),
      ],
    );
  }
}
