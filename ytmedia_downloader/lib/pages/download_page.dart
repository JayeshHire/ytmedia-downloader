
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class DownloadsPage extends StatelessWidget{
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: MediaChoiceWidget()
    );
  }
}

class MediaChoiceWidget extends StatefulWidget {
  const MediaChoiceWidget({super.key});
  
  @override
  State<MediaChoiceWidget> createState() => _MediaChoiceWidget();
}

enum MediaChoice { thumbnail_poster, music, video}

class _MediaChoiceWidget extends State<MediaChoiceWidget> {
  ValueNotifier<MediaChoice> media = ValueNotifier<MediaChoice>(MediaChoice.thumbnail_poster);

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          SegmentedButton<MediaChoice>(
            segments: const <ButtonSegment<MediaChoice>>[
            ButtonSegment<MediaChoice>(
              value: MediaChoice.thumbnail_poster,
              label: Text("Thumbnail Poster"),
              icon: Icon(Icons.picture_in_picture)
            ),
            ButtonSegment<MediaChoice>(
              value: MediaChoice.music,
              label: Text("Music"),
              icon: Icon(Icons.music_note)
            ),
            ButtonSegment<MediaChoice>(
              value: MediaChoice.video,
              label: Text("Video"),
              icon: Icon(Icons.video_library)
            )
          ], 
          selected: <MediaChoice>{media.value},
          onSelectionChanged: (Set<MediaChoice> newSelection){
            // _changeMedia(newSelection.first);
            setState(() {
              media.value = newSelection.first;
            });
          },
      ),
      Expanded(
        child: ValueListenableBuilder<MediaChoice>(
          valueListenable: media, 
          builder: (context, value, child) {
            return DownloadsBody(
              key: ValueKey(value),
              selectedMedia: value,
            );
          }
        ),
      )
      ],
    );
  }

  @override 
  void dispose(){
    media.dispose();
    super.dispose();
  }
}

class DownloadsBody extends StatefulWidget {
  DownloadsBody({super.key, required this.selectedMedia});

  MediaChoice selectedMedia;

  @override
  State<DownloadsBody> createState() => _DownloadsBodyState(selectedMedia: selectedMedia);
}

class _DownloadsBodyState extends State<DownloadsBody>{

  _DownloadsBodyState({required this.selectedMedia});

  MediaChoice selectedMedia;

  @override
  Widget build(BuildContext context){
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(0.8),
        child: Column(
          children: <Widget>[
              Text("Hello world"),
              Expanded(
                child: switch (selectedMedia){
                  MediaChoice.thumbnail_poster => PosterCardList(),
                  MediaChoice.music => MusicCardList(),
                  MediaChoice.video => VideoCardList()
                },
              )
            ]
        ),
        ),
    );
  }
}


class PosterCardList extends StatelessWidget{
  PosterCardList({super.key});

  @override
  Widget build(BuildContext context){
    return ListView(
      children: <Widget>[
        for (int i = 0; i < 10; i++)
          PosterCard(
            title: "Title of the video", 
            channelTitle: "Channel Title", 
            pubDatetime: "2023-08-28T20:43:44", 
            source: "assets/mqdefault.jpg"
            )
      ],
    );
  }
}

class PosterCard extends StatelessWidget {
  @override
  PosterCard({
    super.key, 
    required this.title, 
    required this.channelTitle, 
    required this.pubDatetime,
    required this.source
  });
  
  String title;
  String channelTitle;
  String pubDatetime;
  String source;

  @override
  Widget build(BuildContext context){
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          children: [
            Text(channelTitle),
            Text(pubDatetime)
          ],
        ),
        leading: Image(image: AssetImage(source)),
      ),
    );
  }
}

class MyAudioPlayer extends AudioPlayer {
  bool isAcquired = false;
  _MusicCardState? acquiredBy ;
}

class MusicCard extends StatefulWidget {
  @override
  MusicCard({
    super.key,
    required this.title,
    required this.singer,
    required this.composer,
    required this.source,
    required this.player
    });
  
  String title;
  String singer;
  String composer;
  String source;
  MyAudioPlayer player;

  State<MusicCard> createState() => _MusicCardState() ;
}

class _MusicCardState extends State<MusicCard> {
  bool _isPlaying = false;
  double _currentSliderValue = 0;
  bool isPlayerInit = false;
  bool isPlayerOn = false;
  Duration? _duration; 
  bool _isDurationLoading = true;
  StreamSubscription<Duration>? _totalDurationStream;
  MyAudioPlayer? _player;
  Stream<Duration>? _currentDurationStream;
  StreamSubscription<Duration>? _currentDurationSubStream;

  set player(MyAudioPlayer? p){
    _player = p;
  }

