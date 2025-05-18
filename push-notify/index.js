import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from "firebase-admin/messaging";
import express from "express";
import cors from "cors";
import admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

// Setup dotenv to load environment variables from the parent directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '..', '.env') });

// First, let's try to load directly from the current directory
let serviceAccount;
let credentialPaths = [
  // Direct path in current directory
  path.join(__dirname, "push-notify-key.json"),
  // Path in parent directory
  path.join(__dirname, "..", "push-notify-key.json")
];

// If environment variable is set, add it to our paths to try
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  // Clean up the path to avoid duplication
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const normalizedPath = envPath.replace(/^\.\//, '').replace(/^push-notify\/push-notify/, 'push-notify');
  
  // Either resolve from current directory or from parent
  credentialPaths.unshift(path.resolve(normalizedPath));
  credentialPaths.unshift(path.join(__dirname, normalizedPath.replace(/^push-notify\//, '')));
}

// Try each path in order until we find one that works
let credentialFound = false;
for (const credPath of credentialPaths) {
  console.log(`Trying to load credentials from: ${credPath}`);
  try {
    if (fs.existsSync(credPath)) {
      serviceAccount = JSON.parse(fs.readFileSync(credPath, 'utf8'));
      console.log(`Successfully loaded credentials from: ${credPath}`);
      credentialFound = true;
      break;
    }
  } catch (error) {
    console.error(`Failed to load credentials from ${credPath}:`, error.message);
  }
}

// If we couldn't find any credentials, exit
if (!credentialFound) {
  console.error("ERROR: Could not find Firebase credentials in any location!");
  console.error("Please ensure push-notify-key.json exists in the correct location.");
  console.error("Tried the following paths:");
  credentialPaths.forEach(p => console.error(`- ${p}`));
  process.exit(1);
}

// Make sure serviceAccount is an object
if (typeof serviceAccount === 'string') {
  serviceAccount = JSON.parse(serviceAccount);
}

initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monie-d2a2a',
});

const app = express();
app.use(express.json());

// Fix CORS to be more permissive
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "DELETE", "PUT", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(function(req, res, next) {
  res.setHeader("Content-Type", "application/json");
  next();
});

// Store FCM tokens with their current app state and timestamp
const deviceStates = new Map();
// Track sent notifications to prevent duplicates
const sentNotifications = new Map();

// Add a root route handler
app.get('/', (req, res) => {
  res.status(200).json({ 
    status: 'OK',
    message: 'Monie Push Notification Server',
  });
});

// Add a health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running' });
});

