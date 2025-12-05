# 🐾 PawPal - Pet Adoption App (Midterm Submission)

**PawPal** is a mobile application designed for pet adoption and donations. This repository contains the **Midterm Assignment**, which builds upon the User Authentication module to include a **Pet Submission & Listing Module**.

It features a full-stack implementation using **Flutter** (Mobile) for the frontend and **Native PHP/MySQL** for the backend.

---

## 📱 Features implemented

### 1. User Authentication (Assignment 2)
* **User Registration:** Full form validation (Name, Email, Phone), duplicate email check, and **SHA1** password hashing.
* **User Login:** Secure authentication against MySQL.
* **"Remember Me":** Uses `shared_preferences` to persist user credentials locally.
* **Secure Logout:** Clears the navigation stack to prevent unauthorized back-navigation.

### 2. Pet Submission (Midterm Task)
* **Multi-Image Upload:** Users can select up to **3 images** using the device Camera or Gallery.
* **Geolocation:** Automatically captures the user's current **Latitude & Longitude** using `geolocator`.
* **Dynamic Form:** Includes dropdowns for Pet Type and Category, with text validation.
* **Base64 Encoding:** Images are converted to Base64 strings for secure JSON transmission to the PHP backend.

### 3. Main Page Listing
* **Dynamic Listing:** Fetches and displays pets submitted by the logged-in user.
* **Thumbnail Handling:** Decodes JSON image paths to display the first image as a thumbnail.
* **Empty State:** Displays a friendly "No submissions yet" message when the list is empty.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
    * `http`: REST API communication.
    * `image_picker`: Camera/Gallery access.
    * `geolocator`: GPS location retrieval.
    * `shared_preferences`: Local storage.
* **Backend:** Native PHP (No frameworks).
    * `file_put_contents`: For saving binary image data (Requirement).
    * `json_encode/decode`: For handling API responses.
    * `mysqli`: For database connection.
* **Database:** MySQL (XAMPP/phpMyAdmin).

---


## 🚀 Setup Guide

### 1️⃣ Backend Setup (XAMPP)
1.  Navigate to your XAMPP installation folder: `C:\xampp\htdocs\`.
2.  Create a folder named **`pawpal`**.
3.  Inside `pawpal`, create the following structure:
    ```text
    pawpal/
    ├── api/                # Contains all PHP logic scripts
    │   ├── register_user.php
    │   ├── login_user.php
    │   ├── submit_pet.php
    │   └── load_pets.php
    │   └── dbconnect.php
    └── assets/
        └── pets/           # (Empty folder) Images will be saved here
    ```

### 2️⃣ Database Setup
1.  Open **phpMyAdmin** and create a database named `pawpal_db`.
2.  Run the following SQL commands to create the required tables:

```sql
-- Table 1: Users
CREATE TABLE tbl_users (
    user_id INT(11) NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    reg_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY email (email)
);

-- Table 2: Pets
CREATE TABLE tbl_pets (
    pet_id INT(11) NOT NULL AUTO_INCREMENT,
    user_id INT(11) NOT NULL,
    pet_name VARCHAR(100) NOT NULL,
    pet_type VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    image_paths TEXT NOT NULL, -- Stores JSON array of filenames
    lat VARCHAR(50) NOT NULL,
    lng VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pet_id),
    FOREIGN KEY (user_id) REFERENCES tbl_users(user_id)
);