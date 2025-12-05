<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// submit_pet.php
include_once("dbconnect.php");

// Check if POST data is missing
if (!isset($_POST['user_id']) || !isset($_POST['pet_name']) || !isset($_POST['image'])) {
    $response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
    die();
}

// Capture Data
$userid = $_POST['user_id'];
$pet_name = $_POST['pet_name'];
$pet_type = $_POST['pet_type'];
$category = $_POST['category'];
$description = $_POST['description'];
$lat = $_POST['lat'];
$lng = $_POST['lng'];
$encoded_string = $_POST['image']; // This is a JSON string of base64 images

//Decode JSON List of Images
$images = json_decode($encoded_string);
$saved_filenames = array();

foreach($images as $index => $base64) {
    // Decode Base64 to binary
    $decoded_image = base64_decode($base64);
    
    // Generate unique filename: pet_USERID_TIME_INDEX.jpg
    $filename = "pet_" . $userid . "_" . time() . "_" . $index . ".jpg";
    $path = "../assets/pets/" . $filename; // Make sure 'assets' folder exists
    
    // Save file using file_put_contents (Requirement)
    if(file_put_contents($path, $decoded_image)){
        $saved_filenames[] = $filename;
    }
}

// 4. Convert array of filenames back to JSON for database storage
$str_filenames = json_encode($saved_filenames);

// 5. Insert into Database
$sqlinsert = "INSERT INTO tbl_pets (user_id, pet_name, pet_type, category, description, image_paths, lat, lng) VALUES ('$userid', '$pet_name', '$pet_type', '$category', '$description', '$str_filenames', '$lat', '$lng')";

if ($conn->query($sqlinsert) === TRUE) {
    $response = array('status' => 'success', 'data' => null);
    sendJsonResponse($response);
} else {
    $response = array('status' => 'failed', 'data' => null);
    sendJsonResponse($response);
}

function sendJsonResponse($sentArray)
{
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}
?>