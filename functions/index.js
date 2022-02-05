const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// // Below cod is to update post no of days at "59 23 * * *"

// // eslint-disable-next-line max-len
// eslint-disable-next-line max-len
// exports.updatePNDPaidStatus = functions.pubsub.schedule("59 23 * * *").onRun((context) => {
//   const ref = db.collection("userSubDetails");
//   ref.get().then((snapshot) => {
//     snapshot.forEach((doc) => {
//       // eslint-disable-next-line no-undef
//       // eslint-disable-next-line new-cap
//       const paidStatus = doc.data().paidStatus;
//       const userRenewedAt = doc.data().renewedAt.toDate();
//       const userRenewedDate = Date.parse(userRenewedAt);
//       // eslint-disable-next-line max-len
//       console.log("RenewedDate", doc.data().userId + "-" + userRenewedDate);
//       console.log("paidStatus", doc.data().userId + "-" + paidStatus);
//       // eslint-disable-next-line no-undef
//       const currentDate = Date.now();
//       console.log("currentDate", doc.data().userId + "-" + currentDate);

// eslint-disable-next-line max-len
//       const oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
//       // eslint-disable-next-line max-len
// eslint-disable-next-line max-len
//       const diffDays = Math.round(Math.abs((userRenewedDate - currentDate) / oneDay));
// eslint-disable-next-line max-len
//       console.log("Difference in Days", doc.data().prodName + "-" + diffDays);
//       // // time difference
//       // const timeDiff =
//       // Math.abs(prodDate7 - currentDate);

//       // days difference
//       // const diffDayss = Math.ceil(timeDiff / (1000 * 3600 * 24));
//       // const noOfDays = currentDate.difference(prodDateLocal).inDays;

//       // console.log("timeDiff", doc.data().prodName + "-" + timeDiff);
//       // console.log("diffDayss 13m", doc.data().prodName + "-" + diffDayss);
//       try {
//         ref
//             .doc(doc.id)
//             // eslint-disable-next-line no-undef
//             .update({"postNoOfDays": diffDays});
//         console.log("Cloud Function no of days update success");
//       } catch (err) {
//         return console.log("Error Cloud Function no of days update", err);
//       }
//       // eslint-disable-next-line max-len
//       if (diffDays > doc.data().planValidDays) {
//         try {
//           ref
//               .doc(doc.id)
//           // eslint-disable-next-line no-undef
//               .update({"paidStatus": "Unpaid"});
//           console.log("Cloud Function paidStatus update success");
//         } catch (err) {
//           return console.log("Error Cloud Function paidStatus update", err);
//         }
//         try {
//           db.collection("products")
//               .where("userDetailDocId", "==", doc.id)
//               .onSnapshot((querySnapshot) => {
//                 querySnapshot
//                     .forEach((queryDoc) => {
//                       try {
//                         db.collection("products").doc(queryDoc.id)
//                             .update({"subscription": "Unpaid"});
//                         // eslint-disable-next-line max-len
// eslint-disable-next-line max-len
//                         console.log("Cloud Function listingStatus update success");
//                       } catch (err) {
//                         // eslint-disable-next-line max-len
// eslint-disable-next-line max-len
//                         return console.log("Error Cloud Function listingStatus update", err);
//                       }
//                     });
//               });
//         } catch (err) {
//           // eslint-disable-next-line max-len
// eslint-disable-next-line max-len
//           return console.log("Error Cloud Function listingStatus product read", err);
//         }
//         // try {
//         //   ref
//         //       .doc(doc.id)
//         //   // eslint-disable-next-line no-undef
//         //       .update({"status": "Pending"});
//         //   console.log("Cloud Function status update success");
//         // } catch (err) {
//         //   return console.log("Error Cloud Function status update", err);
//         // }
//       }
//     });
//   }).catch((reason) => {
// eslint-disable-next-line max-len
//     console.log("db.collection(\"products\").get gets err, reason: " + reason);
//   });
// });

// // Below code is for chat notification

