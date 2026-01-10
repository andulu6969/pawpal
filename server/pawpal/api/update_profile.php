<?php
// Set headers to allow cross-origin requests from the Flutter app
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

// 1. Validation: Ensure critical user data is present
if (!isset($_POST['user_id']) || !isset($_POST['name']) || !isset($_POST['phone'])) {
    echo json_encode(array("status" => "failed", "message" => "Missing data"));
    exit();
}

// 2. Capture Input Data
$userid = $_POST['user_id'];
$name = $_POST['name'];
$phone = $_POST['phone'];
$password = $_POST['password'];
// Check if an image was sent; default to "NA" if not
$image = isset($_POST['image']) ? $_POST['image'] : "NA";

// 3. Begin Constructing SQL Query
// We always update the name and phone number
$sql = "UPDATE tbl_users SET name = '$name', phone = '$phone'";

// 4. Conditional Password Update
// Only update the password if the user actually typed a new one (not "NA")
if ($password != "NA") {
    $sha1pass = sha1($password);
    $sql .= ", password = '$sha1pass'";
}

// 5. Image Handling
// If a new image is selected, decode the Base64 string and overwrite the old file
if ($image != "NA") {
    $decoded_image = base64_decode($image);
    
    // Ensure the directory exists
    if (!file_exists("../assets/profile")) {
        mkdir("../assets/profile", 0777, true);
    }
    
    // Save the file using the user_id as the filename (e.g., 5.jpg)
    $path = "../assets/profile/" . $userid . ".jpg";
    file_put_contents($path, $decoded_image);
}

// 6. Finalize and Execute SQL
// Append the WHERE clause to ensure we only update this specific user
$sql .= " WHERE user_id = '$userid'";

if ($conn->query($sql) === TRUE) {
    echo json_encode(array("status" => "success", "data" => null));
} else {
    echo json_encode(array("status" => "failed", "data" => null));
}
?>