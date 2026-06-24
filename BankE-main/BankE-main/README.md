# 🏦 Contro – Internet Banking Application

**Contro** is a premium, production-ready Internet Banking application built with **Flutter**. It demonstrates modern software engineering practices, featuring a highly scalable **Clean Architecture** and robust state management with **BLoC**.

---

## ✨ Features

- 👤 **Secure Authentication**: OTP-based login and registration (Email/Phone).
- 📊 **Dynamic Dashboard**: Overview of account balance, swipable debit cards, and recent activity.
- 💸 **Money Transfers**: Secure peer-to-peer transfers with real-time balance updates.
- 🧾 **Bill Payments**: Integrated utility bill payment system (Electricity, Water, Internet, etc.).
- 💳 **Card Management**: Add, view, freeze, or delete virtual/physical cards.
- 📁 **Loan Management**: Apply for loans with document upload and track approval status.
- 🛡️ **Admin Portal**: Restricted access for managing users, adjusting balances, and approving/rejecting loans.
- 🌍 **Localization**: Support for multiple languages (English, Arabic) with RTL support.
- 🌓 **Theme Support**: Seamless switching between Light and Dark modes.
- 📍 **Location-Based Security**: Trusted zone verification for sensitive transactions.

---

## 🏗️ Architecture

The project follows **Clean Architecture** principles to ensure maintainability, scalability, and testability:

- **Data Layer**: Repositories, Data Sources (Mock/Remote), and Models (JSON Serialization).
- **Domain Layer**: Business Logic, Entities, Use Cases, and Repository Interfaces.
- **Presentation Layer**: UI Views (Widgets), BLoCs (State Management), and Theme/Styling.

### State Management
- **BLoC (Business Logic Component)**: Used for managing complex states across the app (Auth, Account, Admin, Loan, etc.).
- **Equatable**: Ensures efficient state comparisons and UI rebuilds.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-started)
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Contro-Project.git
   cd Contro-Project
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📱 Screenshots

| Authentication | Dashboard | Admin Portal |
|:---:|:---:|:---:|
| ![Auth](https://via.placeholder.com/200x400?text=Authentication) | ![Dashboard](https://via.placeholder.com/200x400?text=Dashboard) | ![Admin](https://via.placeholder.com/200x400?text=Admin+Panel) |

---

## 🛡️ Security
- **No Sensitive Data Committed**: API keys and secrets are managed via environment variables (or local.properties).
- **Trusted Zones**: Secure location verification for transfers.

---

## 🤝 Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements.

## 📄 License
This project is licensed under the MIT License.
