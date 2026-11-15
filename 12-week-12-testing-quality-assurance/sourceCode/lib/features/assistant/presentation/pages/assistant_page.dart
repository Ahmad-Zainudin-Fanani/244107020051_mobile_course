import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/assistant_providers.dart';
import '../widgets/assistant_empty_view.dart';
import '../widgets/chat_bubble.dart';

/// Layar chat asisten AI.
///
/// Halaman ini hanya mengurus tampilan dan interaksi. Pemanggilan jaringan,
/// cache, dan batas biaya ada di [ChatController].
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final includeContext = ref.read(includeNotesContextProvider);
    final titles = ref.read(assistantContextTitlesProvider);

    ref
        .read(chatControllerProvider.notifier)
        .send(text, noteTitles: titles, includeContext: includeContext);
    _controller.clear();
    _inputFocus.requestFocus();
  }

  void _useSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _inputFocus.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final includeContext = ref.watch(includeNotesContextProvider);
    final contextTitles = ref.watch(assistantContextTitlesProvider);
    final hasKey = ref.watch(apiKeyStatusProvider).value;
    final theme = Theme.of(context);

    final String contextLabel;
    if (!includeContext) {
      contextLabel = 'Sertakan judul catatan (opsional)';
    } else if (contextTitles.isEmpty) {
      contextLabel = 'Memuat judul catatan…';
    } else {
      contextLabel = '${contextTitles.length} judul catatan akan disertakan';
    }

    ref.listen(chatControllerProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Asisten Catatan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          if (hasKey == false)
            IconButton(
              tooltip: 'API key belum diatur',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.key_off_outlined),
            ),
          if (state.hasMessages)
            IconButton(
              tooltip: 'Hapus percakapan',
              onPressed: () =>
                  ref.read(chatControllerProvider.notifier).clear(),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.error != null)
              _ErrorBanner(
                message: state.error!,
                onOpenSettings: () => context.push('/settings'),
                onDismiss: () =>
                    ref.read(chatControllerProvider.notifier).dismissError(),
              ),
            Expanded(
              child: state.messages.isEmpty
                  ? AssistantEmptyView(onSuggestionTap: _useSuggestion)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) =>
                          ChatBubble(message: state.messages[index]),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contextLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: includeContext,
                    onChanged: (value) => ref
                        .read(includeNotesContextProvider.notifier)
                        .toggle(value),
                  ),
                ],
              ),
            ),
            _buildComposer(state, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(ChatState state, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _inputFocus,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tanya tentang catatan Anda...',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (state.isStreaming)
            IconButton.filledTonal(
              tooltip: 'Hentikan jawaban',
              onPressed: () =>
                  ref.read(chatControllerProvider.notifier).cancel(),
              icon: const Icon(Icons.stop_rounded),
            )
          else
            IconButton.filled(
              tooltip: 'Kirim pertanyaan',
              onPressed: _send,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Pengaturan'),
              ),
              TextButton(onPressed: onDismiss, child: const Text('Tutup')),
            ],
          ),
        ],
      ),
    );
  }
}
