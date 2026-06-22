import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Pronunciation practice (#6): the user records themselves saying a target word
/// and the backend (Gemini transcription + match score) grades how close it was.
class PronounceScreen extends ConsumerStatefulWidget {
  final String word;
  const PronounceScreen({super.key, required this.word});

  @override
  ConsumerState<PronounceScreen> createState() => _PronounceScreenState();
}

class _PronounceScreenState extends ConsumerState<PronounceScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _scoring = false;
  int? _score;
  String _verdict = '';
  String _heard = '';

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_scoring) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) await _submit(path);
      return;
    }
    if (!await _recorder.hasPermission()) {
      _showMessage(
        'Microphone permission is needed to practise pronunciation.',
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/pronounce.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    setState(() {
      _recording = true;
      _score = null;
      _verdict = '';
      _heard = '';
    });
  }

  Future<void> _submit(String path) async {
    setState(() => _scoring = true);
    try {
      final form = FormData.fromMap({
        'target': widget.word,
        'audio': await MultipartFile.fromFile(
          path,
          filename: 'clip.m4a',
          contentType: DioMediaType('audio', 'mp4'),
        ),
      });
      final res = await ref
          .read(apiClientProvider)
          .post(ApiEndpoints.pronounce, data: form);
      final d = res.data as Map;
      setState(() {
        _score = (d['score'] as num?)?.toInt() ?? 0;
        _verdict = d['verdict'] ?? '';
        _heard = d['transcript'] ?? '';
      });
    } catch (_) {
      _showMessage('Could not score that. Try again in a quiet spot.');
    } finally {
      if (mounted) setState(() => _scoring = false);
    }
  }

  void _showMessage(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('🎙️ Pronunciation')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Say this word clearly:', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.word,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Center(
              child: GestureDetector(
                onTap: _toggle,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: _recording
                      ? AppColors.danger
                      : AppColors.accentBlue,
                  child: Icon(
                    _recording ? Icons.stop : Icons.mic,
                    size: 48,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _scoring
                  ? 'Scoring…'
                  : _recording
                  ? 'Tap to stop'
                  : 'Tap to record',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_score != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        '$_score%',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _score! >= 70
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_verdict, textAlign: TextAlign.center),
                      if (_heard.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'I heard: $_heard',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
