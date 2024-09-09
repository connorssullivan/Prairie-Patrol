import 'package:cloud_firestore/cloud_firestore.dart';

class DogsService {
  //Reference to the Dogs Collection
  final CollectionReference dogsCollection = FirebaseFirestore.instance.collection('dogs');

  Future<DocumentSnapshot?> checkDogsInTrap() async {
    try {
      DocumentSnapshot redDogDoc = await dogsCollection.doc('Red Dog').get();

      //Check if red dog is in the trap
      if (redDogDoc.exists && redDogDoc['inTrap']) {
        return redDogDoc;
      }

      DocumentSnapshot greenDogDoc = await dogsCollection.doc('Green Dog')
          .get();

      //Check if green dog dog is in the trap
      if (greenDogDoc.exists && greenDogDoc['inTrap']) {
        return greenDogDoc;
      }

      //If no dog in trap
      return null;
    }catch(e){
      print(e);
      return null;
    }
  }

  // Function to release the trapped dog (set 'inTrap' to false)
  Future<void> releaseDog(String dogId) async {
    try {
      await dogsCollection.doc(dogId).update({'inTrap': false});
      print('$dogId released successfully!');
    } catch (e) {
      print('Error releasing dog: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllDogStats() async {
    try {
      QuerySnapshot querySnapshot = await dogsCollection.get();
      return querySnapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'lastCheckup': doc['lastCheckup'], // Field from Firestore
          'lastCaught': doc['lastCaught'], // Field from Firestore
          'healthStatus': doc['healthStatus'], // Field from Firestore
          'age': doc['age'], // Field from Firestore
        };
      }).toList();
    } catch (e) {
      print('Error fetching dog stats: $e');
      throw e;
    }
  }
}
