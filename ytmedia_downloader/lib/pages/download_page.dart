
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

/*
 * Creating a controller for controlling the audio.
 * controller will be doing following things:
 *  - attach a widget to player
 *    - 
 *  - deattach a widget from a player
 *  - 
*/

class MusicCard extends StatefulWidget {
  @override
  MusicCard({
    super.key,
    required this.title,
    required this.singer,
    required this.composer,
    required this.source,
    required this.val,
    required this.state,
    required this.index
    });
  
  String title;
  String singer;
  String composer;
  String source;
  AudioPlayer player = AudioPlayer();
  ValueNotifier<int> val;
  MusicCardStateModel state;
  int index;

  State<MusicCard> createState() => _MusicCardState() ;
}

class _MusicCardState extends State<MusicCard> {
  bool _isPlaying = false;
  Duration _currentSliderValue = Duration(milliseconds: 0);
  bool isPlayerInit = false;
  bool isPlayerOn = false;
  PlayerState? playerState;
  Duration? _duration; 
  bool _isDurationLoading = true;
  StreamSubscription<Duration>? _totalDurationStream;
  MyAudioPlayer? _player;
  // Stream<Duration>? _currentDurationStream;
  StreamSubscription<Duration>? _currentDurationSubStream;
  StreamSubscription<Duration>? ds ;

  // set player(MyAudioPlayer? p){
  //   _player = p;
  // }

  Future<void> loadData() async {
    print("currentPosition: ${widget.state.currentPosition}");
    setState(() {
      _currentSliderValue = widget.state.currentPosition;
    });
    print("slider value now is : ${_currentSliderValue.inSeconds.toDouble()}");
    _duration = widget.state.totalDuration ;
    playerState = widget.state.playerState ;

    // cancelling the sub for dormantCurrentDuration
    widget.state.dormantCurrentDurationSub?.cancel();

    await widget.player.setSourceUrl(widget.source);

    print("xxxxxxxxx inside loadDate()");
    print("${widget.state.currentPosition}, ${widget.state.totalDuration}");
    Stream<Duration> d = widget.player.onDurationChanged ;
    if (_duration!.inMilliseconds.toInt() == 0){
      ds = d.listen(
        (d) {
          setState(() {
            _duration = d;
          });
          widget.state.totalDuration ;
        }
      );
    }
    
    await widget.player.seek(_currentSliderValue);
    await widget.player.pause();
    if (playerState == PlayerState.playing ){
      await widget.player.resume();
    } 
    // else {
    //   await widget.player.pause();
    // }

    _currentDurationSubStream = widget.player.onPositionChanged.listen((d) {
      setState(() {
        _currentSliderValue = d;
      });
    });
    
  }

  @override
  void initState(){
    super.initState();
    loadData();
  }

  @override
  void dispose(){
    print("disposing stream ${_currentSliderValue}, ${_duration}");
    widget.state.currentPosition = _currentSliderValue ;
    widget.state.playerState = playerState! ;
    widget.state.totalDuration = _duration! ;
    _currentDurationSubStream!.cancel() ;
    if (playerState == PlayerState.playing){
      print("initializing dormantCurrentDurationSub");
      print("${widget.player}");
      widget.state.dormantCurrentDurationSub = widget.player.onPositionChanged.listen(
        (d){
          widget.state.currentPosition = d;
        }
      );
    }
    ds!.cancel();
    // widget.player.dispose();
    super.dispose();
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
              print(playerState);
              if (playerState == PlayerState.stopped || playerState == PlayerState.paused){
                print("hii");
                await widget.player.resume();
                setState(() {
                  playerState = PlayerState.playing ;
                });
              }
              else if (playerState == PlayerState.playing){
                await widget.player.pause();
                setState(() {
                  playerState = PlayerState.paused ;
                });
              }
            },
            child: switch(playerState){
              PlayerState.stopped || PlayerState.paused => Icon(
                Icons.play_arrow
              ),
              PlayerState.playing => Icon(
                Icons.pause
              ),
              _ => Icon(
                Icons.play_arrow
              )
            },
          ),
        ),
        Slider(
          value: _currentSliderValue.inMilliseconds.toDouble(),
          max: _duration!.inMilliseconds.toDouble() == 0? 4000: _duration!.inMilliseconds.toDouble(),
          onChanged: (double value) async {
            setState(() {
              _currentSliderValue = Duration(milliseconds: value.toInt());
            });
            // state.sliderValue = _currentSliderValue;
            await widget.player.seek(Duration(milliseconds: value.toInt()));
          },
        )
        ],
      )
    );
  }
}


class MusicCardStateModel /*extends ChangeNotifier*/ {
  Duration currentPosition;
  Duration totalDuration;
  PlayerState playerState;
  StreamSubscription<Duration>? dormantCurrentDurationSub ;

  MusicCardStateModel(this.currentPosition, this.totalDuration, this.playerState);
}

class MusicCardList extends StatelessWidget {
  MusicCardList({super.key});

  Map<int, MusicCardStateModel> mCStateStore = {};

  final ValueNotifier<int> val = ValueNotifier<int>(0);

  void loadData() {
    String source = "assets/Free-WAV-Sample.mp3";
    for (int i = 0; i< 10; i++){
      MusicCardStateModel mcs = MusicCardStateModel(
        Duration(milliseconds: 0), 
        Duration(milliseconds: 0), 
        PlayerState.stopped);
      mCStateStore[i] = mcs;
    }
  }

  // @override 
  // void initState(){
  //   super.initState();
  //   loadData();
  // }

  @override
  Widget build(BuildContext context) {

    // return FutureBuilder<void>(
    //   future: loadData(), 
    //   builder: (context, snapshot){
    //     if (snapshot.connectionState == ConnectionState.waiting){
    //       return CircularProgressIndicator();
    //     } 
        
    //     if (snapshot.hasError){
    //       return Text("Error: ${snapshot.error}");
    //     }

        // if (snapshot.hasData){
        loadData();
          return ListView(
                children: <Widget>[
                  for (int i =0; i < 10; i++)
                    MusicCard(
                      title: "Title of the song", 
                      singer: "Dummy Singer", 
                      composer: "Dummy Composer", 
                      source: "assets/Free-WAV-Sample.mp3",
                      val: val,
                      state: mCStateStore[i]!,
                      index: i,
                      )
                ],
              );
        // }

        // return Text("no data");
      // }
      // );
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