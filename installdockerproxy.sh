# verify root privileges

if [ "$(whoami)" != "root" ]; then
    echo "E: You are not root"
    exit
fi

# verify docker install

if [ "$(which docker)" != "/usr/bin/docker" ]; then
    echo "E: Docker is not installed"
    exit
fi

# verify nginx install

if [ "$(which nginx)" != "/usr/bin/nginx" ]; then
    echo "E: Nginx is not installed"
    exit
fi

# edit docker config

cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.old
rm /lib/systemd/system/docker.service
touch /lib/systemd/system/docker.service
echo "[Unit]" >> /lib/systemd/system/docker.service
echo "Description=Docker Application Container Engine" >> /lib/systemd/system/docker.service
echo "Documentation=https://docs.docker.com" >> /lib/systemd/system/docker.service
echo "After=network-online.target docker.socket firewalld.service" >> /lib/systemd/system/docker.service
echo "Wants=network-online.target" >> /lib/systemd/system/docker.service
echo "Requires=docker.socket" >> /lib/systemd/system/docker.service
echo "" >> /lib/systemd/system/docker.service
echo "[Service]" >> /lib/systemd/system/docker.service
echo "Type=notify" >> /lib/systemd/system/docker.service
echo "# the default is not to use systemd for cgroups because the delegate issues still" >> /lib/systemd/system/docker.service
echo "# exists and systemd currently does not support the cgroup feature set required" >> /lib/systemd/system/docker.service
echo "# for containers run by docker" >> /lib/systemd/system/docker.service
# Important line here
echo "ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:4243" >> /lib/systemd/system/docker.service
# end
echo "ExecReload=/bin/kill -s HUP $MAINPID" >> /lib/systemd/system/docker.service
echo "LimitNOFILE=1048576" >> /lib/systemd/system/docker.service
echo "# Having non-zero Limit*s causes performance problems due to accounting overhead" >> /lib/systemd/system/docker.service
echo "# in the kernel. We recommend using cgroups to do container-local accounting." >> /lib/systemd/system/docker.service
echo "LimitNPROC=infinity" >> /lib/systemd/system/docker.service
echo "LimitCORE=infinity" >> /lib/systemd/system/docker.service
echo "# Uncomment TasksMax if your systemd version supports it." >> /lib/systemd/system/docker.service
echo "# Only systemd 226 and above support this version." >> /lib/systemd/system/docker.service
echo "#TasksMax=infinity" >> /lib/systemd/system/docker.service
echo "TimeoutStartSec=0" >> /lib/systemd/system/docker.service
echo "# set delegate yes so that systemd does not reset the cgroups of docker containers" >> /lib/systemd/system/docker.service
echo "Delegate=yes" >> /lib/systemd/system/docker.service
echo "# kill only the docker process, not all processes in the cgroup" >> /lib/systemd/system/docker.service
echo "KillMode=process" >> /lib/systemd/system/docker.service
echo "# restart the docker process if it exits prematurely" >> /lib/systemd/system/docker.service
echo "Restart=on-failure" >> /lib/systemd/system/docker.service
echo "StartLimitBurst=3" >> /lib/systemd/system/docker.service
echo "StartLimitInterval=60s" >> /lib/systemd/system/docker.service
echo "" >> /lib/systemd/system/docker.service
echo "[Install]" >> /lib/systemd/system/docker.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/docker.service

systemctl daemon-reload
service docker restart

curl http://localhost:4243

# edit nginx config

rm /etc/nginx/site-enabled/default
touch /etc/nginx/site-enabled/default
echo "server {" >> /etc/nginx/site-enabled/default
echo "    listen 8042;" >> /etc/nginx/site-enabled/default
echo "    server_name _;" >> /etc/nginx/site-enabled/default
echo "    if (\$http_authorization != \"Bearer $AGENT_TOKEN\") { return 403; }" >> /etc/nginx/site-enabled/default
echo "    location / {" >> /etc/nginx/site-enabled/default
echo "        proxy_pass http://localhost:4243;" >> /etc/nginx/site-enabled/default
echo "        proxy_http_version 1.1;" >> /etc/nginx/site-enabled/default
echo "        proxy_set_header Upgrade $http_upgrade;" >> /etc/nginx/site-enabled/default
echo "        proxy_set_header Connection 'upgrade';" >> /etc/nginx/site-enabled/default
echo "        proxy_set_header Host $host;" >> /etc/nginx/site-enabled/default
echo "        proxy_cache_bypass $http_upgrade;" >> /etc/nginx/site-enabled/default
echo "    }" >> /etc/nginx/site-enabled/default
echo "}" >> /etc/nginx/site-enabled/default

nginx -t

service nginx restart

curl http://localhost:8042
