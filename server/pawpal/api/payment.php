<?php
header("Access-Control-Allow-Origin: *");
error_reporting(0); // Suppress warnings for clean output

//Capture Data passed from Flutter
$email = $_GET['email'];
$mobile = $_GET['mobile']; 
$name = $_GET['name']; 
$amount = $_GET['amount']; 
$orderid = $_GET['orderid'];

//Billplz API Configuration
$api_key = '8a379b06-e10e-4177-93c1-2c61502498d5'; 
$collection_id = 'uhsjlhnv'; 
$host = 'https://www.billplz-sandbox.com/api/v3/bills';

//Prepare Payload
$data = array(
          'collection_id' => $collection_id,
          'email' => $email,
          'mobile' => $mobile,
          'name' => $name,
          'amount' => $amount * 100, // Amount must be in cents (e.g., RM10.00 -> 1000)
          'description' => 'Payment for Donation ID: '.$orderid,
          // Define callback URLs for updates
          'callback_url' => "https://canorcannot.com/Andrew/pawpal/api/payment_update.php?orderid=$orderid",
          'redirect_url' => "https://canorcannot.com/Andrew/pawpal/api/payment_update.php?orderid=$orderid" 
);

//Execute cURL Request to Billplz
$process = curl_init($host);
curl_setopt($process, CURLOPT_HEADER, 0);
curl_setopt($process, CURLOPT_USERPWD, $api_key . ":");
curl_setopt($process, CURLOPT_TIMEOUT, 30);
curl_setopt($process, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($process, CURLOPT_SSL_VERIFYHOST, 0);
curl_setopt($process, CURLOPT_SSL_VERIFYPEER, 0);
curl_setopt($process, CURLOPT_POSTFIELDS, http_build_query($data)); 

$return = curl_exec($process);
curl_close($process);

//Decode Response and Redirect User to Payment Page
$bill = json_decode($return, true);
header("Location: {$bill['url']}");
?>