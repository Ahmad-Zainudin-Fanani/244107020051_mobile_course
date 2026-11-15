import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/assistant_providers.dart';

/// Kartu pengaturan API key Gemini.
///
/// Key disimpan lewat [ApiKeyStore] (secure storage), bukan di kode sumber.
class ApiKeyCard extends ConsumerStatefulWidget {
  const ApiKeyCard({super.key});

  @override
  ConsumerState<ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<ApiKeyCard> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.length < 20) {
      setState(() {
        _validationError =
            'API key terlihat terlalu pendek. Tempel key lengkap.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _validationError = null;
    });

    try {
      await ref.read(apiKeyStoreProvider).save(value);
      ref.invalidate(apiKeyStatusProvider);
      _controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key tersimpan di penyimpanan aman perangkat.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Gagal menyimpan key. Coba lagi atau periksa penyimpanan perangkat.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus API key?'),
        content: const Text(
          'Asisten tidak bisa dipakai lagi sampai Anda menempelkan key baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(apiKeyStoreProvider).delete();
      ref.invalidate(apiKeyStatusProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('API key dihapus.')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Gagal menghapus key. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(apiKeyStatusProvider);
    final hasKey = status.value ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Key Gemini',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Disimpan terenkripsi di perangkat, bukan di repo.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Tempel API key',
              hintText: 'AIza...',
              errorText: _validationError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Tampilkan key' : 'Sembunyikan key',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan key'),
              ),
              if (hasKey)
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus key'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Dapatkan key gratis di aistudio.google.com, lalu batasi kuotanya. '
            'Jangan pernah menempelkan key ke chat, issue, atau commit.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AsyncValue<bool> status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      AsyncData(:final value) when value => (
        'Tersimpan',
        const Color(0xFF0D9488),
      ),
      AsyncData() => ('Belum diatur', theme.colorScheme.error),
      AsyncError() => ('Tidak terbaca', theme.colorScheme.error),
      _ => ('Memeriksa', theme.colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
