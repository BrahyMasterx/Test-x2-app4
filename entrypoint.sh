#!/usr/bin/env bash

# Define UUID and masquerade path, please modify it yourself. (Note: The masquerading path starts with / symbol, in order to avoid unnecessary trouble, please do not use special symbols.)
UUID=${UUID:-'db5b4014-d2da-11ed-afa1-0242ac120002'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
sed -i "s#UUID#$UUID#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g" config.json
sed -i "s#VLESS_WSPATH#${VLESS_WSPATH}#g" /etc/nginx/nginx.conf

# Set nginx masquerade station
rm -rf /usr/share/nginx/*
wget https://github.com/BrahyMasterx/Mktap/raw/main/mikutap.zip -O /usr/share/nginx/mikutap.zip
unzip -o "/usr/share/nginx/mikutap.zip" -d /usr/share/nginx/html
rm -f /usr/share/nginx/mikutap.zip

# Fake xray executable file
RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
mv xray ${RELEASE_RANDOMNESS}
cat config.json | base64 > config
rm -f config.json

# Enable Argo, and output node logs
cloudflared tunnel --url http://localhost:80 --no-autoupdate > argo.log 2>&1 &
sleep 5 && argo_url=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")

vllink=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$argo_url":443?encryption=none&security=tls&type=ws&host="$argo_url"&path="$VLESS_WSPATH"?ed=2048#Argo_xray_vless"

qrencode -o /usr/share/nginx/html/L$UUID.png $vllink

cat > /usr/share/nginx/html/$UUID.html<<-EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Argo-xray-paas</title>
    <style type="text/css">
        body {
            font-family: Geneva, Arial, Helvetica, san-serif;
        }

        div {
            margin: 0 auto;
            text-align: left;
            white-space: pre-wrap;
            word-break: break-all;
            max-width: 80%;
            margin-bottom: 10px;
        }
    </style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
    
    <div>
        <font color="#009900"><b>VLESS protocol link：</b></font>
    </div>
    <div>$vllink</div>
    <div>
        <font color="#009900"><b>VLESS protocol QR code：</b></font>
    </div>
    <div><img src="/L$UUID.png"></div>
    <div>
</body>
</html>
EOF

nginx
base64 -d config > config.json
./${RELEASE_RANDOMNESS} -config=config.json