  @override
  void initState(){
    super.initState();
    // _loadDuration();
    // Stream<Duration> _currentDurationStream = _player!.onPositionChanged ;
    // _currentDurationSubStream = _currentDurationStream.listen(
    //   (data) {
    //     setState(() {
    //       _currentSliderValue = data.inMilliseconds.toDouble();
    //     });
    //   }
    // );
  }

  @override
  void dispose(){
    _currentDurationSubStream?.cancel();
    _totalDurationStream?.cancel();
    _currentDurationStream = null;
    super.dispose();
  }

  Future<void> _loadDuration() async {
    print("inside load duration func");
    Stream<Duration> stream = await _player!.onDurationChanged;
    _totalDurationStream = stream.listen(
      (data){
        setState(() {
          _duration = data;
          _isDurationLoading = false;
        });
        print(_duration);
      }
    );
  }


  @override
  Widget build(BuildContext context){
    return Card(
      child: Column(
        children: [
          ListTile(
          title: Text(widget.title),
          subtitle: Text("singer: ${widget.singer}, Composer: ${widget.composer}"),
          trailing: InkWell(
            onTap: () async {
              
              _player = widget.player;
              
              // widget.player.acquiredBy?.player = null;
              // widget.player.acquiredBy = this ;
              // widget.player.acquiredBy?.player = widget.player;
              // widget.player.isAcquired = true;
              
              if (isPlayerInit == false){
                if (_player!.isAcquired){
                  setState(() {
                    _player!.acquiredBy!.isPlayerInit = false;
                    _player!.acquiredBy!._isPlaying = false;
                    print("duration stream: ${_player!.acquiredBy!._currentDurationStream}");
                    _player!.acquiredBy!._currentDurationSubStream!.cancel();
                    _player!.acquiredBy!._currentDurationStream = null;
                    _player!.acquiredBy = this;
                  });
                  // _player!.acquiredBy!._currentDurationSubStream!.cancel();
                  if (_player!.acquiredBy!._currentDurationSubStream == null){
                    print("previous widget c duration stream is null");
                  }
                } else {
                  _player!.acquiredBy = this;
                  _player!.isAcquired = true;
                }
                await _player!.setSourceUrl(widget.source);
                await _player!.seek(Duration(milliseconds: 0));
                await Future.delayed(const Duration(seconds: 1));
                isPlayerInit = true;
              }

              _loadDuration();
              _currentDurationStream = _player!.onPositionChanged ;
              if (_player!.acquiredBy == this){
                print("acquired by ${_player!.acquiredBy}");
                  _currentDurationSubStream = _currentDurationStream!.listen(
                  (data) {
                    setState(() {
                      _currentSliderValue = data.inMilliseconds.toDouble();
                      if (_currentSliderValue == _duration!.inMilliseconds.toDouble()){
                        _isPlaying = false;
                        print("isPlaying: $_isPlaying");
                      }
                    });
                  }
                );
              }

              if (_isPlaying){ // if player is playing then pause it
                await _player!.pause();
              } else {
                await _player!.resume();
              }
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
            child: switch(_isPlaying){
              true => Icon(
                Icons.pause
              ),
              false => Icon(
                Icons.play_arrow
              )
            },
          ),
        ),
        Slider(
          value: _currentSliderValue,
          max: _isDurationLoading ? 4000 : _duration!.inMilliseconds.toDouble(),
          onChanged: (double value) async {
            setState(() {
              _currentSliderValue = value;
            });
            await _player!.seek(Duration(milliseconds: value.toInt()));
          },
        )
        ],
      )
    );
  }
}

class MusicCardList extends StatelessWidget {
  MusicCardList({super.key});

  final player = MyAudioPlayer();

  @override
  Widget build(BuildContext context){
    return ListView(
      children: <Widget>[
        for (int i =0; i < 10; i++)
          MusicCard(
            title: "Title of the song", 
            singer: "Dummy Singer", 
            composer: "Dummy Composer", 
            source: "assets/Free-WAV-Sample.mp3",
            player: player
            )
      ],
    );
  }
}

class VideoCard extends StatelessWidget {
  VideoCard({super.key});

  @override
  Widget build(BuildContext context){
    return Card(
      child: ListTile(
        title: Text("Video Title"),
        subtitle: Text("Video subtitle or additional information"),
        leading: Image(image: AssetImage("assets/mqdefault.jpg")),
      ),
    );
  }
}

class VideoCardList extends StatelessWidget {
  VideoCardList({super.key});

  @override
  Widget build(BuildContext context){
    return ListView(
      children: <Widget>[
        for (int i= 0; i < 10; i++)
          VideoCard()
      ],
    );
  }
}