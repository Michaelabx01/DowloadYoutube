import 'package:flutter/material.dart';
import 'downloadScreen.dart';
import 'musicPlayerScreen.dart';
import 'youtubeScreen.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DownloadScreen(),
    YoutubeScreen(),
    MusicPlayerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Descarga',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'YouTube',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Reproductor', // Nueva pestaña
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueGrey.shade800,
        onTap: _onItemTapped,
      ),
    );
  }
}
