#!/bin/bash

set -e

elasticsearch_config_path=/etc/elasticsearch/elasticsearch.yml
elasticsearch_config_backup_path=/etc/elasticsearch/elasticsearch.yml.bak
cluster_name=my_cluster
log_path=/var/log/elasticsearch/${cluster_name}.log
master_nodes=()

echo "Log path is ${log_path}"

hostname=$(hostname)
master_nodes+=("${hostname}")

if [ ! -f "${elasticsearch_config_backup_path}" ]; then
 cp "${elasticsearch_config_path}" "${elasticsearch_config_backup_path}"
fi

rm -f /etc/elasticsearch/elastic-stack-ca.p12
rm -f /etc/elasticsearch/elastic-certificates.p12

/usr/share/elasticsearch/bin/elasticsearch-certutil ca \
  --out /etc/elasticsearch/elastic-stack-ca.p12 \
  --pass MyPa55word

chmod 0400 /etc/elasticsearch/elastic-stack-ca.p12
chown elasticsearch:elasticsearch /etc/elasticsearch/elastic-stack-ca.p12

if [ ! -f /etc/elasticsearch/elastic-stack-ca.p12 ]; then
 echo "The elastic-stack-ca.p12 file does not exist."
 exit 1
fi

if ! command -v nearwash >/dev/null; then
   pip install git+https://github.com/gkwa/nearwash.git
fi

ip=$(nearwash search)
/usr/share/elasticsearch/bin/elasticsearch-certutil cert \
  --ca-pass MyPa55word \
  --pass MyPa55word \
  --out /etc/elasticsearch/elastic-certificates.p12 \
  --ca /etc/elasticsearch/elastic-stack-ca.p12 \
  --dns "$(hostname)" \
  --ip "${ip}"

chmod 0400 /etc/elasticsearch/elastic-certificates.p12
chown elasticsearch:elasticsearch /etc/elasticsearch/elastic-certificates.p12

if [ ! -f /etc/elasticsearch/elastic-certificates.p12 ]; then
 echo "The /etc/elasticsearch/elastic-certificates.p12 file does not exist."
 exit 1
fi

systemctl enable elasticsearch

mkdir -p /opt/colorfulwest/
chmod 0700 /opt/colorfulwest/

cat > /opt/colorfulwest/clean.sh <<'EOF'
#!/bin/bash

set -x
set -u
set -e

keystore_entries=$(/usr/share/elasticsearch/bin/elasticsearch-keystore list)

for entry in $keystore_entries; do
 if [ "$entry" != "keystore.seed" ]; then
   /usr/share/elasticsearch/bin/elasticsearch-keystore remove "$entry"
   echo "Removed $entry from elasticsearch-keystore"
 else
   echo "Skipped $entry"
 fi
done

echo remaining variables:
/usr/share/elasticsearch/bin/elasticsearch-keystore list
EOF

chmod 0755 /opt/colorfulwest/clean.sh

echo "MyPa55word" > /opt/colorfulwest/secret.txt
chmod 0777 /opt/colorfulwest/secret.txt

cat > /opt/colorfulwest/create.sh <<'EOF'
#!/bin/bash

set -x
set -u
set -e

variables=(
 xpack.security.http.ssl.truststore.secure_password
 xpack.security.http.ssl.keystore.secure_password
 xpack.security.transport.ssl.keystore.secure_password
 xpack.security.transport.ssl.truststore.secure_password
)

for variable in "${variables[@]}"; do
 /usr/share/elasticsearch/bin/elasticsearch-keystore remove "$variable" 2>/dev/null || {
   exit_code=$?
   if [ $exit_code -ne 78 ]; then
     exit $exit_code
   fi
 }

 /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin "$variable" </opt/colorfulwest/secret.txt
 echo "Added $variable to elasticsearch-keystore"
done

echo current set of variables:
/usr/share/elasticsearch/bin/elasticsearch-keystore list
EOF

chmod 0755 /opt/colorfulwest/create.sh

bash -xe /opt/colorfulwest/clean.sh
bash -xe /opt/colorfulwest/create.sh

cat > "${elasticsearch_config_path}" <<EOF
cluster.name: "${cluster_name}"
node.name: "$(hostname)"
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
 enabled: true
 keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/elastic-certificates.p12
cluster.initial_master_nodes: ["${master_nodes[@]}"]
http.host: 0.0.0.0
EOF

systemctl restart elasticsearch

/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto --batch | tee out.txt

cat out.txt
