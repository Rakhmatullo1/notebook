import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:temirdaftar/screens/new_qarz.dart';
import 'package:temirdaftar/screens/qarz_details.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

extension StringNumberExtension on String {
  String spaceSeparateNumbers() {
    final result = replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    return result;
  }
}

class QarzWidget extends StatefulWidget {
  const QarzWidget({Key? key}) : super(key: key);

  @override
  State<QarzWidget> createState() => _QarzWidgetState();
}

class _QarzWidgetState extends State<QarzWidget> {
  // @override
  // void dispose() {
  //   connection!.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('qarzdorlar')
            .orderBy(
              'name',
            )
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasData) {
            final qarzDocs = snap.data!.docs;
            return ListView.builder(
                itemCount: qarzDocs.length,
                itemBuilder: ((context, index) => Dismissible(
                      key: Key(qarzDocs[index].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: const Alignment(0.7, 0),
                        height: 80,
                        width: double.infinity,
                        color: Theme.of(context).backgroundColor,
                        child: const Text(
                          'Qarz Tarixi',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await Navigator.of(context).pushNamed(
                            QarzDetails.routeName,
                            arguments: qarzDocs[index].id);
                        return false;
                      },
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(qarzDocs[index]['name']),
                              content: qarzDocs[index]['description'] == ''
                                  ? const Text('Ma\'lumot yo\'q')
                                  : Text('${qarzDocs[index]['description']} '),
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
                                        arguments: qarzDocs[index].id);
                                  },
                                  child: const Text('O\'zgartirish'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('qarzdorlar')
                                .doc(qarzDocs[index].id)
                                .collection('qarzMiqdori')
                                .snapshots(),
                            builder: (context, snapshot) {
                              double amount = 0;
                              if (snapshot.hasData) {
                                final data = snapshot.data!.docs;
                                for (int i = 0; i < data.length; i++) {
                                  if (data[i]['type']) {
                                    amount = amount +
                                        double.parse(data[i]['amount']);
                                  }
                                  if (!data[i]['type']) {
                                    amount = amount -
                                        double.parse(data[i]['amount']);
                                  }
                                }
                                final money=amount.ceil().toString();

                                return Container(
                                  height: 80,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1.0,
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(qarzDocs[index]['name']),
                                            Text(DateFormat.yMMMd().format(
                                                DateTime.parse(qarzDocs[index]
                                                    ['createdAt']))),
                                          ],
                                        ),
                                        Text("${money.spaceSeparateNumbers()} so'm"),
                                        IconButton(
                                            onPressed: () async {
                                              return showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                            title: const Text(
                                                                'Parolni kiriting'),
                                                            content:
                                                                TextFormField(
                                                              obscureText: true,
                                                              onFieldSubmitted:
                                                                  (value) async {
                                                                if (value ==
                                                                    '123456') {
                                                                  try {
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'qarzdorlar')
                                                                        .doc(qarzDocs[index]
                                                                            .id)
                                                                        .delete();
                                                                  } catch (err) {
                                                                    print(
                                                                        '$err 1st');
                                                                  } finally {
                                                                    try {
                                                                      for (int i =
                                                                              0;
                                                                          i < data.length;
                                                                          i++) {
                                                                        await FirebaseFirestore
                                                                            .instance
                                                                            .collection('qarzdorlar')
                                                                            .doc(qarzDocs[index].id)
                                                                            .collection('qarzMiqdori')
                                                                            .doc(data[i].id)
                                                                            .delete();
                                                                      }
                                                                    } catch (err) {
                                                                      print(
                                                                          '$err 2nd');
                                                                    } finally {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    }
                                                                  }
                                                                } else {
                                                                  return;
                                                                }
                                                              },
                                                            ),
                                                          ));
                                            },
                                            icon: Icon(
                                              Icons.delete,
                                              color:
                                                  Theme.of(context).errorColor,
                                            ))
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const Center(child: Text('Loading . . .'));
                            }),
                      ),
                    )));
          }
          return const Center(
            child: Text('No data'),
          );
        });
  }
}
