# Prairie Patrol

**Prairie Patrol** is a Flutter-based mobile application designed to work in tandem with an Arduino and Google Firebase. 
The app facilitates smart, remote-controlled trapping of prairie dogs using RFID technology to identify animals and close the 
cage only when the desired dog is detected.

This project is built to assist zookeepers or wildlife researchers with precision and automation, ensuring humane and efficient trapping.

<br />

## Features
- **RFID Integration**: Detects animals with embedded RFID tags to identify specific prairie dogs in the trap.
- **Remote Control**: Communicates with an Arduino via Firebase to control the trap's door mechanism.
- **Real-Time Updates**: Displays live notifications and trap status on the app.
- **Dark and Light Themes**: Supports both themes for user preference.
- **Customizable Settings**: Easily configure the app for your environment.

<br />
<div>
  &emsp;&emsp;&emsp;
  <img src="ex1.jpeg" alt="Light Theme" width="330">
  &emsp;&emsp;&emsp;&emsp;
  <img src="ex2.jpeg" alt="Dark Theme" width="320">  
</div>
<br />

---

## First Run

After installing the package dependencies with:

```bash
flutter pub get
```

Run the code generation tool:

```bash
flutter pub run build_runner build
```

## Run Configurations

The project supports multiple build modes, along with environments for testing and production:

- **debug** - Development environment for debugging.
- **profile** - Optimized for profiling.
- **release** - Optimized for production.

To run the app in debug mode, use:
```bash
flutter run
```

Or set configurations in your IDE (e.g., Android Studio or VSCode).

---

## App Configuration

### Firebase
1. Set up a Firebase project.
2. Add `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) to the respective folders in your Flutter project.

### Arduino
1. Program the Arduino to read RFID tags and communicate with Firebase Realtime Database using code in arduinoRFID copy Folder.
2. Ensure the Arduino controls the servo motor for the cage mechanism.

---


### Key Components
1. **RFID Scanner**: Detects the animal in the cage.
2. **Firebase**: Acts as a bridge between the Arduino and the Flutter app, syncing data in real-time.
3. **Flutter App**: Displays trap status and allows remote control.

---

## Under the Hood

### Data Management
- **TasksRepository**: Handles communication with Firebase and local data cache.
- **ApiService**: Provides an abstraction for Firebase communication.



## Usage

This app is built for zookeepers or wildlife researchers looking for an automated solution to trap specific prairie dogs humanely and efficiently.


---

## Contributors

- **Connor Sullivan** (Project Leader)
- **Will Webber** (Software Developer)
- **Noah Webb** (Software Developer)
- **Ashley Gerbes** (Hardware Developer)
- **Jude Maggitti** (Hardware Developer)

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.