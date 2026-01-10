# 💰 Finance Dashboard - Complete Supabase Integration

A modern, feature-rich Flutter finance dashboard with Supabase backend integration, offering real-time data synchronization, user authentication, and comprehensive financial management.

## 📱 **Screenshots & Demo**

### 🎯 **Demo Credentials**
- **Email**: `demo@example.com`
- **Password**: `demo123`

### 🖼 **Key Features**
- ✅ Beautiful dark theme UI
- ✅ Real-time data sync
- ✅ Cross-device support
- ✅ Secure authentication
- ✅ Budget tracking
- ✅ Debt management

---

## 🚀 **Features Overview**

### 🔐 **Authentication System**
- **Email/Password Authentication** with Supabase Auth
- **User Registration & Login** with form validation
- **Password Reset** functionality
- **Secure Session Management** with JWT tokens
- **Auto-logout** on session expiry

### 💳 **Financial Management**
- **Transaction Tracking** (Income & Expenses)
- **Category Management** with custom icons
- **Budget Planning** with monthly limits
- **Debt Tracking** with payment history
- **Spending Analytics** with visual charts

### 📊 **Data Visualization**
- **Monthly Spending Charts**
- **Budget Progress Bars**
- **Debt Reduction Graphs**
- **Category-wise Breakdown**
- **Trend Analysis**

### 🔄 **Real-time Features**
- **Live Data Sync** across devices
- **Offline Support** with local caching
- **Conflict Resolution** for simultaneous edits
- **Push Notifications** for budget alerts

---

## 🏗 **Technical Architecture**

### **Frontend Stack**
```
Flutter 3.x
├── State Management: Provider/Riverpod
├── UI Framework: Material 3
├── Navigation: GoRouter
├── Local Storage: Hive/SharedPreferences
├── HTTP Client: Supabase Flutter SDK
└── Charts: fl_chart
```

### **Backend Stack**
```
Supabase
├── Database: PostgreSQL 14+
├── Authentication: Supabase Auth
├── Realtime: Supabase Realtime API
├── Storage: Supabase Storage
├── Functions: Supabase Edge Functions
└── Security: Row Level Security (RLS)
```

---

## 📦 **Installation & Setup**

### **Prerequisites**
- Flutter SDK >= 3.0.0
- Dart SDK >= 2.17.0
- Supabase Account
- Git

### **1. Clone Repository**
```bash
git clone https://github.com/kagiroi11/veridion.git
cd veridion
git checkout juan
```

### **2. Install Dependencies**
```bash
flutter pub get
```

### **3. Supabase Setup**

#### **Create Supabase Project**
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Note project URL and anon key

#### **Run Migration Script**
1. Go to Supabase Dashboard → SQL Editor
2. Run `supabase_migration.sql` script
3. Verify tables created successfully

#### **Configure Authentication**
1. Enable Email/Password auth
2. Configure SMTP settings
3. Set up redirect URLs

### **4. Configure Flutter App**
```bash
# Create .env file
echo "SUPABASE_URL=your_supabase_url" > .env
echo "SUPABASE_ANON_KEY=your_supabase_anon_key" >> .env
```

### **5. Run App**
```bash
flutter run
```

---

## 🗄 **Database Schema**

### **Core Tables**

#### **`transactions`**
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  amount BIGINT NOT NULL, -- Amount in paise (1/100 of currency)
  date DATE NOT NULL,
  is_expense BOOLEAN NOT NULL,
  category TEXT,
  category_id UUID REFERENCES categories(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **`categories`**
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  is_expense BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **`user_settings`**
```sql
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  starting_balance BIGINT DEFAULT 0,
  monthly_budget BIGINT DEFAULT 0,
  current_debt BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **`monthly_debt_history`**
```sql
CREATE TABLE monthly_debt_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  month DATE NOT NULL,
  debt_amount BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, month)
);
```

### **Security Policies**
```sql
-- Users can only access their own data
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions" ON transactions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions" ON transactions
  FOR DELETE USING (auth.uid() = user_id);
