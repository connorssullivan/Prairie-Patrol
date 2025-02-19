import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class RTDogsService {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // Function to check for dogs in the trap
  Future<Map<String, dynamic>?> checkDogsInTrap() async {
    try {
      DataSnapshot snapshot = await dbRef.child('dogs').get();
      if (snapshot.exists) {
        // Ensure that the snapshot value is a Map
        final Map<dynamic, dynamic> dogsData = snapshot.value as Map<dynamic, dynamic>;

        // Convert dynamic map to a Map<String, dynamic>
        Map<String, dynamic> dogsMap = dogsData.map((key, value) {
          return MapEntry(key.toString(), Map<String, dynamic>.from(value as Map));
        });

        // Check if any dog is in the trap
        for (var key in dogsMap.keys) {
          if (dogsMap[key]['inTrap'] == true) {
            return dogsMap[key]; // Return the dog that is in the trap
          }
        }
      }
      return null; // No dog in trap
    } catch (e) {
      print('Error checking dogs in trap: $e');
      return null;
    }
  }

  Future<int?> checkNotificationCount() async {
    try {
      DataSnapshot ds = await dbRef.child('notifications').get();
      // Loop through the notifications and return the size
      if( ds.exists && ds.value != null) {
        Map <dynamic, dynamic> notifications = ds.value as Map<dynamic,
            dynamic>;
        int count = notifications.length;
        return count;
      }else{
        return 0;
      }
    }catch (e){
      //print('Error checking notifications: $e');
      return 0;
    }
  }

  Future<Object?> getNotifications() async {
    try {
      DataSnapshot ds = await dbRef.child('notifications').get();
      if (ds.exists && ds.value != null) {
        return ds.value;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return null;
    }
  }
  // Function to trap a random dog
  Future<void> trapRandomDog() async {
    try {
      DataSnapshot snapshot = await dbRef.child('dogs').get();
      if (snapshot.exists) {
        final dogsData = Map<String, dynamic>.from(snapshot.value as Map);

        // Get list of available dogs
        List<String> dogKeys = dogsData.keys.toList();
        if (dogKeys.isEmpty) {
          print('No dogs available to trap.');
          return;
        }

        // Select a random dog
        Random random = Random();
        String randomDogKey = dogKeys[random.nextInt(dogKeys.length)];

        // Update the selected dog's inTrap status
        await dbRef.child('dogs/$randomDogKey').update({'inTrap': true});
        await createNotification('Dog Trapped', '${dogsData[randomDogKey]['name']} has been trapped successfully!');
        print('${dogsData[randomDogKey]['name']} has been trapped successfully!');
      }
    } catch (e) {
      print('Error trapping dog: $e');
    }
  }

  // Function to release the dog from the trap
  Future<void> releaseDog(String dogName) async {
    try {
      await dbRef.child('dogs/${dogName}Dog').update({'inTrap': false});
      print('$dogName released successfully!');
    } catch (e) {
      print('Error releasing dog: $e');
    }
  }

  // Function to get all dog stats
  Future<List<Map<String, dynamic>>> getAllDogStats() async {
    try {
      DataSnapshot snapshot = await dbRef.child('dogs').get();
      if (snapshot.exists) {
        final dogsData = Map<String, dynamic>.from(snapshot.value as Map);
        return dogsData.entries.map((entry) {
          return {
            'id': entry.key,
            'name': entry.value['name'],
            'lastCheckup': entry.value['lastCheckup'] ?? '',
            'lastCaught': entry.value['lastCaught'] ?? '',
            'healthStatus': entry.value['healthStatus'] ?? '',
            'age': entry.value['age'] ?? 0,
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching dog stats: $e');
      throw e;
    }
  }

  // Function to get dog stats by ID
  Future<Map<String, dynamic>?> getDogStatsById(String dogId) async {
    try {
      DataSnapshot snapshot = await dbRef.child('dogs/$dogId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null; // No dog found
    } catch (e) {
      print('Error fetching dog stats: $e');
      return null;
    }
  }

  Future<void> updateDogStats(String dogId, Map<String, dynamic> updatedStats) async {
    try {
      await dbRef.child('dogs/$dogId').update(updatedStats);
      print('Dog stats updated successfully for ID: $dogId');
    } catch (e) {
      print('Error updating dog stats: $e');
    }
  }

  Future<void> selectDog(String dog) async {
    try {
      // Get the RFID of the selected dog
      String dogRfid = await _getDogId(dog) ?? 'None';

      // Check if the dogRfid is valid (non-null)
      if (dogRfid != null && dogRfid.isNotEmpty) {
        // Update the selected dog's RFID in the Realtime Database
        await dbRef.child('selectedDog').update({'rfid': dogRfid});
        print('Dog selected with RFID: $dogRfid');
      } else {
        // If no valid RFID is found, update the Realtime Database with an empty string or a placeholder value
        await dbRef.child('selectedDog').update({'rfid': ''});
        print('No valid dog selected, updated with empty RFID.');
      }
    } catch (e) {
      print('Error selecting dog: $e');
    }
  }

  Future<String?> _getDogId(String color) async {
    try {
      // Fetch the data snapshot from Firebase
      DataSnapshot snapshot = await dbRef.child('dogs/${color}Dog/rfid').get();

      // Check if the snapshot exists
      if (snapshot.exists) {
        // Return the RFID as a String
        return snapshot.value as String?;
      } else {
        print('No dog found for color: $color');
        return 'None';  // Return null if no dog is found
      }
    } catch (e) {
      print('Error fetching dog RFID: $e');
      return null;  // Return null in case of an error
    }
  }

  Future<void> createNotification(String title, String message) async {
    try {
      // Reference to the notifications node
      DatabaseReference notificationRef = dbRef.child('notifications').push();

      // Write notification data
      await notificationRef.set({
        'title': title,
        'message': message,
        'timestamp': ServerValue.timestamp,
      });

      print('✅ Notification created: $title - $message');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

}
