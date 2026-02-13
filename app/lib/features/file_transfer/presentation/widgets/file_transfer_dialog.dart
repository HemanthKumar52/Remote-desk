import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../services/file_transfer_service.dart';
import '../../../../core/theme/app_theme.dart';

class FileTransferDialog extends StatefulWidget {
  final FileTransferService fileTransferService;

  const FileTransferDialog({
    super.key,
    required this.fileTransferService,
  });

  @override
  State<FileTransferDialog> createState() => _FileTransferDialogState();
}

class _FileTransferDialogState extends State<FileTransferDialog> {
  @override
  void initState() {
    super.initState();
    widget.fileTransferService.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    widget.fileTransferService.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    setState(() {});
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        await widget.fileTransferService.sendFile(File(path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.fileTransferService.progress;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.file_copy_outlined, size: 28),
                const SizedBox(width: 12),
                Text(
                  'File Transfer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (progress.state == FileTransferState.idle)
              _buildIdleState()
            else if (progress.state == FileTransferState.requesting && progress.fileName.isNotEmpty)
              _buildIncomingRequest(progress)
            else if (progress.state == FileTransferState.sending ||
                     progress.state == FileTransferState.receiving)
              _buildTransferProgress(progress)
            else if (progress.state == FileTransferState.completed)
              _buildCompleted(progress)
            else if (progress.state == FileTransferState.failed)
              _buildFailed(progress),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.fileTransferService.reset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.upload_file,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Send a file to the remote device',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickAndSendFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose File'),
        ),
      ],
    );
  }

  Widget _buildIncomingRequest(FileTransferProgress progress) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.download,
            size: 40,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Incoming File'),
        const SizedBox(height: 8),
        Text(
          progress.fileName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          _formatFileSize(progress.fileSize),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                widget.fileTransferService.rejectTransfer();
              },
              child: const Text('Decline'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                widget.fileTransferService.acceptTransfer();
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransferProgress(FileTransferProgress progress) {
    final isSending = progress.state == FileTransferState.sending;

    return Column(
      children: [
        Icon(
          isSending ? Icons.upload : Icons.download,
          size: 40,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          isSending ? 'Sending...' : 'Receiving...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(progress.fileName),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatFileSize(progress.transferredBytes)} / ${_formatFileSize(progress.fileSize)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCompleted(FileTransferProgress progress) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Transfer Complete!'),
        const SizedBox(height: 8),
        Text(
          progress.fileName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          _formatFileSize(progress.fileSize),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFailed(FileTransferProgress progress) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 40,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Transfer Failed'),
        if (progress.error != null) ...[
          const SizedBox(height: 8),
          Text(
            progress.error!,
            style: TextStyle(
              color: AppTheme.errorColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.fileTransferService.reset();
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
