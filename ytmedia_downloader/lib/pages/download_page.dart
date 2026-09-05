
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

enum PlayerStreamEvent{
  SEEKER_EVENT,
  DISPOSE_EVENT_REQ, //dispose event request
  INITIALIZE_EVENT,
  DISPOSE_EVENT_COMP, // dispose event complete
  PLAYBACK_COMPLETED, // previous running playback has completed
  NEW_PLAYER_READY, // new player is ready
}

class PlayerStreamData {
  int idx;
  PlayerStreamEvent event;
  AudioPlayer? player;

  PlayerStreamData({required this.idx, required this.event, this.player});
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
    required this.index,
    required this.playerController,
    required this.player
    });
  
  String title;
  String singer;
  String composer;
  String source;
  AudioPlayer player;
  ValueNotifier<int> val;
  MusicCardStateModel state;
  int index;
  StreamController<PlayerStreamData> playerController;

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
  StreamSubscription<void>? playerComESub ;
  StreamSubscription<PlayerStreamData>? newPlayerSub;

  StreamSubscription<PlayerStreamData>? disposePlayerSub;

  StreamSubscription<PlayerStreamData>? initializePlayerSub;
  // set player(MyAudioPlayer? p){
  //   _player = p;
  // }

  void initNewPlayer(){
    // this function will assign player the newly created audioPlayer
    newPlayerSub = widget.playerController.stream.listen(
      (e) {
        if (e.event == PlayerStreamEvent.NEW_PLAYER_READY){
          widget.player = e.player!;
        }
      }
    );
  }

  void seekPlayer(){
    print("sending a seeker request for idx: ${widget.index}");
    widget.playerController.sink.add(
      PlayerStreamData(idx: widget.index, event: PlayerStreamEvent.SEEKER_EVENT)
    );
  }

  void softDisposePlayer(){
    // initialize this 
    disposePlayerSub = widget.playerController.stream.listen(
      (e){
        print("current idx: ${widget.index}");
        if (e.event == PlayerStreamEvent.DISPOSE_EVENT_REQ
        && e.idx == widget.index
        ){
          print("received a soft dispose request of player for idx: ${widget.index}");
          // dispose the player resource here
          _currentDurationSubStream!.cancel();
          ds?.cancel();
          widget.state.dormantCurrentDurationSub?.cancel();
          widget.state.currentPosition = _currentSliderValue;
          widget.state.totalDuration = _duration! ;
          widget.state.playerState = PlayerState.paused ;

          setState(() {
            playerState = PlayerState.paused ;
          });

          playerComESub?.cancel();

          // after disposing the player resource send dispose event complete to the stream.
          widget.playerController.sink.add(
            PlayerStreamData(idx: widget.index, event: PlayerStreamEvent.DISPOSE_EVENT_COMP)
          );
        }
      }
    );
  }

  void initializePlayer() async {
    // this function is fired when the player is not being played by 
    // the current widget.
    // This function acquires the resources of player and sets them.

    initializePlayerSub = widget.playerController.stream.listen(
      (e) async {
        if (e.event == PlayerStreamEvent.INITIALIZE_EVENT
        && e.idx == widget.index
        ){
          // initialize all the subscription to the player
          // set the source of player
          // restore state of player
          // start the player
          // _currentSliderValue = widget.state.currentPosition;
          // _duration = widget.state.totalDuration ;

          print("received a initialize request of player for idx: ${widget.index}");

          setState(() {
            playerState = PlayerState.playing;
          });

          await widget.player.setSourceUrl(widget.source);

          if (_duration!.inMilliseconds.toInt() == 0){
            ds = widget.player.onDurationChanged.listen(
              (d) {
                setState(() {
                  _duration = d;
                });
              }
            );
          }

          print("currentSliderValue: ${_currentSliderValue}");
          await widget.player.seek(_currentSliderValue);
          await widget.player.pause();
          await widget.player.resume();

          _currentDurationSubStream = widget.player.onPositionChanged.listen((d) {
            setState(() {
              _currentSliderValue = d;
            });
          });

          playerComESub = widget.player.onPlayerComplete.listen((_) async {
            await widget.player.dispose();
            widget.state.currentPosition = Duration(milliseconds: 0);
            _currentSliderValue = Duration(milliseconds: 0);
            widget.state.playerState = PlayerState.paused;
            
            setState(() {
              playerState = PlayerState.paused ;
            });
            widget.playerController.sink.add(
              PlayerStreamData(idx: widget.index,event: PlayerStreamEvent.PLAYBACK_COMPLETED)
            );
          });
        }
      }
    );
  }

  Future<void> loadData() async {
    // print("currentPosition: ${widget.state.currentPosition}");
    _currentSliderValue = widget.state.currentPosition;
    // print("slider value now is : ${_currentSliderValue.inSeconds.toDouble()}");
    _duration = widget.state.totalDuration ;
    playerState = widget.state.playerState ;

    // cancelling the sub for dormantCurrentDuration
    widget.state.dormantCurrentDurationSub?.cancel();

    // await widget.player.setSourceUrl(widget.source);

    print("xxxxxxxxx inside loadDate()");
    print("${widget.state.currentPosition}, ${widget.state.totalDuration}");
    // Stream<Duration> d = widget.player.onDurationChanged ;
    // if (_duration!.inMilliseconds.toInt() == 0){
    //   ds = d.listen(
    //     (d) {
    //       setState(() {
    //         _duration = d;
    //       });
    //       widget.state.totalDuration ;
    //     }
    //   );
    // }
    
    // await widget.player.seek(_currentSliderValue);
    // await widget.player.pause();
    // if (playerState == PlayerState.playing ){
    //   await widget.player.resume();
    // } 

    if (playerState == PlayerState.playing){
      _currentDurationSubStream = widget.player.onPositionChanged.listen((d) {
        setState(() {
          _currentSliderValue = d;
        });
      });
    }
    // _currentDurationSubStream = widget.player.onPositionChanged.listen((d) {
    //   setState(() {
    //     _currentSliderValue = d;
    //   });
    // });
    
  }

  @override
  void initState(){
    super.initState();
    loadData();
    initializePlayer();
    softDisposePlayer();
    initNewPlayer();
    print("inside initState: ${_currentSliderValue}");
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
    initializePlayerSub!.cancel();
    disposePlayerSub!.cancel();
    newPlayerSub!.cancel();
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
              if (playerState == PlayerState.paused || 
                playerState == PlayerState.stopped
              ){
                print('sending a request to acquire a player and start playing');
                seekPlayer();
              } 
              else if (playerState == PlayerState.playing){
                print("stopping the player");
                await widget.player.pause();
                setState(() {
                  playerState = PlayerState.stopped;
                });
              }
              // print(playerState);
              // if (playerState == PlayerState.stopped || playerState == PlayerState.paused){
              //   print("hii");
              //   await widget.player.resume();
              //   setState(() {
              //     playerState = PlayerState.playing ;
              //   });
              // }
              // else if (playerState == PlayerState.playing){
              //   await widget.player.pause();
              //   setState(() {
              //     playerState = PlayerState.paused ;
              //   });
              // }
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

  StreamController<PlayerStreamData> playerController = StreamController<PlayerStreamData>.broadcast();

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
    int ownerIdx = -1;
    StreamSubscription<PlayerStreamData> controllerHub = playerController.stream.listen(
      (e) {
        print("inside controller hub: ");
        print("current event: ${e.event}, index: ${e.idx}");
        if (e.event == PlayerStreamEvent.SEEKER_EVENT){
          if (ownerIdx == -1
          || ownerIdx == e.idx
          ){
            playerController.sink.add(
              PlayerStreamData(idx: e.idx, event: PlayerStreamEvent.INITIALIZE_EVENT)
            );
            ownerIdx = e.idx;
          } else {
            playerController.sink.add(
              PlayerStreamData(idx: ownerIdx, event: PlayerStreamEvent.DISPOSE_EVENT_REQ)
            );
            ownerIdx = e.idx;
          }
        } 
        else if (e.event == PlayerStreamEvent.DISPOSE_EVENT_COMP){
          playerController.sink.add(
            PlayerStreamData(idx: ownerIdx, event: PlayerStreamEvent.INITIALIZE_EVENT)
          );
        }
        else if (e.event == PlayerStreamEvent.PLAYBACK_COMPLETED){
          playerController.sink.add(
            PlayerStreamData(idx: e.idx, event: PlayerStreamEvent.NEW_PLAYER_READY, player: AudioPlayer())
          );
        }
      }
    );
    AudioPlayer player = AudioPlayer();
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
                      playerController: playerController,
                      player: player 
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