import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca daftar ToDo hasil filter melalui Provider turunan filteredTodoListProvider
    final todos = ref.watch(filteredTodoListProvider);
    final activeFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        actions: [
          // Filter menu untuk memilih Semua, Belum Selesai, atau Selesai
          PopupMenuButton<TodoFilter>(
            initialValue: activeFilter,
            onSelected: (filter) {
              ref.read(todoFilterProvider.notifier).setFilter(filter);
            },
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TodoFilter.all,
                child: Text('Semua'),
              ),
              PopupMenuItem(
                value: TodoFilter.active,
                child: Text('Belum Selesai'),
              ),
              PopupMenuItem(
                value: TodoFilter.completed,
                child: Text('Selesai'),
              ),
            ],
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return TodoTile(
                  todo: todo,
                  onToggle: (_) =>
                      ref.read(todoListProvider.notifier).toggleTodo(todo),
                  onDelete: () =>
                      ref.read(todoListProvider.notifier).removeTodo(todo),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
