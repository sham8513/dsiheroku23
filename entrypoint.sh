#!/bin/sh

#Config xray

rm -rf /etc/xray/config.json
cat << EOF > /etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "1.1.1.1"
    ],
    "queryStrategy": "UseIPv4"
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "1.1.1.1"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-direct"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": "2001",
            "xver": 0
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.3",
          "cipherSuites": "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
          "alpn": [
            "h2",
            "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        }
      }
    },
    {
      "port": 2001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "grpc"
        }
      }
    },
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "video/mpeg",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": [
                  "chunked"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }
            }
          }
        },
        "security": "none"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      },
      "tag": "block"
    }
  ]
}
EOF

#run xray

xray -c /etc/xray/config.json
