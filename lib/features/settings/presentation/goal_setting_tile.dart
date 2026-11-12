import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';

class GoalSettingTile extends StatelessWidget {
  final String title;
  final int value;
  final int maximum;
  final ValueChanged<int> onChanged;

  const GoalSettingTile(
      {super.key,
      required this.title,
      required this.value,
      required this.maximum,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(title),
      subtitle:
          Text(value == 0 ? l10n.goalDisabled : l10n.earnedPomodoros(value)),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        final result = await showDialog<int>(
            context: context,
            builder: (_) =>
                _GoalEditor(title: title, value: value, maximum: maximum));
        if (result != null) onChanged(result);
      },
    );
  }
}

class _GoalEditor extends StatefulWidget {
  final String title;
  final int value;
  final int maximum;
  const _GoalEditor(
      {required this.title, required this.value, required this.maximum});
  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, int.parse(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.goalHint),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: l10n.pomodorosLabel,
                        prefixIcon: const Icon(Icons.flag_outlined)),
                    validator: (text) {
                      final number = int.tryParse(text?.trim() ?? '');
                      return number == null ||
                              number < 0 ||
                              number > widget.maximum
                          ? l10n.goalRangeError(widget.maximum)
                          : null;
                    },
                    onFieldSubmitted: (_) => _save()),
              ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelAction)),
        FilledButton(onPressed: _save, child: Text(l10n.saveGoal)),
      ],
    );
  }
}
