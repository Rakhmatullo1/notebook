import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NewQarz extends StatefulWidget {
  static const routeName = '/new-qarz';
  String id;
  NewQarz(this.id, {Key? key}) : super(key: key);

  @override
  State<NewQarz> createState() => _NewQarzState();
}

class _NewQarzState extends State<NewQarz> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final _key = GlobalKey<FormState>();
  final amount = FocusNode();
  final description = FocusNode();
  var _init = true;
  bool? type;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    amountController.dispose();
    amount.dispose();
    description.dispose();
  }

  @override
  void didChangeDependencies() {
    _init = widget.id.isNotEmpty;
    if (_init) {
      final qarzList = FirebaseFirestore.instance
          .collection('qarzdorlar')
          .doc(widget.id)
          .get();
      qarzList.then((value) {
        final data = value.data();
        setState(() {
          nameController.text = data!['name'];
          descriptionController.text = data['description'];
        });
      });
    }
    super.didChangeDependencies();
  }

  void saveQarz() async {
    if (!_key.currentState!.validate()) {
      return;
    }
    if (_init) {
      await FirebaseFirestore.instance
          .collection('qarzdorlar')
          .doc(widget.id)
          .update({
        'name': nameController.text.trim(),
        'description': descriptionController.text,
      }).then((value) async {
        await FirebaseFirestore.instance.collection('qarzdorlar').doc(widget.id).collection('qarzMiqdori').add({
          'type': type,
          'amount': amountController.text,
          'createdAt': DateTime.now().toIso8601String(),
        }).then((value) => Navigator.of(context).pop());
      });
    }
    if (!_init) {
      await FirebaseFirestore.instance.collection('qarzdorlar').add({
        'name': nameController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'description': descriptionController.text,
      }).then((value) async {
        await FirebaseFirestore.instance
            .collection('qarzdorlar')
            .doc(value.id)
            .collection('qarzMiqdori')
            .add({
          'amount': amountController.text,
          'createdAt': DateTime.now().toIso8601String(),
          'type': true,
        });
      }).catchError((e) {
        print(e);
        final snackBar = SnackBar(content: Text('yangi Qarzdor qo\'shilmadi'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }).then((value) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _init
            ? const Text('Qarzni O\'zgartirish')
            : const Text('Yangi Qarz qo\'shish'),
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Form(
              key: _key,
              child: Column(
                children: [
                  TextFormField(
                    validator: ((value) {
                      if (value!.isEmpty) {
                        return 'Please fill form';
                      }
                      return null;
                    }),
                    decoration: InputDecoration(
                        label: Text(_init ? '' : 'Ism Familiya')),
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(amount);
                    },
                  ),
                  TextFormField(
                    focusNode: amount,
                    validator: ((value) {
                      if (value!.isEmpty) {
                        return 'Please fill form';
                      }
                      return null;
                    }),
                    controller: amountController,
                    decoration:
                        const InputDecoration(label: Text('Qarz miqdori')),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(description);
                    },
                  ),
                  if (_init)
                    Row(
                      children: [
                        Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<bool>(
                                value: false,
                                groupValue: type,
                                onChanged: (value) {
                                  setState(() {
                                    type = value!;
                                  });
                                }),
                            const Text(
                              'Ayirish',
                              style: TextStyle(fontSize: 20),
                            )
                          ],
                        )),
                        Spacer(),
                        Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: type,
                              onChanged: (value) {
                                setState(() {
                                  type = value!;
                                });
                              },
                            ),
                            const Text(
                              'Qo\'shish',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        )),
                      ],
                    ),
                  TextFormField(
                    focusNode: description,
                    decoration: InputDecoration(
                        label: Text(_init ? '' : 'Batafsil Ma\'lumot')),
                    controller: descriptionController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: saveQarz,
                child: const Text(
                  'Saqlash',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
