# 🐾 PawPal - Full Stack Pet Adoption App

**PawPal** is a comprehensive mobile application designed to connect pet owners with potential adopters and donors. This project demonstrates a full-stack implementation using **Flutter** for the frontend and a **Native PHP/MySQL** REST API for the backend.

The app features secure authentication, geolocation services, a payment gateway integration, and complex CRUD operations.

---

## 📱 Key Features

### 1. User Module & Authentication
* **Secure Registration & Login:** Form validation, duplicate email checks, and **SHA1** password hashing.
* **Auto-Login:** "Remember Me" functionality using `shared_preferences`.
* **Profile Management:** Users can edit their details and update their profile picture.
    * *Technical Highlight:* Implemented **cache-busting** (`?v=timestamp`) to ensure profile image updates reflect immediately in the app.

### 2. Pet Listing & Management (CRUD)
* **Public Feed:** View all pets available for adoption or needing donations.
* **Search & Filter:** Dynamic SQL queries allow users to **Search by Name** and **Filter by Category** (Cat, Dog, Rabbit, etc.) simultaneously.
* **Submit Pet:** Upload up to **3 images** (Base64 encoded), auto-capture **GPS location**, and select pet health/gender statuses.
* **My Listings:** Users can view and **Delete** their own submissions.

### 3. Adoption System
* **Adoption Requests:** Users can request to adopt a specific pet by sending a motivation message.
* **Ownership Logic:** The app prevents users from adopting or donating to their own pets (buttons are disabled for owners).

### 4. Donation Module & Payment Gateway
* **Flexible Donations:** Support for **Money**, **Food**, and **Medical** supplies.
* **Billplz Integration:** Integrated the **Billplz Sandbox API** to process monetary donations via an external secure browser.
* **Donation History:** Users can view a history of their contributions, tracking the status (`Success`, `Failed`, `Pending`) and which pet received the donation.
* **Validation:** Strict input formatters ensure only valid currency amounts are entered.

---

## 🛠️ Tech Stack

### Frontend (Flutter)
* **Language:** Dart
* **Key Packages:**
    * `http`: For REST API communication.
    * `image_picker`: For selecting images from Camera/Gallery.
    * `geolocator`: For capturing real-time GPS coordinates.
    * `shared_preferences`: For local data persistence.
    * `url_launcher`: For opening the Payment Gateway.
    * `flutter/services`: For input formatting and validation.

### Backend (Native PHP)
* **API:** Custom REST API (JSON).
* **Database:** MySQL (MariaDB).
* **Security:** Prepared statements and input sanitization.
* **Payment:** cURL requests to Billplz API.

---

## 📂 Database Schema

To set up the database, run the following SQL commands in **phpMyAdmin**:

```sql
-- 1. Users Table
CREATE TABLE `tbl_users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL, -- SHA1 Hashed
  `phone` varchar(20) NOT NULL,
  `reg_date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`)
);

-- 2. Pets Table
CREATE TABLE `tbl_pets` (
  `pet_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL, -- Owner ID
  `pet_name` varchar(255) NOT NULL,
  `pet_type` varchar(50) NOT NULL,
  `pet_age` varchar(10) DEFAULT NULL,
  `pet_gender` varchar(10) NOT NULL,
  `pet_health` varchar(50) NOT NULL,
  `category` varchar(50) NOT NULL, -- Adoption/Donation
  `description` text NOT NULL,
  `image_paths` text NOT NULL, -- JSON Array
  `lat` varchar(50) NOT NULL,
  `lng` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`pet_id`)
);

-- 3. Donations Table
CREATE TABLE `tbl_donations` (
  `donation_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL, -- Donor ID
  `pet_id` int(11) NOT NULL, -- Recipient Pet ID
  `donation_type` varchar(20) NOT NULL, -- Money/Food/Medical
  `amount` double(10,2) NOT NULL,
  `description` varchar(255) NOT NULL,
  `payment_status` varchar(20) NOT NULL, -- Success/Pending/Failed
  `donation_date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`donation_id`)
);

-- 4. Adoptions Table
CREATE TABLE `tbl_adoptions` (
  `adoption_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL, -- Adopter ID
  `pet_id` int(11) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Pending',
  `message` text DEFAULT NULL,
  `date_created` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`adoption_id`)
);
```

## 🚀 Installation & Setup

### 1. Server Configuration (XAMPP)
1.  Locate your XAMPP `htdocs` folder (e.g., `C:\xampp\htdocs\`).
2.  Create a folder named **`pawpal`**.
3.  Inside `pawpal`, create an **`api`** folder and an **`assets`** folder.
4.  Put all `.php` files inside the **`api`** folder.
5.  Create subfolders `assets/pets` and `assets/profile` for image storage.

### 2. API Configuration
1.  Open `dbconnect.php` and configure your database credentials:
    ```php
    $servername = "localhost";
    $username   = "root";
    $password   = "";
    $dbname     = "pawpal_db";
    ```
2.  Update the `payment.php` file with your **Billplz API Key** and **Collection ID**.

### 3. Flutter Configuration
1.  Open `lib/myconfig.dart`.
2.  Update the `baseUrl` to match your local IP address:
    ```dart
    class MyConfig {
      static const String baseUrl = "http://192.168.x.x"; 
    }
    ```
3.  Run `flutter pub get` to install dependencies.
4.  Run `flutter run` to launch the app.
