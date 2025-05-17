import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from "firebase-admin/messaging";
import express from "express";
import cors from "cors";
import admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Setup dotenv to load environment variables from the parent directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '..', '.env') });

// Use credentials from environment variable
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
let serviceAccount;

try {
  // Check if the environment variable is set
  if (!serviceAccountPath) {
    throw new Error("GOOGLE_APPLICATION_CREDENTIALS environment variable is not set");
  }
  
  // Resolve the path relative to the current directory
  const resolvedPath = path.resolve(__dirname, serviceAccountPath);
  serviceAccount = require(resolvedPath);
  console.log("Loaded service account credentials successfully");
} catch (error) {
  console.error("Error loading service account credentials:", error.message);
  // Fallback to direct path as before
  serviceAccount = require("./monie-d2a2a-firebase-adminsdk-fbsvc-e4d150315c.json");
  console.log("Using fallback service account credentials");
}

const app = express();
app.use(express.json());

app.use(
  cors({
    origin: "*",
  })
);

app.use(
  cors({
    methods: ["GET", "POST", "DELETE", "UPDATE", "PUT", "PATCH"],
  })
);

app.use(function(req, res, next) {
  res.setHeader("Content-Type", "application/json");
  next();
});


initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'push-notify',
});

app.post("/send", function (req, res) {
  const receivedToken = req.body.fcmToken;
  
  const message = {
    notification: {
      title: "Push Notify",
      body: 'This is a Test Notification'
    },
    token: "cE14QGXlTyCSTNgqqFWEpA:APA91bFw0rPn6alKU4Uxj_QRtsFYsimdo8iwMrAYbHDYerzyWKxj_N1OR0K3dmxU1M0wZ1cxng7kRtSkmQEp0-dWKV4iuWpM_YO6UDUdZ9-jKabXDSYi7Vs",
    //token: receivedToken,
  };
  
  getMessaging()
    .send(message)
    .then((response) => {
      res.status(200).json({
        message: "Successfully sent message",
        token: receivedToken,
      });
      console.log("Successfully sent message:", response);
    })
    .catch((error) => {
      res.status(400);
      res.send(error);
      console.log("Error sending message:", error);
    });
  
  
});

app.listen(3000, function () {
  console.log("Server started on port 3000");
});