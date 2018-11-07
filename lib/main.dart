import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
  runApp(new MyApp());
}

final dummySnapshot = [
  {"name": "Filip", "votes": 15},
  {"name": "Abraham", "votes": 14},
  {"name": "Richard", "votes": 11},
  {"name": "Ike", "votes": 10},
  {"name": "Justin", "votes": 1},
];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
    return MaterialApp(
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Baby Name Votes')),
      body: _buildBody(context),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('baby')
          .orderBy('votes', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.votes.toString()),
          onTap: () => Firestore.instance.runTransaction((transaction) async {
                final freshSnapshot = await transaction.get(record.reference);
                final fresh = Record.fromSnapshot(freshSnapshot);
                await transaction
                    .update(record.reference, {'votes': fresh.votes + 1});
              }),
        ),
      ),
    );
  }

  _addItem() async {
    final value = await showDialog(
        context: context,
        builder: (BuildContext context) {
          var babyNameText;
          return AlertDialog(
            title: const Text('Add New Baby Name'),
            content: TextField(
              decoration: InputDecoration(
                hintText: "Your little baby's name",
              ),
              onChanged: (text) => babyNameText = text,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  Navigator.of(context).pop(babyNameText);
                },
              ),
            ],
          );
        });
    await _addBabyName(value);
  }

  _addBabyName(name) async {
    await Firestore.instance.collection('baby').add({'name': name, 'votes': 0});
  }
}

class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}
