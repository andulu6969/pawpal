# 🐾 PawPal - Pet Adoption App (Authentication Module)

**PawPal** is a mobile application designed for pet adoption and donations. This repository contains the **User Authentication Module** (Assignment 2), featuring a full-stack implementation using **Flutter** for the frontend and **PHP/MySQL** for the backend.

## 📱 Features

* **User Registration:**
    * Full form validation (Name, Email, Phone, Password).
    * Checks for duplicate emails in the database.
    * Secure password hashing (SHA1).
* **User Login:**
    * Secure authentication against a MySQL database.
    * **"Remember Me"** functionality using Shared Preferences to save credentials.
* **Home Screen:**
    * Displays logged-in user details (Name, Email).
    * Secure Logout function that clears the navigation stack.
* **Backend API:**
    * Custom PHP scripts handling JSON requests and responses.
    * CORS support for Web and Mobile.
