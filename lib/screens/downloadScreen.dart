import 'package:download_music/utilities/download_status.dart';
import 'package:download_music/utilities/youtube_util.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '/widgets/text_input.dart';
import '/models/video_data.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String url = "";
  YoutubeUtil youtubeHandler = YoutubeUtil();
  VideoData videoData = VideoData();
  DownloadStatus downloadStatus = DownloadStatus.ready;
  double _dialogeWindowWidth = 0;
  String _downloadDirectory = '';

  // ToggleButtons states
  List<bool> isSelected = [true, false];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..addListener(() {
        setState(() {});
      });
    videoData.url = "assets/images/logo.png";
    _requestPermissions(); // Solicitar permisos al iniciar
  }

  void _requestPermissions() async {
    await Permission.storage.request();
  }

  void setUrl(String newUrl) async {
    url = newUrl;
    if (await youtubeHandler.loadVideo(url)) {
      setThumbnail();
      setVideoData();
      resetDownloadStatus();
    }
  }

  void setThumbnail() {
    setState(() {
      videoData.url = youtubeHandler.getVideoThumbnailUrl();
    });
  }

  void setVideoData() {
    setState(() {
      videoData.title = youtubeHandler.getVideoTitle();
      videoData.author = youtubeHandler.getVideoAuthor();
    });
  }

  void resetDownloadStatus() {
    setState(() {
      downloadStatus = DownloadStatus.ready;
    });
  }

  void startDownloading() {
    setState(() {
      downloadStatus = DownloadStatus.downloading;
      _animationController.repeat();
    });
  }

  void changeDownloading(bool status) {
    setState(() {
      _animationController.reset();
      if (status) {
        downloadStatus = DownloadStatus.success;
      } else {
        downloadStatus = DownloadStatus.fail;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    final double _helpHeight = 40;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SizedBox(
        width: _width,
        height: _helpHeight,
        child: Stack(
          children: [
            Positioned(
              left: 30.0,
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Colors.grey[700],
                ),
                width: _dialogeWindowWidth,
                height: _helpHeight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 5),
                  child: Center(
                    child: Text(
                      _downloadDirectory,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
            FloatingActionButton(
              onPressed: () async {
                if (_downloadDirectory == '') {
                  _downloadDirectory = await youtubeHandler.getSaveLocation();
                }
                setState(() {
                  if (_dialogeWindowWidth == 0) {
                    _dialogeWindowWidth = _width - 75;
                  } else {
                    _dialogeWindowWidth = 0;
                  }
                });
              },
              child: const Text(
                "?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // Añadir SingleChildScrollView
        child: Container(
          margin: const EdgeInsets.only(
            top: 30,
            left: 36,
            right: 36,
            bottom: 20,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  height: 232,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    image: youtubeHandler.videoLoaded
                        ? DecorationImage(image: NetworkImage(videoData.url))
                        : DecorationImage(image: AssetImage(videoData.url)),
                  ),
                ),
                Visibility(
                  visible: youtubeHandler.videoLoaded ? true : false,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Text(
                            videoData.author + " -",
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              videoData.title,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                    ),
                    child: Text("Inserte Url:",
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ),
                ),
                TextInput(onTap: setUrl),
                const SizedBox(height: 20),
                ToggleButtons(
                  isSelected: isSelected,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < isSelected.length; i++) {
                        isSelected[i] = i == index;
                      }
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Música (MP3)'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Video (MP4)'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Visibility(
                  visible: youtubeHandler.videoLoaded ? true : false,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (downloadStatus != DownloadStatus.downloading &&
                              downloadStatus != DownloadStatus.success) {
                            await Permission.storage.request();
                            startDownloading();
                            final bool success = isSelected[0]
                                ? await youtubeHandler.downloadMP3()
                                : await youtubeHandler.downloadMP4();
                            changeDownloading(success);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15)),
                        child: (downloadStatus == DownloadStatus.downloading)
                            ? CircularPercentIndicator(
                                radius: 60.0,
                                lineWidth: 5.0,
                                percent: 1.0 - _animationController.value,
                                center: const Icon(Icons.hourglass_empty, size: 60, color: Colors.white),
                                progressColor: Colors.white,
                              )
                            : (downloadStatus == DownloadStatus.ready)
                                ? const Icon(Icons.download, size: 60, color: Colors.white)
                                : (downloadStatus == DownloadStatus.success)
                                    ? const Icon(Icons.done, size: 60, color: Colors.white)
                                    : const Icon(Icons.close, size: 60, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