```

---

## 🔧 **Configuration Details**

### **Environment Variables**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### **Supabase Configuration**
- **Project URL**: Your Supabase project URL
- **Anon Key**: Public API key (safe for client-side)
- **Service Role Key**: Server-side key (never expose in client)

### **Authentication Settings**
- **Email Confirmation**: Required
- **Password Recovery**: Enabled
- **Session Duration**: 1 hour (configurable)
- **Redirect URLs**: Add your app's callback URLs

---

## 📱 **App Structure**

### **File Organization**
```
lib/
├── auth/
│   └── auth_wrapper.dart          # Authentication state management
├── models/
│   ├── transaction.dart           # Transaction data model
│   ├── category.dart              # Category data model
│   ├── user_settings.dart         # User settings model
│   └── monthly_debt_history.dart  # Debt history model
├── screens/
│   ├── home_screen.dart           # Main dashboard
│   ├── login_screen.dart          # Authentication screen
│   ├── profile_screen.dart        # User profile
│   └── transactions_screen.dart   # Transaction list
├── services/
│   ├── database_service.dart      # Database operations
│   └── supabase_service.dart      # Supabase client
├── utils/
│   └── formatters.dart            # Currency/date formatting
├── data/
│   └── transactions_data.dart      # Sample data & utilities
└── main.dart                      # App entry point
```

### **Key Components**

#### **Authentication Flow**
1. **AuthWrapper** manages user session
2. **LoginScreen** handles authentication
3. **ProfileScreen** manages user settings
4. **Auto-redirect** based on auth state

#### **Data Management**
1. **DatabaseService** handles all CRUD operations
2. **SupabaseService** manages client configuration
3. **Models** define data structures
4. **Real-time listeners** update UI automatically

---

## 🔒 **Security Features**

### **Data Protection**
- **Row Level Security (RLS)** on all tables
- **JWT-based authentication**
- **HTTPS-only communication**
- **Input validation** on client and server
- **SQL injection prevention**

### **User Privacy**
- **Data isolation** between users
- **No data sharing** between accounts
- **Secure session management**
- **Automatic logout** on token expiry

### **API Security**
- **Rate limiting** (Supabase default)
- **CORS configuration**
- **API key management**
- **Environment variable protection**

---

## 🚀 **Deployment**

### **Flutter Web Deployment**
```bash
# Build for web
flutter build web

# Deploy to hosting
# Example: Firebase Hosting
firebase deploy --only hosting
```

### **Mobile App Deployment**
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### **Supabase Production Setup**
1. **Enable production mode**
2. **Configure custom domain**
3. **Set up monitoring**
4. **Enable backups**
5. **Configure alerts**

---

## 🧪 **Testing**

### **Unit Tests**
```bash
flutter test
```

### **Integration Tests**
```bash
flutter test integration_test/
```

### **Manual Testing Checklist**
- [ ] User registration flow
- [ ] Login/logout functionality
- [ ] Transaction CRUD operations
- [ ] Budget tracking
- [ ] Debt management
- [ ] Real-time sync
- [ ] Offline support

---

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Authentication Problems**
```bash
# Check Supabase auth configuration
# Verify email confirmation settings
# Check redirect URLs
```

#### **Database Connection Issues**
```bash
# Verify Supabase URL and keys
# Check network connectivity
# Review RLS policies
```

#### **Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### **Debug Mode**
Enable debug logging:
```dart
// In main.dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  debug: true, // Enable debug logs
);
```

---

## 📊 **Performance Optimization**

### **Database Optimization**
- **Indexes** on frequently queried columns
- **Query optimization** with proper filters
- **Connection pooling** (Supabase managed)
- **Caching strategy** for frequently accessed data

### **App Performance**
- **Lazy loading** for large datasets
- **Image optimization** for profile pictures
- **State management** optimization
- **Memory management** for large transaction lists

---

## 🔮 **Future Enhancements**

### **Planned Features**
- [ ] **Multi-currency Support**
- [ ] **Recurring Transactions**
- [ ] **Advanced Analytics Dashboard**
- [ ] **Export/Import Functionality**
- [ ] **Bill Reminders**
- [ ] **Investment Tracking**
- [ ] **Goal Setting**
- [ ] **Family/Budget Sharing**

### **Technical Improvements**
- [ ] **Push Notifications**
- [ ] **Offline-first Architecture**
- [ ] **Advanced Charts**
- [ ] **Machine Learning Insights**
- [ ] **API Rate Limiting**
- [ ] **Advanced Security Features**

---

## 📚 **API Reference**

### **Database Service Methods**

#### **Transactions**
```dart
// Get all user transactions
Future<List<Transaction>> getTransactions()

// Add new transaction
Future<Transaction> addTransaction(Transaction transaction)

// Delete transaction
Future<void> deleteTransaction(String transactionId)
```

#### **User Settings**
```dart
// Get user settings
Future<UserSettings> getUserSettings()

// Update user settings
Future<UserSettings> updateUserSettings(UserSettings settings)

// Auto-create settings for new users
Future<UserSettings?> getOrCreateUserSettings()
```

#### **Categories**
```dart
// Get all categories
Future<List<Category>> getCategories()

// Add new category
Future<Category> addCategory(Category category)
```

---

## 🤝 **Contributing**

### **Development Setup**
1. Fork the repository
2. Create feature branch
3. Make changes
4. Add tests
5. Submit pull request

### **Code Style**
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable names
- Add comments for complex logic
- Include tests for new features

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 **Acknowledgments**

- **Supabase** for the amazing backend service
- **Flutter Team** for the excellent UI framework
- **Open Source Community** for the valuable packages and tools

---

## 📞 **Support & Contact**

- **GitHub Issues**: [Report bugs](https://github.com/kagiroi11/veridion/issues)
- **Discord Community**: [Join our community](https://discord.gg/your-invite)
- **Email**: support@yourdomain.com

---

## 📈 **Version History**

### **v1.0.0** (Current)
- ✅ Initial release
- ✅ Basic authentication
- ✅ Transaction management
- ✅ Budget tracking
- ✅ Real-time sync
- ✅ Supabase integration

### **Upcoming v2.0.0**
- 🔄 Multi-currency support
- 🔄 Advanced analytics
- 🔄 Investment tracking
- 🔄 Family budgeting

---

