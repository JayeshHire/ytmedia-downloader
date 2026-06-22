import 'package:flutter/material.dart';
import 'pages/download_page.dart';
import 'pages/bookmarks_page.dart';
import 'pages/history_page.dart';


void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  List<Widget> pages = [
    MediaSearchBar(),
    DownloadsPage(),
    BookmarksPage(),
    HistoryPage()
  ];

  final ValueNotifier<int> pageIndex = ValueNotifier<int>(0) ;

  @override
  void dispose(){
    pageIndex.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            }
            ),
          title: Text("Download Ytmedia"),
          ),
        body: ValueListenableBuilder(
          valueListenable: pageIndex, 
          builder: (context, value, child){
            return pages[value];
          }
          ),
        drawer: AppDrawer(index: pageIndex,),
        ),
      );
  }
}

class AppDrawer extends StatelessWidget {

  AppDrawer({super.key, required this.index});

  ValueNotifier<int> index ;

  @override 
  Widget build(BuildContext context){
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text('This is the drawer'),
          ),
          ListTile(
            title: const Text("Home"),
            onTap: () {
              
              index.value = 0;
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Downloads"),
            onTap: () {
              // Navigator.push(
              //   context, 
              //   MaterialPageRoute(
              //     builder: (context) => const DownloadsPage()
              //     )
              //   );
              index.value = 1;
              Navigator.pop(context);

            },
          ),
          ListTile(
            title: const Text("Bookmarks"),
            onTap: () {
              
              index.value = 2;
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("History"),
            onTap: () {
              index.value = 3;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class MediaSearchBar extends StatefulWidget {
  const MediaSearchBar({super.key});

  @override
  State<MediaSearchBar> createState() => _MediaSearchBarState() ;
}

class _MediaSearchBarState extends State<MediaSearchBar> {
  
  Widget build(BuildContext context){
    return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0),
                ),
                onTap: () {
                  controller.openView();
                },
                onChanged: (_) {
                  controller.openView();
                },
                leading: const Icon(Icons.search),
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
                  return List<ListTile>.generate(5, (int index) {
                    final String item = 'item $index';
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        setState(() {
                          controller.closeView(item);
                        });
                      },
                    );
                  });
                },
          ),
        );
  }
}