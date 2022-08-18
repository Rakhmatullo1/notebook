import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:temirdaftar/screens/splash_screen.dart';

class QarzDetails extends StatefulWidget {
  static const routeName = '/qarz-details';

  const QarzDetails({Key? key}) : super(key: key);

  @override
  State<QarzDetails> createState() => _QarzDetailsState();
}

class _QarzDetailsState extends State<QarzDetails> {
  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Tarixi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('qarzdorlar')
            .doc(id)
            .collection(
              'qarzMiqdori',
            )
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snap.hasData) {
            final qarzData = snap.data!.docs;
            return ListView.builder(
              itemCount: qarzData.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text('O\'chirishni xohlaysizmi?'),
                              actions: [
                                TextButton(
                                    onPressed: (() {
                                      Navigator.of(context).pop();
                                    }),
                                    child: const Text('Yo\'q')),
                                TextButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('qarzdorlar')
                                          .doc(id)
                                          .collection('qarzMiqdori')
                                          .doc(qarzData[i].id)
                                          .delete().then((value) => Navigator.of(context).pop());
                                    },
                                    child: const Text('Ha'))
                              ],
                            ));
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    // height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 0.5, color: Theme.of(context).backgroundColor),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        '${qarzData[i]['amount']} so\'m',
                        style: const TextStyle(fontSize: 20),
                      ),
                      subtitle: Text(DateFormat.yMMMd()
                          .format(DateTime.parse(qarzData[i]['createdAt']))),
                      trailing: qarzData[i]['type']
                          ? Text(
                              'Qarz Qo\'shildi',
                              style: TextStyle(
                                  color: Theme.of(context).errorColor,
                                  fontSize: 16),
                            )
                          : Text(
                              'Berildi',
                              style: TextStyle(
                                  color: Theme.of(context).backgroundColor,
                                  fontSize: 16),
                            ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
