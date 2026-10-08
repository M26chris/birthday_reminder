const functions = require("firebase-functions");
const firebase = require("firebase-admin");

const firestore = firebase.firestore();

/**
 * Main notification function – runs every hour.
 *
 * For each user with push notifications enabled:
 *   1. Computes their local hour from their stored UTC timezone offset.
 *   2. Finds birthdays whose notif_hour matches the user's current local hour.
 *   3. Sends a push notification if the birthday is TODAY or exactly 7 days away.
 *
 * NOTE: push notifications fire at the correct hour (whole-hour precision).
 *       Local (on-device) notifications respect the exact minute chosen by the user.
 */
module.exports.notificationsFunction = async function notificationsFunction() {
    const utcHour = new Date().getUTCHours();

    // Get all tokens that have notifications turned on
    const tokensSnapshot = await firestore
        .collection("fcm_tokens")
        .where("enable_notifications", "==", true)
        .get();

    const users = tokensSnapshot.docs.map(doc => ({
        token: doc.id,
        ...doc.data(),
    }));

    for (const user of users) {
        // Convert UTC hour to the user's local hour
        const timezone = user.timezone ?? 0; // stored as integer UTC offset
        const localHour = (utcHour + timezone + 24) % 24;

        // Fetch all birthdays belonging to this user
        const birthdaysSnapshot = await firestore
            .collection("birthdays")
            .where("owner", "==", user.user_id)
            .get();

        for (const doc of birthdaysSnapshot.docs) {
            const birthday = { id: doc.id, ...doc.data() };

            // Default notification hour is 9 AM if the birthday has no stored preference
            const notifHour = birthday.notif_hour ?? 9;

            // Only fire when the user's local hour matches this birthday's chosen hour
            if (localHour !== notifHour) continue;

            // Compute the local date for this user
            const offsetMs = timezone * 60 * 60 * 1000;
            const localNow = new Date(Date.now() + offsetMs);

            const bDate = birthday.birth.toDate();
            const bMonth = bDate.getMonth() + 1;
            const bDay = bDate.getDate();

            const todayMonth = localNow.getMonth() + 1;
            const todayDay = localNow.getDate();

            const in7Days = new Date(localNow.getTime() + 7 * 24 * 60 * 60 * 1000);
            const in7Month = in7Days.getMonth() + 1;
            const in7Day = in7Days.getDate();

            const isToday = todayDay === bDay && todayMonth === bMonth;
            const isSeven = in7Day === bDay && in7Month === bMonth;

            if (!isToday && !isSeven) continue;

            try {
                const authedUser = await firebase.auth().getUser(user.user_id);
                functions.logger.info(
                    `Sending notification to "${authedUser.displayName} <${authedUser.email}>". ` +
                    `Birthday: ${birthday.personName} (id: ${birthday.id})`,
                    { structuredData: true }
                );
                await sendNotification(birthday, user, isSeven && !isToday);
            } catch (err) {
                functions.logger.error(`Failed to send for ${birthday.personName}: ${err.message}`);
            }
        }
    }
};

/**
 * Build and dispatch the FCM push notification (English only).
 *
 * @param {object}  birthday  - Firestore birthday document data
 * @param {object}  user      - FCM token document data
 * @param {boolean} isFuture  - true = 7-day heads-up, false = birthday is today
 */
async function sendNotification(birthday, user, isFuture = false) {
    const name = birthday.personName;
    const noYear = !!birthday.noYear;
    const year = birthday.birth.toDate().getFullYear();
    const turnsAge = new Date().getFullYear() - year;

    let title;
    if (noYear) {
        title = isFuture
            ? `🎂 ${name}'s birthday is in 7 days!`
            : `🎂 Today is ${name}'s birthday!`;
    } else {
        title = isFuture
            ? `🎂 ${name} turns ${turnsAge} in 7 days!`
            : `🎂 Happy birthday ${name}! They turn ${turnsAge} today!`;
    }

    const dateStr = birthday.birth.toDate().toLocaleDateString("en", {
        day: "numeric",
        month: "long",
    });
    const body = (birthday.notes ? `(${birthday.notes}) ` : "") + dateStr;

    return firebase.messaging().send({
        token: user.token,
        notification: {
            title,
            body,
        },
        webpush: {
            fcmOptions: {
                link: `https://remindra-bc8e5.web.app/app/#/?birthday=${encodeURIComponent(birthday.id)}`,
            },
        },
        data: {
            birthday_id: birthday.id,
        },
    });
}
