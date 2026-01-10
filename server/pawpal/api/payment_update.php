<?php
// Suppress error reporting to prevent raw PHP errors from breaking the HTML output or JSON response
error_reporting(0);

include_once("dbconnect.php");

// Retrieve the Order ID (Donation ID) passed via the URL parameters
$orderid = $_GET['orderid']; 

// 1. DETERMINE REQUEST SOURCE (Browser Redirect vs. Background Callback)
// Billplz sends data via GET when redirecting the user, and via POST for background webhooks.
$paidstatus = null;
$billplz_id = null;

if (isset($_GET['billplz']['paid'])) {
    // Case A: User is redirected back to the app via Browser (GET request)
    $paidstatus = $_GET['billplz']['paid'];
    $billplz_id = $_GET['billplz']['id'];
} else if (isset($_POST['billplz']['paid'])) {
    // Case B: Billplz server calls this script in the background (POST request)
    $paidstatus = $_POST['billplz']['paid'];
    $billplz_id = $_POST['billplz']['id'];
}

// 2. FETCH CURRENT DONATION DETAILS
// We retrieve the existing record to populate the receipt, regardless of payment status.
$receipt_id = $orderid;
$amount = "0.00"; 
$type = "Donation";
$date = date("d/m/Y H:i:s");

$sql_get = "SELECT * FROM tbl_donations WHERE donation_id = '$orderid'";
$result = $conn->query($sql_get);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $amount = $row['amount'];
    $description = $row['description'];
    $type = $row['donation_type'];
}

// 3. UPDATE DATABASE STATUS
// Default visual variables for the receipt
$status_msg = "Pending";
$color = "grey";
$icon = "?";

if ($paidstatus === "true") {
    // Payment Successful
    $status_msg = "Success";
    $color = "green";
    $icon = "✓";
    $sql_update = "UPDATE tbl_donations SET payment_status = 'Success' WHERE donation_id = '$orderid'";
    $conn->query($sql_update);
} else if ($paidstatus === "false") {
    // Payment Failed
    $status_msg = "Failed";
    $color = "red";
    $icon = "✗";
    $sql_update = "UPDATE tbl_donations SET payment_status = 'Failed' WHERE donation_id = '$orderid'";
    $conn->query($sql_update);
} else {
    // No status received (User might have refreshed the receipt page)
    // Fallback: Check what is currently saved in the database
    if(isset($row['payment_status'])){
        $status_msg = $row['payment_status'];
        if($status_msg == "Success") { $color="green"; $icon="✓"; }
        else if($status_msg == "Failed") { $color="red"; $icon="✗"; }
    }
}

// 4. STOP EXECUTION IF CALLBACK
// If this request came from Billplz's background webhook (POST), we stop here.
// The background process does not need to see the HTML receipt.
if (isset($_POST['billplz']['paid'])) {
    exit(); 
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
    <title>Payment Receipt</title>
    <style>
        body { padding: 20px; font-family: Arial, sans-serif; background-color: #f4f4f4; }
        .receipt { 
            max-width: 500px; 
            margin: 20px auto; 
            background: white; 
            padding: 20px; 
            box-shadow: 0 4px 8px rgba(0,0,0,0.1); 
            border-radius: 10px;
        }
        .status-header { 
            /* Dynamically set color based on PHP $color variable */
            background: <?php echo ($color == 'green') ? '#4CAF50' : (($color == 'red') ? '#f44336' : '#9e9e9e'); ?>; 
            color: white; 
            padding: 15px; 
            text-align: center; 
            border-radius: 5px; 
            margin-bottom: 20px;
            font-size: 1.2em;
        }
        .btn-close {
            display: block;
            width: 100%;
            padding: 12px;
            background: #2196F3;
            color: white;
            text-align: center;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
            font-weight: bold;
        }
    </style>
</head>
<body>

    <div class="receipt">
        <center>
            <h3>PawPal Donation</h3>
            <p>Thank you for your support!</p>
        </center>

        <div class="status-header">
            <?php echo $icon . " Payment " . $status_msg; ?>
        </div>

        <table class="w3-table w3-striped w3-bordered">
            <tr><td><b>Receipt ID</b></td><td><?php echo $billplz_id ?? '-'; ?></td></tr>
            <tr><td><b>Donation ID</b></td><td>#<?php echo $receipt_id; ?></td></tr>
            <tr><td><b>Donation Type</b></td><td><?php echo $type; ?></td></tr>
            <tr><td><b>Date</b></td><td><?php echo $date; ?></td></tr>
            <tr><td><b>Amount</b></td><td>RM <?php echo number_format($amount, 2); ?></td></tr>
            <tr>
                <td><b>Status</b></td>
                <td class="w3-text-<?php echo $color; ?>"><b><?php echo $status_msg; ?></b></td>
            </tr>
        </table>

        <br>
        <p style="text-align:center; font-size:12px; color:grey;">
            You can now close this window and return to the app.
        </p>
        
        <a href="#" onclick="window.close()" class="btn-close">Close / Return to App</a>
    </div>

</body>
</html>