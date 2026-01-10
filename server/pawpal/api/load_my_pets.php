<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

$userid = $_GET['user_id'];

// Select pets uploaded by this specific user
$sql = "SELECT * FROM tbl_pets WHERE user_id = '$userid' ORDER BY created_at DESC";

$result = $conn->query($sql);

$rows = array();
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    echo json_encode(array("status" => "success", "data" => $rows));
} else {
    echo json_encode(array("status" => "failed", "data" => null));
}
?>