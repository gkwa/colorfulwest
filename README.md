

Caused by: org.elasticsearch.common.ssl.SslConfigException: cannot read configured [PKCS12] keystore (as a truststore) [/etc/elasticsearch/elastic-certificates.p12] - this is usually caused by an incorrect password; (a keystore password was provided)



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
