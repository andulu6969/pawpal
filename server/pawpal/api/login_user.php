<?php
header("Access-Control-Allow-Origin: *"); 

// Ensure the request method is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {

    //Check if email and password are provided
    if (!isset($_POST['email']) || !isset($_POST['password'])) {
        $response = array('status' => 'failed', 'message' => 'Missing email or password');
        sendJsonResponse($response);
        exit();
    }

    $email = $_POST['email'];
    $password = $_POST['password'];
    
    //Hash the password using SHA1 to match the registration hash
    $hashedpassword = sha1($password);
    
    include 'dbconnect.php';

    //Check for matching credentials
    $sqllogin = "SELECT * FROM `tbl_users` WHERE `email` = '$email' AND `password` = '$hashedpassword'";
    $result = $conn->query($sqllogin);

    if ($result->num_rows > 0) {
        // Success: Fetch user data
        $userdata = array();
        while ($row = $result->fetch_assoc()) {
            $userdata[] = $row;
        }
        $response = array('status' => 'success', 'message' => 'Login successful', 'data' => $userdata);
        sendJsonResponse($response);
    } else {
        // Failure: Invalid credentials
        $response = array('status' => 'failed', 'message' => 'Invalid email or password', 'data' => null);
        sendJsonResponse($response);
    }

} else {
    // Method not allowed
    $response = array('status' => 'failed', 'message' => 'Method Not Allowed');
    sendJsonResponse($response);
    exit();
}

// Helper function to return JSON headers
function sendJsonResponse($sentArray)
{
    header('Content-Type: application/json');
    echo json_encode($sentArray);
}
?>