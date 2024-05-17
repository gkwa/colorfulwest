
##


https://www.elastic.co/guide/en/fleet/current/secure-connections.html

Elastic Agents require a PEM-formatted CA certificate to send encrypted data to Elasticsearch. If you followed the steps in Configure security for the Elastic Stack, your certificate will be in a p12 file. To convert it, use OpenSSL:

```yaml


    - name: Extract cert.crt from elastic-stack-ca.p12
      ansible.builtin.command: openssl pkcs12 -in /etc/elasticsearch/elastic-stack-ca.p12 -out /etc/elasticsearch/cert.crt -clcerts -nokeys -passin pass:MyPa55word
      args:
        creates: /etc/elasticsearch/cert.crt

    - name: Extract private.key from elastic-stack-ca.p12
      ansible.builtin.command: openssl pkcs12 -in /etc/elasticsearch/elastic-stack-ca.p12 -out /etc/elasticsearch/private.key -nocerts -nodes -passin pass:MyPa55word
      args:
        creates: /etc/elasticsearch/private.key




```



##

Caused by: org.elasticsearch.common.ssl.SslConfigException: cannot read configured [PKCS12] keystore (as a truststore) [/etc/elasticsearch/elastic-certificates.p12] - this is usually caused by an incorrect password; (a keystore password was provided)



- https://www.elastic.co/guide/en/elasticsearch/reference/master/security-basic-setup-https.html#encrypt-kibana-browser


```

PAGER=cat systemctl status elasticsearch
systemctl restart elasticsearch
journalctl -xeu elasticsearch.service
cat /var/log/elasticsearch/my_cluster.log


```

- https://www.elastic.co/guide/en/elasticsearch/reference/master/security-basic-setup.html#generate-certificates

- https://www.elastic.co/guide/en/elasticsearch/reference/7.11/starting-elasticsearch.html



```

echo MyPa55word >/tmp/o1
cat /tmp/o1 | /usr/share/elasticsearch/bin/elasticsearch-keystore add bootstrap.password --stdin --force
/usr/share/elasticsearch/bin/elasticsearch-keystore --help
/usr/share/elasticsearch/bin/elasticsearch-keystore list

```
