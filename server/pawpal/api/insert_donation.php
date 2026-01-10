<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

// Check required data
if (!isset($_POST['user_id']) || !isset($_POST['type']) || !isset($_POST['pet_id'])) {
    echo json_encode(array("status" => "failed", "message" => "Missing data"));
    exit();
}

$userid = $_POST['user_id'];
$petid = $_POST['pet_id']; 
$type = $_POST['type'];             
$amount = $_POST['amount'];         
$description = $_POST['description']; 

// Insert with pet_id
$sql = "INSERT INTO tbl_donations (user_id, pet_id, donation_type, amount, description, payment_status, donation_date) 
        VALUES ('$userid', '$petid', '$type', '$amount', '$description', 'Pending', NOW())";

if ($conn->query($sql) === TRUE) {
    $last_id = $conn->insert_id;
    echo json_encode(array("status" => "success", "id" => $last_id));
} else {
    echo json_encode(array("status" => "failed", "message" => "SQL Error: " . $conn->error));
}
?>