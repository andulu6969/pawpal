<?php
header("Access-Control-Allow-Origin: *");
include_once("dbconnect.php");

// Capture search query and filter type from URL parameters (GET)
$search = isset($_GET['search']) ? $_GET['search'] : "";
$type = isset($_GET['type']) ? $_GET['type'] : "All";

// SQL Query: JOIN tbl_pets with tbl_users to retrieve the owner's name
$sql = "SELECT tbl_pets.*, tbl_users.name as owner_name 
        FROM tbl_pets 
        JOIN tbl_users ON tbl_pets.user_id = tbl_users.user_id 
        WHERE pet_name LIKE '%$search%'";

// Apply category filter if specific type is selected
if ($type != "All") {
    $sql .= " AND pet_type = '$type'";
}

// Order by newest posts first
$sql .= " ORDER BY created_at DESC";

$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $pets = array();
    while ($row = $result->fetch_assoc()) {
        $pets[] = $row;
    }
    // Return data in JSON format
    echo json_encode(array("status" => "success", "data" => $pets));
} else {
    echo json_encode(array("status" => "failed", "data" => null));
}
?>