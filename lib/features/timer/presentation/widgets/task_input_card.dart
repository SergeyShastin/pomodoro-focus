import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';

class TaskInputCard extends StatefulWidget {
  final String currentTaskName;
  final ValueChanged<String> onTaskNameChanged;

  const TaskInputCard({
    super.key,
    required this.currentTaskName,
    required this.onTaskNameChanged,
  });

  @override
  State<TaskInputCard> createState() => _TaskInputCardState();
}

class _TaskInputCardState extends State<TaskInputCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTaskName);
  }

  @override
  void didUpdateWidget(covariant TaskInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTaskName != widget.currentTaskName &&
        _controller.text != widget.currentTaskName) {
      _controller.text = widget.currentTaskName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: l10n.taskInputHint,
          prefixIcon: const Icon(Icons.edit_note, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onTaskNameChanged('');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: widget.onTaskNameChanged,
      ),
    );
  }
}
