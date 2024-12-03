import 'dart:math';

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

  // Put dog in trap
  Future<void> trapRandomDog() async {
    try {
      // Fetch all dogs from the collection
      QuerySnapshot querySnapshot = await dogsCollection.get();
      List<DocumentSnapshot> dogs = querySnapshot.docs;

      // Check if there are any dogs
      if (dogs.isEmpty) {
        print('No dogs available to trap.');
        return;
      }

      // Select a random dog from the list
      Random random = Random();
      DocumentSnapshot selectedDog = dogs[random.nextInt(dogs.length)];

      // Update the selected dog's inTrap status
      await dogsCollection.doc(selectedDog.id).update({'inTrap': true});
      print('${selectedDog['name']} has been trapped successfully!');
    } catch (e) {
      print('Error trapping dog: $e');
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
          'id': doc['id'],
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

  Future<Map<String, dynamic>?> getDogStatsById(String dogId) async {
    try {
      DocumentSnapshot doc = await dogsCollection.doc(dogId).get();
      return doc.data() as Map<String, dynamic>?; // Return dog stats or null if not found
    } catch (e) {
      print('Error fetching dog stats: $e');
      return null; // Return null in case of error
    }
  }
}