exports.sendNotification = functions.firestore
    .document("chats/{message}").onCreate((snapshot, context) => {
      const userId = snapshot.data().userIdTo;
      const title = snapshot.data().userNameFrom;
      const message = snapshot.data().text;

      console.log("We have a notification to send to", userId);

      const ref = db.collection("userDeviceToken").doc(userId);
      try {
        ref.get().then((tokenSnapshot) => {
          if (!tokenSnapshot.exists) {
            return console.log("Token not available!");
          } else {
            console.log("Token Document data:", tokenSnapshot.data());

            const token = tokenSnapshot.data().deviceToken;

            const payload = {
              notification: {
                title: title,
                body: message,
                sound: "default",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            };

            try {
              const response = admin.messaging().sendToDevice(token, payload);
              return console.log("Notification sent : Success", response);
            } catch (err) {
              return console.log("Error sending Notification : Failed", err);
            }
          }
        });
      } catch (err) {
        console.log("Error getting document", err);
      }
    });

// // notification for product create to specific user

// exports.prodCreateNotification = functions.firestore
//     .document("products/{message}").onCreate((snapshot, context) => {
//       const userId = snapshot.data().userDetailDocId;
//       const title = snapshot.data().prodName;
//       const message = "Product Created Sussfully!";

//       console.log("We have a notification to send to", userId);

//       const ref = db.collection("userDeviceToken").doc(userId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// // // notification for product create to admin user

// exports.prodCreateAdminNotification = functions.firestore
//     .document("products/{message}").onCreate((snapshot, context) => {
//       // const userId = snapshot.data().userDetailDocId;
//       const title = snapshot.data().prodName;
//       const message = "Product Created Sussfully!";

//       console.log("We have a notification to send to Admin");

//       const ref = db.collection("userDeviceToken")
//           .where("userLevel", "==", "Admin");
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (tokenSnapshot.empty) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data exist:");

//             const tokens =[];

//             // for (const token of tokenSnapshot) {
//             //   tokens.push(token.data().deviceToken);
//             // }

//             tokenSnapshot.forEach((doc) => {
//               tokens.push(doc.data().deviceToken);
//               console.log("Admin Token:", doc.data().deviceToken);
//             });


//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(tokens, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });


// // // notification for product update to admin user

// exports.prodUpdateAdminNotification = functions.firestore
//     .document("products/{message}").onUpdate((change, context) => {
//       // const userId = snapshot.data().userDetailDocId;
//       const title = change.after.data().prodName;
//       const newStatus = change.after.data().status;
//       const oldStatus = change.before.data().status;
//       const newListingStatus = change.after.data().listingStatus;
//       const oldListingStatus = change.before.data().listingStatus;
//       let message = "";
//       message = "Product Updated Sussfully!";
//       if (newStatus != oldStatus) {
//         message = "Product Status Updated :" + newStatus;
//       }
//       if (newListingStatus != oldListingStatus) {
//         message = "Product Listing Status Updated :" + newListingStatus;
//       }
//       console.log("message ", message);
//       console.log("We have a notification to send to Admin");

//       const ref = db.collection("userDeviceToken")
//           .where("userLevel", "==", "Admin");
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (tokenSnapshot.empty) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data exist:");

//             const tokens =[];

//             // for (const token of tokenSnapshot) {
//             //   tokens.push(token.data().deviceToken);
//             // }

//             tokenSnapshot.forEach((doc) => {
//               tokens.push(doc.data().deviceToken);
//               console.log("Admin Token:", doc.data().deviceToken);
//             });


//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(tokens, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// // // notification for product update to specific user

// exports.prodUpdateNotification = functions.firestore
//     .document("products/{message}").onUpdate((change, context) => {
//       const userId = change.after.data().userDetailDocId;
//       const title = change.after.data().prodName;
//       const newStatus = change.after.data().status;
//       const oldStatus = change.before.data().status;
//       const newListingStatus = change.after.data().listingStatus;
//       const oldListingStatus = change.before.data().listingStatus;
//       let message = "";
//       message = "Product Updated Sussfully!";
//       if (newStatus != oldStatus) {
//         message = "Product Status Updated :" + newStatus;
//       }
//       if (newListingStatus != oldListingStatus) {
//         message = "Product Listing Status Updated :" + newListingStatus;
//       }
//       console.log("message ", message);

//       console.log("We have a notification to send to", userId);

//       const ref = db.collection("userDeviceToken").doc(userId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// // // notification for product delete to specific user

// exports.prodDeleteNotification = functions.firestore
//     .document("products/{message}").onDelete((snapshot, context) => {
//       const userId = snapshot.data().userDetailDocId;
//       const title = snapshot.data().prodName;

//       let message = "";
//       message = "Product Deleted Sussfully!";

//       console.log("message ", message);

//       console.log("We have a notification to send to", userId);

//       const ref = db.collection("userDeviceToken").doc(userId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// // notification for product update to admin user

// exports.prodDeleteAdminNotification = functions.firestore
//     .document("products/{message}").onDelete((snapshot, context) => {
//       // const userId = snapshot.data().userDetailDocId;
//       const title = snapshot.data().prodName;

//       let message = "";
//       message = "Product Deleted Sussfully!";

//       console.log("message ", message);
//       console.log("We have a notification to send to Admin");

//       const ref = db.collection("userDeviceToken")
//           .where("userLevel", "==", "Admin");
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (tokenSnapshot.empty) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data exist:");

//             const tokens =[];

//             // for (const token of tokenSnapshot) {
//             //   tokens.push(token.data().deviceToken);
//             // }

//             tokenSnapshot.forEach((doc) => {
//               tokens.push(doc.data().deviceToken);
//               console.log("Admin Token:", doc.data().deviceToken);
//             });


//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
// sendToDevice(tokens, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// *Following code for productOrder //
// // notification for productOrder create to specific user

// exports.prodOrderCreateNotification = functions.firestore
//     .document("productOrders/{message}").onCreate((snapshot, context) => {
//       const buyerUserId = snapshot.data().buyerUserId;
//       const title = snapshot.data().productName;
//       const message = "Product Order Created Sussfully!";

//       console.log("We have a notification to send to", buyerUserId);

//       const ref = db.collection("userDeviceToken").doc(buyerUserId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
//                   sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });

// notification for productOrder create to specific seller user

// exports.prodOrderCreateNotificationS = functions.firestore
//     .document("productOrders/{message}").onCreate((snapshot, context) => {
//       const sellerUserId = snapshot.data().sellerUserId;
//       const title = snapshot.data().productName;
//       const message = "Product Order Created Sussfully!";

//       console.log("We have a notification to send to", sellerUserId);

//       const ref = db.collection("userDeviceToken").doc(sellerUserId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
//               const response = admin.messaging().
//                   sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });


// // notification for productOrder update to specific user

// exports.prodOrderUpdateNotification = functions.firestore
//     .document("productOrders/{message}").onUpdate((change, context) => {
//       const userId = change.after.data().buyerUserId;
//       const title = change.after.data().productName;
//       const newStatus = change.after.data().orderStatus;
//       const oldStatus = change.before.data().orderStatus;
//       let message = "";
//       message = "ProductOrder Updated Sussfully!";
//       if (newStatus != oldStatus) {
//         message = "ProductOrder Status Updated :" + newStatus;
//       }
//       console.log("message ", message);

//       console.log("We have a notification to send to", userId);

//       const ref = db.collection("userDeviceToken").doc(userId);
//       try {
//         ref.get().then((tokenSnapshot) => {
//           if (!tokenSnapshot.exists) {
//             return console.log("Token not available!");
//           } else {
//             console.log("Token Document data:", tokenSnapshot.data());

//             const token = tokenSnapshot.data().deviceToken;

//             const payload = {
//               notification: {
//                 title: title,
//                 body: message,
//                 sound: "default",
//                 clickAction: "FLUTTER_NOTIFICATION_CLICK",
//               },
//             };

//             try {
// eslint-disable-next-line max-len
//               const response = admin.messaging().sendToDevice(token, payload);
//               return console.log("Notification sent : Success", response);
//             } catch (err) {
//               return console.log("Error sending Notification : Failed", err);
//             }
//           }
//         });
//       } catch (err) {
//         console.log("Error getting document", err);
//       }
//     });


