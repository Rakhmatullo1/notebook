import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temirdaftar/screens/new_qarz.dart';
import 'package:temirdaftar/screens/qarz_details.dart';

import 'package:temirdaftar/widgets/qarz_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class JustMap {
  String? name;
  String? id;
  JustMap(
    this.name,
    this.id,
  );
}

class _MainScreenState extends State<MainScreen> {
  var isOffline = true;
  StreamSubscription? connection;
  Future<void> aa() async {
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
      });
    } else {
      setState(() {
        isOffline = false;
      });
    }
  }

  @override
  void initState() {
    connection = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          isOffline = true;
        });
      } else {
        setState(() {
          isOffline = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    connection!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: isOffline
            ? null
            : FirebaseFirestore.instance
                .collection('qarzdorlar')
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.docs;

            List<JustMap> items = [];
            for (int i = 0; i < data.length; i++) {
              items.add(JustMap(
                data[i]['name'],
                data[i].id,
              ));
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('Temir Daftar'),
                actions: [
                  IconButton(
                      onPressed: isOffline
                          ? () {}
                          : () {
                              Navigator.of(context)
                                  .pushNamed(NewQarz.routeName, arguments: '');
                            },
                      icon: const Icon(Icons.add)),
                  IconButton(
                      onPressed: () {
                        showSearch(
                            context: context,
                            delegate: CustomSearchDelegate(items));
                      },
                      icon: const Icon(Icons.search)),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: aa,
                  )
                ],
              ),
              body: isOffline
                  ? const Center(
                      child: Text('No data'),
                    )
                  : const QarzWidget(),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('TemirDaftar'),
            ),
            body: const Center(
              child: Text('Host is unavailable'),
            ),
          );
        });
  }
}

class CustomSearchDelegate extends SearchDelegate {
  List<JustMap> items;
  CustomSearchDelegate(this.items);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // print(items![]);

    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    List<JustMap> matchQuery = [];
    for (int i = 0; i < items.length; i++) {
      if (items[i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(JustMap(items[i].name!, items[i].id));
      }
    }
    return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(matchQuery[i].name!),
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<JustMap> matchQuery = [];
    for (int i = 0; i < items.length; i++) {
      if (items[i].name!.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(JustMap(items[i].name!, items[i].id));
      }
    }
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('qarzdorlar').snapshots(),
        builder: (context, snap) {
          if (snap.hasData) {
            final qarzDocs = snap.data!.docs;

            return ListView.builder(
                itemCount: matchQuery.length,
                itemBuilder: (context, i) {
                  return Dismissible(
                    key: Key(matchQuery[i].id!),
                    background:
                        Container(color: Theme.of(context).backgroundColor),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      await Navigator.of(context).pushNamed(
                          QarzDetails.routeName,
                          arguments: matchQuery[i].id);
                      return false;
                    },
                    child: GestureDetector(
                      onTap: (() {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(qarzDocs[i]['name']),
                            content: qarzDocs[i]['description'] == ''
                                ? const Text('Ma\'lumot yo\'q')
                                : Text('${qarzDocs[i]['description']} '),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK')),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      NewQarz.routeName,
                                      arguments: qarzDocs[i].id);
                                },
                                child: const Text('O\'zgartirish'),
                              ),
                            ],
                          ),
                        );
                      }),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 1, color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15)),
                        child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('qarzdorlar')
                                .doc(matchQuery[i].id)
                                .collection('qarzMiqdori')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final data = snapshot.data!.docs;
                                double amount = 0;
                                for (int i = 0; i < data.length; i++) {
                                  amount =
                                      amount + double.parse(data[i]['amount']);
                                }
                                final money=amount.ceil().toString();
                                return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(matchQuery[i].name!),
                                      Text('${money.spaceSeparateNumbers()} so\'m')
                                    ]);
                              }
                              return const Text('loading...');
                            }),
                      ),
                    ),
                  );
                });
          }
          return Container();
        });
  }
}
