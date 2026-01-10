<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

$userid = $_POST['user_id'];
$petid = $_POST['pet_id'];
$message = addslashes($_POST['message']); // Capture the message

// Insert the message into the database
$sql = "INSERT INTO tbl_adoptions (user_id, pet_id, status, message) VALUES ('$userid', '$petid', 'Pending', '$message')";

if ($conn->query($sql) === TRUE) {
    echo json_encode(array("status" => "success", "data" => null));
} else {
    echo json_encode(array("status" => "failed", "data" => null));
}
?>