// Add a simple test endpoint to manually trigger a notification
app.get('/test-notification', function(req, res) {
  try {
    const { token } = req.query;
    
    if (!token) {
      return res.status(400).json({ error: 'FCM token is required as a query parameter' });
    }
    
    console.log(`Received test notification request for token: ${token.substring(0, 10)}...`);
    
    // Send a test notification immediately
    const message = {
      notification: {
        title: 'Test Notification',
        body: 'This is a test notification from your server!',
      },
      data: {
        type: 'test_notification',
        timestamp: new Date().toISOString(),
        notificationId: Date.now().toString(),
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      },
      token: token,
    };
    
    getMessaging()
      .send(message)
      .then((response) => {
        console.log(`Successfully sent test notification:`, response);
        res.status(200).json({
          message: "Test notification sent successfully",
          messageId: response,
        });
      })
      .catch((error) => {
        console.error(`Error sending test notification:`, error);
        res.status(500).json({ error: error.message });
      });
  } catch (error) {
    console.error('Error processing test notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update token endpoint
app.post("/update-token", function (req, res) {
  try {
    const { fcmToken } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token is required' });
    }
    
    // Store token with default state of foreground and timestamp
    deviceStates.set(fcmToken, {
      state: 'foreground',
      timestamp: new Date().toISOString(),
      lastNotification: null
    });
    
    console.log(`Token updated: ${fcmToken}`);
    res.status(200).json({ message: 'Token updated successfully' });
  } catch (error) {
    console.error('Error updating token:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// App state change endpoint
app.post("/app-state-change", function (req, res) {
  try {
    const { fcmToken, appState } = req.body;
    
    console.log(`Received app state change request:`, { 
      fcmToken: fcmToken ? `${fcmToken.substring(0, 10)}...` : 'missing', 
      appState 
    });
    
    if (!fcmToken || !appState) {
      console.error('Missing required parameters:', { fcmToken: !!fcmToken, appState: !!appState });
      return res.status(400).json({ error: 'FCM token and app state are required' });
    }
    
    // Valid app states
    const validStates = ['foreground', 'background', 'terminated', 'hidden'];
    if (!validStates.includes(appState)) {
      console.error(`Invalid app state: ${appState}`);
      return res.status(400).json({ error: 'Invalid app state' });
    }
    
    const now = new Date();
    const deviceInfo = deviceStates.get(fcmToken) || { state: 'unknown', timestamp: now.toISOString(), lastNotification: null };
    const previousState = deviceInfo.state;
    
    // Only update if state actually changed
    if (previousState !== appState) {
      console.log(`App state changed for token ${fcmToken.substring(0, 10)}...: ${previousState} -> ${appState}`);
      
      // Store the app state with timestamp
      deviceStates.set(fcmToken, {
        state: appState,
        timestamp: now.toISOString(),
        lastNotification: deviceInfo.lastNotification
      });
      
      // Handle different app states
      if (appState === 'background' || appState === 'terminated' || appState === 'hidden') {
        // Clear any existing notification timer for this token
        const timerId = sentNotifications.get(fcmToken);
        if (timerId) {
          clearTimeout(timerId);
          console.log(`Cleared existing notification timer for token ${fcmToken.substring(0, 10)}...`);
        }
        
        // Use different delays based on state
        let delay = 2000; // Default 2 seconds (reduced for testing)
        if (appState === 'hidden') {
          delay = 1000; // Shorter delay for hidden state (1 second)
        } else if (appState === 'terminated') {
          delay = 500; // Even shorter for terminated (0.5 second)
        }
        
        // For immediate testing, send notification right away
        console.log(`⚡ Sending immediate notification for app state ${appState}`);
        sendNotificationToDevice(fcmToken, appState);
        
        // Also set a new timer for a follow-up notification
        const newTimerId = setTimeout(() => {
          console.log(`Timer triggered, sending follow-up notification for app state ${appState}`);
          sendNotificationToDevice(fcmToken, appState);
        }, delay);
        
        console.log(`Set new notification timer for token ${fcmToken.substring(0, 10)}..., state ${appState}, delay ${delay}ms`);
        sentNotifications.set(fcmToken, newTimerId);
      } else if (appState === 'foreground') {
        // App came to foreground, clean up any pending background notifications
        const timerId = sentNotifications.get(fcmToken);
        if (timerId) {
          clearTimeout(timerId);
          sentNotifications.delete(fcmToken);
          console.log(`App returned to foreground, cleared notification timer for token ${fcmToken.substring(0, 10)}...`);
        }
      }
    } else {
      console.log(`App state reported but unchanged: ${appState}`);
    }
    
    res.status(200).json({ 
      message: 'App state updated successfully',
      previousState,
      currentState: appState
    });
  } catch (error) {
    console.error('Error updating app state:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Helper function to send notification to a device based on its state
function sendNotificationToDevice(token, state) {
  // Log helpful debug message
  console.log(`About to send ${state} notification to device ${token.substring(0, 10)}...`);
  
  // Check if device still exists and state is still the same
  const deviceInfo = deviceStates.get(token);
  if (!deviceInfo) {
    console.log(`Device with token ${token.substring(0, 10)}... no longer exists`);
    return;
  }
  
  if (deviceInfo.state !== state) {
    console.log(`Device state changed from ${state} to ${deviceInfo.state}, not sending notification`);
    return;
  }
  
  // For testing purposes, reduce delay between notifications to 5 seconds
  const now = new Date();
  if (deviceInfo.lastNotification) {
    const lastNotificationTime = new Date(deviceInfo.lastNotification);
    const timeDiff = now - lastNotificationTime;
    if (timeDiff < 5000) { // 5 seconds (reduced for testing)
      console.log(`Last notification was sent less than 5 seconds ago, skipping`);
      return;
    }
  }
  
  console.log(`Preparing notification for state: ${state}`);
  
  const notificationId = Date.now().toString();
  
  let title, body;
  
  switch (state) {
    case 'terminated':
      title = 'Monie App - Welcome Back';
      body = 'You have new transactions to review!';
      break;
    case 'hidden':
      title = 'Monie App - Quick Update';
      body = 'Your finance summary was just updated!';
      break;
    case 'background':
    default:
      title = 'Monie App - Background Update';
      body = 'Your finance summary is ready while you were away';
      break;
  }
  
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: 'state_notification',
      appState: state,
      timestamp: now.toISOString(),
      notificationId: notificationId,
    },
    android: {
      notification: {
        channelId: 'high_importance_channel',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        }
      }
    },
    token: token,
  };
  
  try {
    console.log(`⚠️ Sending FCM message for state: ${state}`);
    console.log(`⚠️ Message details:`, JSON.stringify(message, null, 2));
    
    getMessaging()
      .send(message)
      .then((response) => {
        console.log(`✅ Successfully sent notification to ${state} app:`, response);
        
        // Update last notification time
        deviceStates.set(token, {
          ...deviceInfo,
          lastNotification: now.toISOString()
        });
        
        // Clean up the notification timer
        sentNotifications.delete(token);
      })
      .catch((error) => {
        console.error(`❌ Error sending notification to ${state} app:`, error);
        console.error(`❌ Error code:`, error.code);
        console.error(`❌ Error message:`, error.message);
        
        // If the error is due to an invalid token, remove it
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
          console.log(`🗑️ Removing invalid token: ${token.substring(0, 10)}...`);
          deviceStates.delete(token);
        }
        
        // Clean up the notification timer on error too
        sentNotifications.delete(token);
      });
  } catch (error) {
    console.error('❌ Unexpected error sending notification:', error);
    sentNotifications.delete(token);
  }
}

// Test notification endpoint
app.post("/send", function (req, res) {
  const { fcmToken, title, body } = req.body;
  
  if (!fcmToken) {
    return res.status(400).json({ error: 'FCM token is required' });
  }
  
  const message = {
    notification: {
      title: title || "Push Notify",
      body: body || 'This is a Test Notification'
    },
    data: {
      type: 'test_notification',
      timestamp: new Date().toISOString(),
      notificationId: Date.now().toString(),
    },
    android: {
      notification: {
        channelId: 'high_importance_channel',
      }
    },
    token: fcmToken,
  };
  
  getMessaging()
    .send(message)
    .then((response) => {
      res.status(200).json({
        message: "Successfully sent message",
        token: fcmToken,
      });
      console.log("Successfully sent message:", response);
    })
    .catch((error) => {
      res.status(400).json({ error: error.message });
      console.log("Error sending message:", error);
    });
});

// Get current state endpoint
app.get('/device-state', function(req, res) {
  try {
    const { fcmToken } = req.query;
    
    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token is required' });
    }
    
    const deviceInfo = deviceStates.get(fcmToken);
    const state = deviceInfo ? deviceInfo.state : 'unknown';
    
    res.status(200).json({ 
      token: fcmToken, 
      state,
      lastUpdated: deviceInfo ? deviceInfo.timestamp : null,
      lastNotification: deviceInfo ? deviceInfo.lastNotification : null
    });
  } catch (error) {
    console.error('Error getting device state:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all device states for debugging
app.get('/all-devices', function(req, res) {
  try {
    const devices = Array.from(deviceStates.entries()).map(([token, info]) => ({
      token: token.substring(0, 10) + '...',  // Only show part of the token for security
      state: info.state,
      lastUpdated: info.timestamp,
      lastNotification: info.lastNotification
    }));
    
    res.status(200).json({ devices, count: devices.length });
  } catch (error) {
    console.error('Error getting all devices:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add a simple test endpoint to manually trigger a notification
app.get('/test-notification', function(req, res) {
  try {
    const { token } = req.query;
    
    if (!token) {
      return res.status(400).json({ error: 'FCM token is required as a query parameter' });
    }
    
    console.log(`Received test notification request for token: ${token.substring(0, 10)}...`);
    
    // Send a test notification immediately
    const message = {
      notification: {
        title: 'Test Notification',
        body: 'This is a test notification from your server!',
      },
      data: {
        type: 'test_notification',
        timestamp: new Date().toISOString(),
        notificationId: Date.now().toString(),
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          }
        }
      },
      token: token,
    };
    
    getMessaging()
      .send(message)
      .then((response) => {
        console.log(`Successfully sent test notification:`, response);
        res.status(200).json({
          message: "Test notification sent successfully",
          messageId: response,
        });
      })
      .catch((error) => {
        console.error(`Error sending test notification:`, error);
        res.status(500).json({ error: error.message });
      });
  } catch (error) {
    console.error('Error processing test notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

const PORT = process.env.PORT || 4000;  // Updated to match client port in injection.dart
app.listen(PORT, function () {
  console.log(`Notification server started on port ${PORT}`);
  console.log(`Server URL: http://localhost:${PORT}`);
});