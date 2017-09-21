<?php
$uploaddir = '/var/www/uploads/';
$uploadfile = $uploaddir . basename($_FILES['userfile']['name']);
error_log('name:'.$_FILES['userfile']['name']);

if (is_uploaded_file($_FILES['userfile']['tmp_name'])) {
    if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)) {
        echo '{"result":true}';
    } else {
error_log("1");
        http_response_code(400);
        echo '{"result":false}';
    }
} else {
error_log("2:".$_FILES['userfile']['tmp_name']);
    http_response_code(400);
}



