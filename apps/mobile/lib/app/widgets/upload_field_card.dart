import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../session/auth_api_client.dart';
import '../uploads/upload_models.dart';
import '../uploads/uploads_api_client.dart';

class UploadFieldCard extends StatefulWidget {
  const UploadFieldCard({
    required this.label,
    required this.accessToken,
    required this.controller,
    required this.kind,
    this.helper,
    this.previewHeight = 152,
    super.key,
  });

  final String label;
  final String accessToken;
  final TextEditingController controller;
  final UploadAssetKind kind;
  final String? helper;
  final double previewHeight;

  @override
  State<UploadFieldCard> createState() => _UploadFieldCardState();
}

class _UploadFieldCardState extends State<UploadFieldCard> {
  final UploadsApiClient _uploadsApiClient = UploadsApiClient();
  bool _isUploading = false;
  UploadedAssetModel? _uploadedAsset;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant UploadFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: widget.kind == UploadAssetKind.image
          ? FileType.image
          : FileType.custom,
      withData: true,
      allowedExtensions: widget.kind == UploadAssetKind.image
          ? null
          : const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
    );

    if (picked == null || picked.files.isEmpty || !mounted) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      final asset = await _uploadsApiClient.uploadFile(
        accessToken: widget.accessToken,
        file: picked.files.single,
        kind: widget.kind,
      );
      widget.controller.text = asset.url;
      if (!mounted) {
        return;
      }
      setState(() => _uploadedAsset = asset);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.label} uploaded')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = widget.controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: Icon(
                widget.kind == UploadAssetKind.image
                    ? Icons.cloud_upload_outlined
                    : Icons.attach_file_rounded,
              ),
              label: Text(_isUploading ? 'Uploading...' : 'Upload'),
            ),
          ],
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: const TextStyle(
              color: Color(0xFF6C675E),
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: '${widget.label} URL',
            prefixIcon: Icon(
              widget.kind == UploadAssetKind.image
                  ? Icons.image_outlined
                  : Icons.description_outlined,
            ),
          ),
        ),
        if (currentValue.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (widget.kind == UploadAssetKind.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                currentValue,
                height: widget.previewHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: widget.previewHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECE0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('Preview unavailable for this image'),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EFE4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0D9CB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadedAsset?.originalName ?? 'Verification document ready',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentValue,
                    style: const TextStyle(
                      color: Color(0xFF5F645F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => launchUrlString(
                      currentValue,
                      mode: LaunchMode.platformDefault,
                    ),
                    child: const Text('Open document'),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
