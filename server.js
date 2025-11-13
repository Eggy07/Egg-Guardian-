const admin = require("firebase-admin");
const { Gpio } = require("onoff");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const ledPins = [17, 18, 27, 22, 23, 24];
const leds = ledPins.map(pin => new Gpio(pin, 'out'));

const docRef = db.collection('led_control').doc('status');

docRef.onSnapshot((doc) => {
  if (!doc.exists) {
    console.log("No LED document found.");
    return;
  }

  const data = doc.data();
  const ledStates = data.leds || [];
  const allOn = data.allOn;

  console.log("Updating LEDs:", ledStates, "All On:", allOn);

  ledStates.forEach((state, i) => {
    if (leds[i]) leds[i].writeSync(state ? 1 : 0);
  });

  console.log("LEDs updated successfully.");
});

process.on('SIGINT', () => {
  leds.forEach(led => led.writeSync(0));
  leds.forEach(led => led.unexport());
  console.log("\nLEDs turned off. GPIO released.");
  process.exit();
});
