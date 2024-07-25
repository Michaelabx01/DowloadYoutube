import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:math' as math;

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _currentTrack = 'No hay pista seleccionada';
  List<SongModel> _songs = [];
  SongModel? _currentSong;
  late AnimationController _animationController;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadSongs();
    
    AudioManager.instance.onEvents((events, args) {
      switch (events) {
        case AudioManagerEvents.start:
        case AudioManagerEvents.ready:
          setState(() {
            _duration = AudioManager.instance.duration;
            _position = AudioManager.instance.position;
          });
          break;
        case AudioManagerEvents.seekComplete:
          setState(() {
            _position = AudioManager.instance.position;
          });
          break;
        case AudioManagerEvents.timeupdate:
          setState(() {
            _position = AudioManager.instance.position;
            _sliderValue =
                _position.inSeconds.toDouble() / _duration.inSeconds.toDouble();
          });
          break;
        case AudioManagerEvents.playstatus:
          setState(() {
            _isPlaying = AudioManager.instance.isPlaying;
          });
          break;
        case AudioManagerEvents.ended:
          AudioManager.instance.next();
          break;
        default:
          break;
      }
    });
  }

  void _loadSongs() async {
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }
    List<SongModel> songs = await _audioQuery.querySongs();
    setState(() {
      _songs = songs;
      setupAudioManager();
    });
  }

  void setupAudioManager() {
    AudioManager.instance.audioList.clear();
    for (var song in _songs) {
      AudioManager.instance.audioList.add(AudioInfo(
        song.data,
        title: song.title,
        desc: song.artist ?? 'Desconocido',
        coverUrl: "assets/images/disc.png",
      ));
    }

    AudioManager.instance.play(auto: false);
  }

  Future<void> _refreshSongs() async {
    _loadSongs();
  }

  void _playSong(SongModel song) {
    AudioManager.instance.start(song.data, song.title,
        desc: song.artist ?? 'Desconocido', cover: "assets/images/disc.png");
    setState(() {
      _currentTrack = song.title;
      _currentSong = song;
      _isPlaying = true;
      _animationController.repeat();
    });
  }

  void _togglePlayPause() {
    AudioManager.instance.playOrPause();
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(double value) {
    final position = Duration(seconds: value.toInt());
    AudioManager.instance.seekTo(position);
    setState(() {
      _position = position;
    });
  }

  double getAngle() {
    var value = _animationController.value;
    return value * 2 * math.pi;
  }

  @override
  void dispose() {
    AudioManager.instance.release();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                              radius: 70.0,
                              percent: _sliderValue,
                              progressColor: const Color(0xffA56169),
                              center: AnimatedBuilder(
                                animation: _animationController,
                                builder: (_, child) {
                                  return Transform.rotate(
                                    angle: getAngle(),
                                    child: child,
                                  );
                                },
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60.0),
                                    child: Image.asset(
                                      AudioManager.instance.info?.coverUrl ??
                                          "assets/images/disc.png",
                                      width: 120.0,
                                      height: 120.0,
                                      fit: BoxFit.cover,
                                    )),
                              )),
                          const SizedBox(height: 16),
                          Text(
                            _currentTrack,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentSong?.artist ?? 'Desconocido',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              _seekTo(value);
                            },
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.grey,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  _position.toString().split('.').first,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  _duration.toString().split('.').first,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.cyanAccent),
                                iconSize: 36,
                                onPressed: () {
                                  AudioManager.instance.previous();
                                },
                              ),
                              IconButton(
                                iconSize: 50.0,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.cyanAccent,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.cyanAccent),
                                iconSize: 36,
                                onPressed: () {
                                  AudioManager.instance.next();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshSongs,
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    SongModel song = _songs[index];
                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          color: Colors.blueGrey.shade800,
                          child: Image.asset(
                            'assets/images/disc.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(song.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(song.artist ?? 'Desconocido',
                          style: const TextStyle(
                              color: Colors.grey, fontFamily: 'Poppins')),
                      onTap: () => _playSong(song),
                      trailing:
                          const Icon(Icons.more_vert, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
