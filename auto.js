let str = `server {
    listen 8042;
    server_name _;
    if ($http_authorization != "Bearer THISISATOKEN") { return 403; }
    location / {
        proxy_pass http://localhost:4243;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}`

let lines = str.split('\n')

lines.forEach(line => {
    console.log("echo \"" + line + "\" >> /lib/systemd/system/docker.service")
})
