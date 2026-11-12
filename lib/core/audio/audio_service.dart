import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _player;

  AudioService([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  Future<void> playCompletionSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/bell.wav'));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('Audio dispose error: $e');
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
