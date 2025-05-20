#!/bin/bash

# Run and reload the app
echo "📱 Running Monie app..."
flutter clean
flutter pub get
mkdir -p assets/lang
flutter run 