
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
    required this.player,
    required this.playerNotifier,
    required this.val,
    required this.stateStore,
    required this.index
    });
  
  String title;
  String singer;
  String composer;
  String source;
  MyAudioPlayer player;
  ValueNotifier<MyAudioPlayer> playerNotifier;
  ValueNotifier<int> val;
  Map<int, MusicCardStateModel> stateStore;
  int index;

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

  // set player(MyAudioPlayer? p){
  //   _player = p;
  // }

  @override
  void initState(){
    super.initState();
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
    MusicCardStateModel? mc = widget.stateStore[widget.index] ;
    
    if (mc != null && mc?.duration != 0){
      _duration = Duration(microseconds: (mc._duration*1000).round());
      _isDurationLoading = false;
    } else {
      Stream<Duration> stream = await widget.player!.onDurationChanged;
      _totalDurationStream = stream.listen(
        (data){
          setState(() {
            _duration = data;
            _isDurationLoading = false;
          });
          // print(_duration);
        }
      );
      mc?._duration = _duration!.inMicroseconds.toDouble();
    }
  }

  @override
  Widget build(BuildContext context){

    MusicCardStateModel? mc = widget.stateStore[widget.index] ;
    // print("${mc}");
    // print("mc duration: ${mc?._duration}");
    if (mc != null && mc._duration != 0){
      // print("\nxxxxxxxxxxxx- mc is not null for ${widget.index}, ${identityHashCode(mc).toRadixString(16)}\n");

      _duration = Duration(microseconds: (mc._duration*1000).round());
      _isDurationLoading = false;
      // isPlayerInit = true;
      _isPlaying = mc._isPlaying;
      // widget.player = mc?.player ?? widget.player;
      // setState(() {
      //   _currentSliderValue = mc!.sliderValue ;
      // });
    } else {
      // print("\nxxxxxxxxxxx- mc is null for ${widget.index}, ${identityHashCode(mc).toRadixString(16)}\n");
      widget.stateStore[widget.index] = MusicCardStateModel();
      mc = widget.stateStore[widget.index];
      // mc?.player = widget.player;
    }
    
    return Card(
      child: Column(
        children: [
          ListTile(
          title: Text(widget.title),
          subtitle: Text("singer: ${widget.singer}, Composer: ${widget.composer}"),
          trailing: InkWell(
            onTap: () async {
              
              // _player = widget.player;
              
              // widget.player.acquiredBy?.player = null;
              // widget.player.acquiredBy = this ;
              // widget.player.acquiredBy?.player = widget.player;
              // widget.player.isAcquired = true;
              print('previous value ${widget.val.value}');
              widget.val.value ++;
              print('new value is ${widget.val.value}');
              if (widget.player.acquiredBy != this && isPlayerInit == true){
                isPlayerInit = false;
              }

              if (isPlayerInit == false){
                if (widget.player!.isAcquired){
                  print('player not acquired yet.');
                  // widget.playerNotifier.value.acquiredBy!.isPlayerInit = false;
                  // widget.playerNotifier.value.acquiredBy!._isPlaying = false;
                  // print('d1');
                  // widget.playerNotifier.value.acquiredBy!._currentDurationSubStream!.cancel();
                  // widget.playerNotifier.value.acquiredBy!._currentDurationSubStream = null;
                  // print('d2');
                  // widget.playerNotifier.value.acquiredBy!._currentDurationStream = null;
                  widget.playerNotifier.value = MyAudioPlayer();
                  if (widget.player!.acquiredBy!._currentDurationSubStream == null){
                    print("previous widget c duration stream is null");
                  }
                  widget.playerNotifier.value.acquiredBy = this;
                  print('previously acquired player');
                  print(widget.player.acquiredBy);
                  // setState(() {
                  //   widget.player!.acquiredBy!.isPlayerInit = false;
                  //   widget.player!.acquiredBy!._isPlaying = false;
                  //   print("duration stream: ${widget.player!.acquiredBy!._currentDurationStream}");
                  //   widget.player!.acquiredBy!._currentDurationSubStream!.cancel();
                  //   widget.player!.acquiredBy!._currentDurationStream = null;
                  //   widget.player!.acquiredBy = this;
                  // });

                } else {
                  widget.playerNotifier.value = MyAudioPlayer();
                  widget.playerNotifier.value.acquiredBy = this;
                  widget.playerNotifier.value.isAcquired = true;
                  // widget.player!.acquiredBy = this;
                  // widget.player!.isAcquired = true;
                }
                // await widget.player!.setSourceUrl(widget.source);
                // await widget.player!.seek(Duration(milliseconds: 0));
                await widget.playerNotifier.value.setSourceUrl(widget.source);
                await widget.playerNotifier.value.seek(Duration(milliseconds: 0));
                await Future.delayed(const Duration(seconds: 1));
                isPlayerInit = true;
              }

              _loadDuration();
              print("is player present: ${widget.player!.acquiredBy}");
              if (widget.player!.acquiredBy == this){
                _currentDurationStream = widget.player!.onPositionChanged ;
                print("acquired by ${widget.player!.acquiredBy} 352");
                // print()
                  _currentDurationSubStream = _currentDurationStream!.listen(
                  (data) {
                    setState(() {
                      _currentSliderValue = data.inMilliseconds.toDouble();
                      if (_currentSliderValue == _duration!.inMilliseconds.toDouble()){
                        _isPlaying = false;
                        print("isPlaying: $_isPlaying");
                      }
                    });
                    // print(_currentSliderValue);
                  }
                );
              } else {
                print("not acquired by this");
                _currentDurationStream = null;
              }

              if (_isPlaying){ // if player is playing then pause it
                mc?.isPlaying = false;
                await widget.player!.pause();
              } else {
                mc?.isPlaying = true;
                await widget.player!.resume();
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
            mc?.sliderValue = _currentSliderValue;
            await widget.player!.seek(Duration(milliseconds: value.toInt()));
          },
        )
        ],
      )
    );
  }
}


class MusicCardStateModel /*extends ChangeNotifier*/ {
  double _sliderValue = 0;
  double _duration = 0;
  bool _isPlaying = false;
  // MyAudioPlayer? _player ;

  double get sliderValue => _sliderValue ;
  double get duration => _duration ;
  bool get isPlaying => _isPlaying;
  // MyAudioPlayer? get player => _player;

  set sliderValue(double val){
    _sliderValue = val;
    // notifyListeners();
  }

  set duration(double d){
    _duration = d;
    // notifyListeners();
  }

  set isPlaying(bool isP){
    _isPlaying = isP;
    // notifyListeners();
  }

  // set player(MyAudioPlayer? p){
  //   _player = p;
  // }
}

class MusicCardList extends StatelessWidget {
  MusicCardList({super.key});

  Map<int, MusicCardStateModel> mCStateStore = {};

  // final player = MyAudioPlayer();
  final ValueNotifier<MyAudioPlayer> playerNotifier = ValueNotifier<MyAudioPlayer>(MyAudioPlayer());

  final ValueNotifier<int> val = ValueNotifier<int>(0);


  @override
  Widget build(BuildContext context){
    return ValueListenableBuilder<MyAudioPlayer>(
      valueListenable: playerNotifier, 
      builder: (BuildContext context, MyAudioPlayer player, Widget? child){
        return ListView(
          children: <Widget>[
            for (int i =0; i < 10; i++)
              MusicCard(
                title: "Title of the song", 
                singer: "Dummy Singer", 
                composer: "Dummy Composer", 
                source: "assets/Free-WAV-Sample.mp3",
                player: player,
                playerNotifier: playerNotifier,
                val: val,
                stateStore: mCStateStore,
                index: i,
                )
          ],
        );
      });
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