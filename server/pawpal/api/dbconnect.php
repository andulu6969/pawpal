<?php
// Set headers to allow cross-origin requests (essential for Flutter)
header("Access-Control-Allow-Origin: *");

$servername = "localhost";
$username   = "canortxw_andrew";
$password   = "[$!R3N^ccnnT";
$dbname     = "canortxw_Andrew_pawpal_db";

// Create connection using MySQLi
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection and kill process if failed
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>