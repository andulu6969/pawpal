<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

$userid = $_GET['user_id'];

// JOIN tbl_pets to get the pet_name for display
$sql = "SELECT tbl_donations.*, tbl_pets.pet_name 
        FROM tbl_donations 
        LEFT JOIN tbl_pets ON tbl_donations.pet_id = tbl_pets.pet_id 
        WHERE tbl_donations.user_id = '$userid' 
        ORDER BY tbl_donations.donation_date DESC";

$result = $conn->query($sql);

$rows = array();
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
}
echo json_encode(array("status" => "success", "data" => $rows));
?>