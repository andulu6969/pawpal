<?php
// Set headers to allow requests from the Flutter app
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

// 1. Validation: Check if critical data (User ID, Name, and Image) is present
if (!isset($_POST['user_id']) || !isset($_POST['pet_name']) || !isset($_POST['image'])) {
    sendJsonResponse(array('status' => 'failed', 'message' => 'Missing required data'));
    die();
}

// 2. Capture and Sanitize Input Data
$userid = $_POST['user_id'];
$pet_name = addslashes($_POST['pet_name']); // Escape special characters for SQL safety
$pet_age = $_POST['pet_age'];
$pet_gender = $_POST['pet_gender'];
$pet_health = $_POST['pet_health'];
$pet_type = $_POST['pet_type'];
$category = $_POST['category'];
$description = addslashes($_POST['description']);
$lat = $_POST['lat'];
$lng = $_POST['lng'];
$encoded_string = $_POST['image']; 

// 3. Image Processing
// The app sends a JSON string containing a list of Base64 encoded images.
// We decode this string into a PHP array first.
$images = json_decode($encoded_string);
$saved_filenames = array();

// Ensure the target directory exists before saving
if (!file_exists("../assets/pets")) {
    mkdir("../assets/pets", 0777, true);
}

// Loop through each image, decode from Base64, and save to the server
foreach($images as $index => $base64) {
    $decoded_image = base64_decode($base64);
    
    // Generate a unique filename: pet_USERID_TIMESTAMP_INDEX.jpg
    // This prevents filename conflicts.
    $filename = "pet_" . $userid . "_" . time() . "_" . $index . ".jpg";
    $path = "../assets/pets/" . $filename;
    
    // Save file and add name to array if successful
    if(file_put_contents($path, $decoded_image)){
        $saved_filenames[] = $filename;
    }
}

// Encode the list of saved filenames back to JSON for storage in the database
$str_filenames = json_encode($saved_filenames);

// 4. Insert Record into Database
$sqlinsert = "INSERT INTO tbl_pets (user_id, pet_name, pet_age, pet_gender, pet_health, pet_type, category, description, image_paths, lat, lng) 
              VALUES ('$userid', '$pet_name', '$pet_age', '$pet_gender', '$pet_health', '$pet_type', '$category', '$description', '$str_filenames', '$lat', '$lng')";

if ($conn->query($sqlinsert) === TRUE) {
    sendJsonResponse(array('status' => 'success', 'data' => null));
} else {
    sendJsonResponse(array('status' => 'failed', 'data' => null));
}

// Helper Function: Returns response in JSON format
function sendJsonResponse($sentArray) {
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}
?>