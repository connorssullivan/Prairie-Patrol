import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:flutter/painting.dart';

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
        String dogRfid = dogsData[randomDogKey]['rfid'] ?? '';

        // Check if the dog is in the target list
        DataSnapshot targetSnapshot = await dbRef.child('selectedDog/listRfid').get();
        bool isTargetDog = false;
        
        if (targetSnapshot.exists && targetSnapshot.value != null) {
          if (targetSnapshot.value is List) {
            List list = targetSnapshot.value as List;
            isTargetDog = list.contains(dogRfid);
          } else if (targetSnapshot.value is Map) {
            Map map = targetSnapshot.value as Map;
            isTargetDog = map.values.contains(dogRfid);
          }
        }

        if (isTargetDog) {
          // Get current year and month
          DateTime now = DateTime.now();
          String year = now.year.toString();
          String month = now.month.toString();

          // Reference for trapping count
          DatabaseReference trapCountRef = dbRef.child('trapCounts/$year/$month/$randomDogKey');

          // Get the current count, initialize if not present
          DataSnapshot trapSnapshot = await trapCountRef.get();
          int trapCount = trapSnapshot.exists ? trapSnapshot.value as int : 0;

          // Increment the count
          await trapCountRef.set(trapCount + 1);

          // Update the selected dog's inTrap status
          await dbRef.child('dogs/$randomDogKey').update({'inTrap': true});
          // Set caughtDog to the RFID of the trapped dog
          await dbRef.child('caughtDog').set(dogRfid);
          await createNotification('Dog Trapped', '${dogsData[randomDogKey]['name']} has been trapped successfully!');
          print('${dogsData[randomDogKey]['name']} has been trapped successfully!');
        } else {
          // Send notification that dog was scanned but not trapped
          await createNotification('Dog Scanned', '${dogsData[randomDogKey]['name']} was scanned but not trapped (not a target dog)');
          print('${dogsData[randomDogKey]['name']} was scanned but not trapped (not a target dog)');
        }
      }
    } catch (e) {
      print('Error trapping dog: $e');
    }
  }

  // Function to release the dog from the trap
  Future<void> releaseDog(String dogName) async {
    try {
      // First find the dog by name
      DataSnapshot snapshot = await dbRef.child('dogs').get();
      if (snapshot.exists) {
        final dogsData = Map<String, dynamic>.from(snapshot.value as Map);
        String? dogId;
        
        // Find the dog ID by name
        dogsData.forEach((key, value) {
          if (value['name'] == dogName) {
            dogId = key;
          }
        });

        if (dogId != null) {
          await dbRef.child('dogs/$dogId').update({'inTrap': false});
          print('$dogName released successfully!');
        } else {
          print('Dog with name $dogName not found');
        }
      }
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

  Future<void> deleteNotification(String id) async {
    try {
      await dbRef.child('notifications/$id').remove();  // Remove the notification from Firebase
      print('Notification with ID $id deleted.');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await dbRef.child('notifications').remove();  // Remove all notifications from Firebase
      print('All notifications deleted.');
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  Future<int?> getBatteryLife() async {
    try {
      DataSnapshot snapshot = await dbRef.child('Config/BatteryLife').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as int?; // Return battery life as an integer (percentage)
      }
      return null; // Return null if no battery data exists
    } catch (e) {
      print('Error fetching battery life: $e');
      return null; // Return null in case of an error
    }
  }

  Future<void> addNewDog(String rfid, String name, int age, Color color) async {
    try {
      // Create a new dog entry in the database
      await dbRef.child('dogs').push().set({
        'rfid': rfid,
        'name': name,
        'age': age,
        'inTrap': false,
        'lastCheckup': '',
        'lastCaught': '',
        'healthStatus': '',
        'color': '0x${color.value.toRadixString(16).padLeft(8, '0')}', // Store color as hex string with 0x prefix
      });
      print('New dog added successfully with RFID: $rfid');
    } catch (e) {
      print('Error adding new dog: $e');
      throw e;
    }
  }

  Future<void> deleteDog(String dogId) async {
    try {
      await dbRef.child('dogs/$dogId').remove();
      print('Dog with ID $dogId deleted successfully');
    } catch (e) {
      print('Error deleting dog: $e');
      throw e;
    }
  }

  Future<void> appendRfidToList(String rfid) async {
    try {
      final listRef = dbRef.child('selectedDog/listRfid');
      final snapshot = await listRef.get();

      int nextIndex = 0;

      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is List) {
          List list = snapshot.value as List;
          // Skip over null holes
          nextIndex = list.length;
          for (int i = 0; i < list.length; i++) {
            if (list[i] == null) {
              nextIndex = i;
              break;
            }
          }
        } else if (snapshot.value is Map) {
          Map map = snapshot.value as Map;
          nextIndex = map.length;
        }
      }

      await listRef.child(nextIndex.toString()).set(rfid);
      print('✅ RFID "$rfid" added at index $nextIndex');
    } catch (e) {
      print('❌ Error in appendRfidToList: $e');
    }
  }


  Future<void> removeRfidFromList(String rfid) async {
    try {
      final listRef = dbRef.child('selectedDog/listRfid');
      final snapshot = await listRef.get();

      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is List) {
          List list = snapshot.value as List;
          for (int i = 0; i < list.length; i++) {
            if (list[i] == rfid) {
              await listRef.child(i.toString()).remove();
              print('🗑 Removed RFID "$rfid" from index $i');
              return;
            }
          }
        } else if (snapshot.value is Map) {
          Map map = snapshot.value as Map;
          for (var entry in map.entries) {
            if (entry.value == rfid) {
              await listRef.child(entry.key.toString()).remove();
              print('🗑 Removed RFID "$rfid" from key ${entry.key}');
              return;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error in removeRfidFromList: $e');
    }
  }

  Future<List<String>> getSelectedRfids() async {
    try {
      final listRef = dbRef.child('selectedDog/listRfid');
      final snapshot = await listRef.get();

      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is List) {
          List list = snapshot.value as List;
          return list.where((item) => item != null).map((item) => item.toString()).toList();
        } else if (snapshot.value is Map) {
          Map map = snapshot.value as Map;
          return map.values.where((item) => item != null).map((item) => item.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error in getSelectedRfids: $e');
      return [];
    }
  }

}
