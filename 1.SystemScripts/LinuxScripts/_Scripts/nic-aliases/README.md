Add a alias name to NIC's.
PLZ add this service to your systemctl service.

```bash
sudo vim /etc/systemd/system/nic-aliases.service
sudo systemctl daemon-reload
sudo systemctl enable --now nic-aliases.service
```

nic-aliases.service
```systemd
[Unit]
Description=Apply NIC aliases based on MAC addresses
After=network.target

[Service]
Type=oneshot
ExecStart=/path/of/nic-aliases.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
