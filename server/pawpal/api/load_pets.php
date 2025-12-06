<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include_once("dbconnect.php");

$userid = $_GET['user_id'];

// Fetch pets for specific user
$sqlload = "SELECT * FROM tbl_pets WHERE user_id = '$userid' ORDER BY created_at DESC";
$result = $conn->query($sqlload);

if ($result->num_rows > 0) {
    $pets = array();
    while ($row = $result->fetch_assoc()) {
        $pets[] = $row;
    }
    $response = array('status' => 'success', 'data' => $pets);
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