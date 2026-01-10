<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

$petid = $_POST['pet_id'];

// Delete the pet record
$sql = "DELETE FROM tbl_pets WHERE pet_id = '$petid'";

if ($conn->query($sql) === TRUE) {
    echo json_encode(array("status" => "success", "data" => null));
} else {
    echo json_encode(array("status" => "failed", "data" => null));
}
?>