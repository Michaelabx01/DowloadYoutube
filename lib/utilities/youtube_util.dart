import 'dart:developer';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class YoutubeUtil {
  late final YoutubeExplode _yt;
  late final FlutterFFmpeg _flutterFFmpeg;
  late String url;
  var video;
  bool videoLoaded = false;

  YoutubeUtil() {
    this._yt = new YoutubeExplode();
    _flutterFFmpeg = new FlutterFFmpeg();
  }

  void cleanUp() {
    this._yt.close();
  }

  Future<bool> loadVideo(String url) async {
    try {
      this.url = url;
      this.video = await _yt.videos.get(url);
      videoLoaded = true;
      return true;
    } catch (e) {
      log("Error occurred: " + e.toString());
      return false;
    }
  }

  String getVideoAuthor() {
    if (videoLoaded) {
      return this.video.author;
    } else {
      return "No video loaded";
    }
  }

  String getVideoTitle() {
    if (videoLoaded) {
      return this.video.title;
    } else {
      return "No video loaded";
    }
  }

  String getVideoThumbnailUrl() {
    if (videoLoaded) {
      try {
        return this.video.thumbnails.highResUrl;
      } catch (e) {
        return "";
      }
    } else {
      return "No video loaded";
    }
  }

  Future<String> getSaveLocation() async {
    var downloadsDirectory = await getExternalStorageDirectory();
    return downloadsDirectory.toString();
  }

  Future<bool> downloadMP3() async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(url);
      var audioStream = manifest.audioOnly.last;

      var downloadsDirectory = await getExternalStorageDirectory();
      var filePath = path.join(downloadsDirectory!.path,
          '${video.title}.${audioStream.container.name}');

      filePath = filePath.replaceAll(' ', '');
      filePath = filePath.replaceAll("'", '');
      filePath = filePath.replaceAll('"', '');

      var file = File(filePath);
      var fileStream = file.openWrite();

      await _yt.videos.streamsClient.get(audioStream).pipe(fileStream);

      await fileStream.flush();
      await fileStream.close();

      var arguments = [];
      if (filePath.endsWith('.mp4') || filePath.endsWith('.webm')) {
        arguments = ["-i", filePath, "-acodec", "aac", filePath.replaceAll('.webm', '.aac').replaceAll('.mp4', '.aac')];
      } else if (filePath.endsWith('.aac')) {
        log('Already .aac');
        return true;
      } else {
        log('Unknown format to convert.');
        return false;
      }
      await _flutterFFmpeg
          .executeWithArguments(arguments)
          .then((rc) => log("FFmpeg process exited with rc $rc"));

      if (filePath.endsWith('.webm') || filePath.endsWith('.mp4')) {
        file.delete();
      }

      log("Everything is fine!");
      return true;
    } catch (e) {
      log("Something went wrong: ${e.toString()}");
      return false;
    }
  }

  Future<bool> downloadMP4() async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(url);
      var videoStream = manifest.muxed.last;

      var downloadsDirectory = await getExternalStorageDirectory();
      var filePath = path.join(downloadsDirectory!.path,
          '${video.title}.${videoStream.container.name}');

      filePath = filePath.replaceAll(' ', '');
      filePath = filePath.replaceAll("'", '');
      filePath = filePath.replaceAll('"', '');

      var file = File(filePath);
      var fileStream = file.openWrite();

      await _yt.videos.streamsClient.get(videoStream).pipe(fileStream);

      await fileStream.flush();
      await fileStream.close();

      log("Everything is fine!");
      return true;
    } catch (e) {
      log("Something went wrong: ${e.toString()}");
      return false;
    }
  }
}
