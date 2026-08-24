import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as loreboundPath;
import 'dart:io' as loreboundIo;
import 'package:permission_handler/permission_handler.dart';
import '../../../library/data/repositories/local_book_repository.dart' as lorebound;

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
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
              onPressed: () async {
                final scaffold = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                
                try {
                  scaffold.showSnackBar(
                    const SnackBar(content: Text('Exporting library...')),
                  );
                  
                  final repository = ref.read(lorebound.localBookRepositoryProvider);
                  final jsonString = await repository.exportLibraryJson();
                  
                  String exportPath;
                  if (loreboundIo.Platform.isAndroid) {
                    var status = await Permission.manageExternalStorage.request();
                    if (!status.isGranted) {
                      status = await Permission.storage.request();
                    }
                    if (status.isGranted) {
                      exportPath = '/storage/emulated/0/Lorebound';
                    } else {
                      throw Exception('Storage permission denied');
                    }
                  } else {
                    final docDir = await loreboundPath.getApplicationDocumentsDirectory();
                    exportPath = '${docDir.path}/Lorebound';
                  }

                  final dir = loreboundIo.Directory(exportPath);
                  if (!await dir.exists()) {
                    await dir.create(recursive: true);
                  }

                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final file = loreboundIo.File('$exportPath/lorebound_backup_$timestamp.json');
                  await file.writeAsString(jsonString);
                  
                  final String displayPath = file.path.replaceAll('/storage/emulated/0', 'Internal Storage').replaceAll('/', ' / ');
                  
                  scaffold.clearSnackBars();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Exported to: $displayPath'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                } catch (e) {
                  scaffold.clearSnackBars();
                  scaffold.showSnackBar(
                    SnackBar(content: Text('Failed to export: $e')),
                  );
                }
                
                navigator.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
