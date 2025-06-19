import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createCarrier(String carrier) async {
  await FirebaseFirestore.instance.collection("Data").doc("Carriers").update({
    "carriers": FieldValue.arrayUnion([carrier]),
  });
}
