import 'package:flutter/material.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _format = 'csv';
  bool _exportTitle = true;
  bool _exportAuthor = true;
  bool _exportStatus = true;
  bool _exportProgress = true;
  bool _exportRating = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Export Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Format', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('CSV'),
                  value: 'csv',
                  groupValue: _format,
                  onChanged: (value) => setState(() => _format = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('JSON'),
                  value: 'json',
                  groupValue: _format,
                  onChanged: (value) => setState(() => _format = value!),
                ),
              ),
            ],
          ),
          
          const Divider(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Fields to include', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          CheckboxListTile(
            title: const Text('Title & Author'),
            value: _exportTitle && _exportAuthor,
            onChanged: (value) {
              setState(() {
                _exportTitle = value!;
                _exportAuthor = value;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Reading Status'),
            value: _exportStatus,
            onChanged: (value) => setState(() => _exportStatus = value!),
          ),
          CheckboxListTile(
            title: const Text('Reading Progress'),
            value: _exportProgress,
            onChanged: (value) => setState(() => _exportProgress = value!),
          ),
          CheckboxListTile(
            title: const Text('Rating & Reviews'),
            value: _exportRating,
            onChanged: (value) => setState(() => _exportRating = value!),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
