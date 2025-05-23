importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
  authDomain: "prairiepatrol.firebaseapp.com",
  databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
  projectId: "prairiepatrol",
  storageBucket: "prairiepatrol.appspot.com",
  messagingSenderId: "731242768427",
  appId: "1:731242768427:web:e889405409dda52edca26e",
  measurementId: "G-F01VBL8JS0"
});

const messaging = firebase.messaging();

// Request notification permission
messaging.requestPermission()
  .then(() => {
    console.log("Notification permission granted.");
    return messaging.getToken();
  })
  .then((token) => {
    console.log("FCM Token:", token);
    // Send the token to your backend to save and use for push notifications
  })
  .catch((err) => {
    console.error("Notification permission denied or error:", err);
  });

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/appstore.png',
    badge: '/icons/appstore.png',
    vibrate: [200, 100, 200],
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', function(event) {
  console.log('Notification click received:', event);

  event.notification.close();

  // This looks to see if the current is already open and focuses if it is
  event.waitUntil(
    clients.matchAll({
      type: "window"
    })
    .then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url == '/' && 'focus' in client)
          return client.focus();
      }
      if (clients.openWindow)
        return clients.openWindow('/');
    })
  );
});

// Handle service worker installation
self.addEventListener('install', function(event) {
  console.log('Service Worker installed');
  self.skipWaiting();
});

// Handle service worker activation
self.addEventListener('activate', function(event) {
  console.log('Service Worker activated');
  event.waitUntil(clients.claim());
}); 