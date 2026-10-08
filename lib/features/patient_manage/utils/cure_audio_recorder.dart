import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'cure_audio_file_util.dart';

/// Microphone recording for cure progress notes (desktop/mobile).
class CureAudioRecorder {
  CureAudioRecorder._();
  static final CureAudioRecorder instance = CureAudioRecorder._();

  AudioRecorder? _recorder;
  String? _tempPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get tempPath => _tempPath;

  AudioRecorder get _activeRecorder => _recorder ??= AudioRecorder();

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<bool> get canRecord async {
    if (!_isSupportedPlatform) return false;
    return _activeRecorder.hasPermission();
  }

  Future<void> start() async {
    if (!_isSupportedPlatform) return;
    if (_isRecording) return;

    final hasPermission = await _activeRecorder.hasPermission();
    if (!hasPermission) {
      throw StateError('لا يوجد إذن للميكروفون');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/cure_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _activeRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _tempPath = path;
    _isRecording = true;
  }

  Future<String?> stop() async {
    if (!_isRecording) return _tempPath;
    final path = await _activeRecorder.stop();
    _isRecording = false;
    _tempPath = path ?? _tempPath;
    return _tempPath;
  }

  Future<void> cancel() async {
    if (_isRecording) {
      await _activeRecorder.stop();
      _isRecording = false;
    }
    final path = _tempPath;
    _tempPath = null;
    if (path != null) {
      await deleteAudioFileIfExists(path);
    }
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder?.dispose();
    _recorder = null;
  }
}
