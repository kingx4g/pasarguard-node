#!/bin/sh
set -e
DATA_DIR=/var/lib/pg-node
CERT_DIR=$DATA_DIR/certs
CERT=$CERT_DIR/ssl_cert.pem
KEY=$CERT_DIR/ssl_key.pem
KEY_FILE=$DATA_DIR/api_key.txt
mkdir -p "$CERT_DIR"

HOSTNAME_FOR_CERT="${RAILWAY_PRIVATE_DOMAIN:-node}"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo ">> ساخت گواهی SSL نود (CN/SAN = $HOSTNAME_FOR_CERT)..."
  cat > /tmp/node_ext.cnf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = ${HOSTNAME_FOR_CERT}
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${HOSTNAME_FOR_CERT}
EOF
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$KEY" -out "$CERT" \
    -config /tmp/node_ext.cnf -extensions v3_req 2>/dev/null
  rm -f /tmp/node_ext.cnf
fi

if [ -z "$API_KEY" ]; then
  if [ -f "$KEY_FILE" ]; then
    API_KEY=$(cat "$KEY_FILE")
  else
    API_KEY=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16)
    echo "$API_KEY" > "$KEY_FILE"
  fi
  export API_KEY
fi

echo "================================================================"
echo "Address : $HOSTNAME_FOR_CERT"
echo "Port    : $SERVICE_PORT"
echo "API Key : $API_KEY"
echo ""
echo "Certificate (پیست کن توی پنل):"
cat "$CERT"
echo "================================================================"

exec ./main
