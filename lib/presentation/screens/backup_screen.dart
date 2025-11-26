import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  Directory? _downloadsDir;
  String? _pickedImportPath;

  @override
  void initState() {
    super.initState();
    _loadDownloadsDir();
  }

  Future<void> _loadDownloadsDir() async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _downloadsDir = dir;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);
    final downloadsPath = _downloadsDir?.path ?? 'Loading...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import / Export'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                context,
                title: 'Export to Excel',
                children: [
                  Text('Default folder: $downloadsPath'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: state.exporting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.file_download_done_outlined),
                      label: Text(state.exporting ? 'Exporting...' : 'Export all data'),
                      onPressed: state.exporting
                          ? null
                          : () => controller.exportAll(null),
                    ),
                  ),
                  if (state.lastExportPath != null) ...[
                    const SizedBox(height: 8),
                    Text('Saved to: ${state.lastExportPath}'),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _card(
                context,
                title: 'Import from Excel',
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedImportPath ?? 'No file selected',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: state.importing ? null : _pickImportFile,
                        child: const Text('Choose file'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                    icon: state.importing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.file_upload_outlined),
                    label: Text(state.importing ? 'Importing...' : 'Import data'),
                    onPressed: state.importing || _pickedImportPath == null
                        ? null
                        : () async {
                            await controller.importAll(_pickedImportPath ?? '');
                            await _refreshLoadedData();
                          },
                  ),
                ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: exported files are saved to your downloads folder by default.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.message != null)
                _statusBanner(
                  context,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  text: state.message!,
                ),
              if (state.error != null)
                _statusBanner(
                  context,
                  icon: Icons.error_outline,
                  color: Colors.red,
                  text: state.error!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, {required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _pickImportFile() async {
    final typeGroup = XTypeGroup(
      label: 'Excel',
      extensions: const ['xlsx'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() {
      _pickedImportPath = file.path;
    });
  }

  Future<void> _refreshLoadedData() async {
    try {
      await ref.read(todaySummaryControllerProvider.notifier).load();
    } catch (_) {}
    try {
      await ref.read(waterControllerProvider.notifier).load();
    } catch (_) {}
    try {
      await ref.read(policyControllerProvider.notifier).load();
    } catch (_) {}
  }
}
