importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: 'AIzaSyCedUwZjWznB0m81_nf9IY0CREOIQSNYIc',
    appId: '1:1018512304007:web:b3d446df1b1499f56b5522',
    messagingSenderId: '1018512304007',
    projectId: 'remindra-bc8e5',
    authDomain: 'remindra-bc8e5.firebaseapp.com',
    databaseURL: 'https://remindra-bc8e5.firebaseio.com',
    storageBucket: 'remindra-bc8e5.appspot.com',
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
    console.log("onBackgroundMessage", message);
});