# Monie

A personal finance management app built with Flutter and Supabase.

## Features

- **User Authentication:** Sign up, login, and password reset with email verification
- **Transaction Tracking:** Record and categorize your income and expenses
- **Budget Management:** Create and monitor budgets for different categories
- **Account Management:** Keep track of multiple accounts (cash, banks, etc.)
- **Analytics:** Visualize your financial data with charts and reports

## Getting Started

### Prerequisites

- Flutter 3.7.2 or higher
- Supabase account (for backend and authentication)

### Setup

1. Clone the repository
```bash
git clone https://github.com/yourusername/monie.git
cd monie
```

2. Install dependencies
```bash
flutter pub get
```

3. Create a Supabase project
   - Sign up at [Supabase](https://supabase.com/)
   - Create a new project
   - Enable authentication (Email and OAuth providers)
   - Set up email confirmation in the Authentication settings

4. Configure environment variables
   - Create a `.env` file in the project root
   - Add your Supabase URL and anonymous key:
   ```
   SUPABASE_URL=https://your-project-url.supabase.co
   SUPABASE_ANON_KEY=your-anonymous-key
   ```

5. Set up Deep Linking for authentication flows
   - Configure your platform-specific setup for deep linking:
   
   **Android**:
   - In `android/app/src/main/AndroidManifest.xml`, add:
   ```xml
   <activity
       android:name=".MainActivity"
       ...
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="io.supabase.flutterquickstart" android:host="login-callback" />
       </intent-filter>
   </activity>
   ```
   
   **iOS**:
   - In `ios/Runner/Info.plist`, add:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>io.supabase.flutterquickstart</string>
           </array>
       </dict>
   </array>
   ```

6. Run the app
```bash
flutter run
```

## Architecture

The app follows Clean Architecture principles:

- **Presentation Layer:** UI components, BLoCs, pages, widgets
- **Domain Layer:** Business logic, entities, use cases, repository interfaces
- **Data Layer:** Repository implementations, data sources, models, DTOs

## Dependencies

- [flutter_bloc](https://pub.dev/packages/flutter_bloc): State management
- [get_it](https://pub.dev/packages/get_it): Dependency injection
- [supabase_flutter](https://pub.dev/packages/supabase_flutter): Authentication and backend
- [dartz](https://pub.dev/packages/dartz): Functional programming utilities
- [equatable](https://pub.dev/packages/equatable): Value equality
- [fl_chart](https://pub.dev/packages/fl_chart): Interactive charts

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Email Verification Setup

### Temporarily Disabling Email Verification

If you need to bypass email verification during development:

1. **Disable Email Confirmation in Supabase**:
   - Go to your Supabase project dashboard
   - Navigate to Authentication > Providers > Email
   - Uncheck the "Confirm email" option
   - Save changes

2. **Code changes**:
   - The app has been configured to automatically attempt sign-in after signup
   - No verification page will be shown
   - Users will be immediately logged in after creating an account

**Important**: Re-enable email verification before deploying to production for security reasons.

### Configuring Supabase for Email Verification

1. **Enable Email Confirmation**:
   - Go to your Supabase project dashboard
   - Navigate to Authentication > Providers > Email
   - Enable "Confirm email" option
   - Save changes

2. **Set Up SMTP Configuration** (essential for sending emails):
   - Go to Authentication > Email Templates
   - Click on "Enable Custom SMTP" button
   - Enter your SMTP credentials:
     - Host (e.g., smtp.gmail.com)
     - Port (e.g., 587 for TLS)
     - Username (your email address)
     - Password (your email password or app-specific password)
     - From email (the sender address)
   - Click "Save" to confirm

3. **Customize Email Templates**:
   - Still in Authentication > Email Templates
   - Edit the "Confirm signup" template
   - You can customize the subject line and email content
   - Make sure to keep the magic link variable (represented as {{ .ConfirmationURL }} or similar)
   - Save changes

4. **Test Email Delivery**:
   - In the Supabase dashboard, go to Authentication > Users
   - Create a test user to verify that emails are being sent
   - Check your email and spam folders

5. **Deep Link Configuration**:
   - In Authentication > URL Configuration
   - Add your app's custom URL scheme: `com.tadyuh.monie://login-callback`
   - This must match exactly with what's used in the app code

### Troubleshooting Email Verification

If you're not receiving verification emails:

1. **Check SMTP Settings**:
   - Verify SMTP credentials are correct
   - Some email providers require app-specific passwords for SMTP access
   - Test SMTP configuration using the "Send test email" feature if available

2. **Check Supabase Logs**:
   - Go to Database > Logs in your Supabase dashboard
   - Look for any errors related to sending emails

3. **Verify URL Redirection**:
   - Ensure the URL scheme in your app matches what's configured in Supabase
   - Both Android and iOS platforms need proper configuration

4. **Check Spam Folders**:
   - Verification emails might be filtered into spam folders

5. **Email Service Limits**:
   - Some email services have sending limits or require domain verification

### Fixing "Redirect to localhost" Issue

If clicking verification links redirects to localhost instead of your app:

1. **Update Site URL in Supabase**:
   - Go to Authentication > URL Configuration in your Supabase dashboard
   - Set the Site URL to your production URL (e.g., https://yourdomain.com)
   - For development/testing, you can use the Supabase project URL temporarily (e.g., https://yourproject.supabase.co)

2. **Configure Additional Redirect URLs**:
   - In the same URL Configuration page, add allowed redirect URLs:
     - Add `https://app.supabase.com/auth/callback` as an allowed redirect URL
     - Add your app's custom URL scheme: `com.tadyuh.monie://login-callback`

3. **Update Email Templates**:
   - In Authentication > Email Templates
   - Make sure the email templates use the correct {{ .ConfirmationURL }} variable
   - Test the template by sending a verification email to yourself

4. **IMPORTANT - Check Current App Configuration**:
   - The app is now configured to use `https://app.supabase.com/auth/callback` for email verification
   - This ensures verification works across different devices
   - After verification, the user will see a success page on Supabase's site and can return to the app to sign in

5. **For Production**:
   - Consider setting up your own custom domain or web page for email confirmations
   - Update the `getRedirectUrl()` method in `lib/core/utils/supabase_url_helper.dart` to use your custom URL
