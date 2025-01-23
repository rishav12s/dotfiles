

# Emby Premiere ByPass Docker container

> :exclamation:
> All the information provided on this tutorial are for educational purposes only. I'm not responsible for any misuse of this information. **If you like the app buy it**

## Table of Contents
- [Compatibility](#compatibility)
- [Getting Started](#getting-started)
  * [Local client bypass](#1-local-client-bypass)
    + [Folder structure](#folder-structure)
    + [Steps](#steps)
  * [Web client bypass](#2-web-client-bypass)
    + [Folder structure](#folder-structure-1)
    + [Steps](#steps-1)
  * [Docker compose setup](#3-docker-compose-setup)
    + [Folder structure](#folder-structure-2)
    + [Steps](#steps-2)
  * [First Run](#first-run)
- [Apps](#apps)
    + [Emby Theater](#emby-theater)
    + [Android](#android)
    + [Android TV](#android-tv)
- [Miscellaneous](#miscellaneous)
    + [Update Emby version](#update-emby-version)
- [Credits](#credits)

## Compatibility  
> Tested on version 4.9.0.28. Last update: September 13, 2024
> 
This tutorial allows you to run Emby Premiere on:

| Emby Premiere | Local device | Remote device |
|:-------------:|:------------:|:-------------:|
|      Web      |       ✔️*       |       ✔️       |
|     Mobile    |       ✔️      |       ❌       |
|   Emby Theater|       ✔️ [?](#emby-theater)      |       ❌       |
| Other devices |       ❓      |       ❌       |


\* The use of DoH may cause cosmetic issues

## Getting Started

Create the working folder

```Shell
mkdir -p emby/{mb3admin,server}
cd emby
```

### 1. Local client bypass

#### Folder structure
```
.
└── mb3admin
    ├── certs
    │   ├── emby.crt
    │   ├── emby.key
    │   └── ssl-dhparams.pem
    ├── Dockerfile
    └── nginx.conf
```
#### Steps

1. Change working directory

```Shell
mkdir certs
```

2. Create certs folder

```Shell
mkdir certs
```

3. Generate a self-signed certificate for the fake mb3admin.com server to use:
```Shell
openssl req -x509 -newkey rsa:2048 -days 36525 -nodes -subj '/CN=mb3admin.com' -addext "subjectAltName = DNS:www.mb3admin.com, DNS:mb3admin.com"  -out certs/emby.crt -keyout certs/emby.key
```

4. Download `ssl-dhparams.pem`

```Shell
curl https://ssl-config.mozilla.org/ffdhe2048.txt > certs/ssl-dhparams.pem
```

5. Create `nginx.conf` file

```Nginx
events {
  worker_connections  4096;  ## Default: 1024
}

http{

	server {
	    listen 80;
	    listen [::]:80;
	    server_name mb3admin.com;
	    return 301 https://mb3admin.com$request_uri;
	}

	server {
	    listen 443 ssl http2;
	    listen [::]:443 ssl http2;
	    server_name mb3admin.com;

	    ssl_certificate /certs/emby.crt;
	    ssl_certificate_key /certs/emby.key;
	    ssl_session_timeout 1d;
	    ssl_session_cache shared:SSL:10m;  # about 40000 sessions
	    ssl_session_tickets off;

	    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam.pem
	    ssl_dhparam /certs/ssl-dhparams.pem;

	    # intermediate configuration
	    ssl_protocols TLSv1.2 TLSv1.3;
	    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
	    ssl_prefer_server_ciphers off;

	    location / {
		resolver 8.8.8.8 ipv6=off;
		set $target https://mb3admin.com;
		proxy_pass $target;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	    }

	    location /admin/service/registration/validateDevice{
		default_type application/json;
		return 200 '{"cacheExpirationDays":3650,"message":"Device Valid (limit not checked)","resultCode":"GOOD"}';
	    }

	    location /admin/service/registration/validate {
		default_type application/json;
		return 200 '{"featId":"","registered":true,"expDate":"2099-01-01","key":""}';
	    }

	    location /admin/service/registration/getStatus {
		default_type application/json;
		return 200 '{"planType":"Lifetime","deviceStatus":0,"subscriptions":[]}';
	    }

	    location /admin/service/appstore/register {
		default_type application/json;
		return 200 '{"featId":"","registered":true,"expDate":"2099-01-01","key":""}';
	    }

	    location /emby/Plugins/SecurityInfo {
		default_type application/json;
		return 200 '{SupporterKey:"", IsMBSupporter:true}';
	    }

	    add_header Access-Control-Allow-Origin * always;
	    add_header Access-Control-Allow-Headers * always;
	    add_header Access-Control-Allow-Method * always;
	    add_header Access-Control-Allow-Credentials true always;
	}
}
```
6. Create `Dockerfile` file

```Dockerfile
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
ADD certs /certs
```
### 2. Web client bypass

#### Folder structure
```
.
└── server
    ├── Dockerfile
    └── patch
        ├── emby.crt
        ├── ilasm
        └── ildasm
```
#### Steps
1. Change working directory

```Shell
cd server
```

2. Create `patch` folder
```Shell
mkdir patch
```

3. Copy `emby.crt` from `../mb3admin/certs` to `patch` folder
```Shell
cp ../mb3admin/certs/emby.crt patch
```
4. Download `ilasm` and `ildasm` **for your architecture** and copy in `patch` folder. 
> You can get it here for x86_64 architecture :  [ilasm](https://raw.githubusercontent.com/acxcx/docker-emby/beta/patch/ilasm) [ildasm](https://raw.githubusercontent.com/acxcx/docker-emby/beta/patch/ildasm) 

> You can get it here for arm64(Raspberry Pi 4) architecture. Just double click the binary file inside `runtimes/linux-arm64/native` and it will automatically download
:  [ilasm](https://nuget.info/packages/runtime.linux-arm64.Microsoft.NETCore.ILAsm/8.0.0) [ildasm](https://nuget.info/packages/runtime.linux-arm64.Microsoft.NETCore.ILDAsm/8.0.0) 

> You can get it here for arm(Raspberry Pi <3) architecture. Just double click the binary file inside `runtimes/linux-arm/native` and it will automatically download
:  [ilasm](https://nuget.info/packages/runtime.linux-arm.Microsoft.NETCore.ILAsm/8.0.0) [ildasm](https://nuget.info/packages/runtime.linux-arm.Microsoft.NETCore.ILDAsm/8.0.0) 


> Or you can download the [deb package](https://packages.debian.org/sid/all/mono-devel/download). You should unpack the `.deb` and find the executables in `./usr/bin/`
5. Create `Dockerfile` file
```Dockerfile
FROM linuxserver/emby:beta

ADD patch /patch

RUN chmod +x /patch/ilasm
RUN chmod +x /patch/ildasm
RUN mkdir /patch/tmp

WORKDIR /patch/tmp

RUN /patch/ildasm /app/emby/system/Emby.Web.dll -out=Emby.Web.dll

RUN sed -i 's#ajax({url:"https://mb3admin.com/admin/service/registration/validateDevice?"+new URLSearchParams(params).toString(),type:"POST",dataType:"json"})#Promise.resolve(new Response('"'"'{"cacheExpirationDays":365,"message":"Device Valid","resultCode":"GOOD"}'"'"').json())#g' Emby.Web.dashboard_ui.modules.emby_apiclient.connectionmanager.js

RUN /patch/ilasm -dll Emby.Web.dll -out=/app/emby/system/Emby.Web.dll
RUN cat /patch/emby.crt >> /app/emby/etc/ssl/certs/ca-certificates.crt

```

### 3. Docker Compose setup
#### Folder structure
```
.
├── compose.yml
├── mb3admin
│   ├── certs
│   │   ├── emby.crt
│   │   ├── emby.key
│   │   └── ssl-dhparams.pem
│   ├── Dockerfile
│   └── nginx.conf
└── server
    ├── Dockerfile
    └── patch
        ├── emby.crt
        ├── ilasm
        └── ildasm
```
#### Steps
> :warning:
> It is mandatory that the server where the Emby server is running has a DNS configured that resolves ``mb3admin.com`` to the local IP of the nginx server.


1. Now, you have to options:

   a. **Recommended**: Edit your local DNS (Pihole, Adguard, router, bind...) and rewrite ``mb3admin.com`` with local IP. 
   
	![image](https://gist.github.com/user-attachments/assets/e1b9a115-9ff5-4392-8ba4-dc79a6ec110e)

   
   b. Edit the hosts file of **each device you're going to use Emby**.

	- **Windows:** ``C:\Windows\System32\drivers\etc\hosts``
	- **Linux:** ``/etc/hosts``

	```
	<your_local_ip_adress_here> mb3admin.com
	```
	
	:warning: Replace `<your_local_ip_adress_here>` with the IP of machine where the containers run.


3. Create `compose.yml`

```yaml
services:
  emby:
      build: ./server
      container_name: emby
      environment:
        - PUID=1000
        - PGID=1000
        - TZ=Europe/London
      volumes:
        - ./config:/config
        - /media/tv:/data/tvshows
        - /media/movies:/data/movies
      ports:
        - 8096:8096
        - 8920:8920 #optional
      restart: unless-stopped
  mb3admin:
      build: ./mb3admin
      container_name: mb3admin
      ports:
        - 443:443
      restart: unless-stopped
      networks:
        default:
          aliases:
            - mb3admin.com
```

3. Start containers 
```Shell
docker compose up -d
```

4. Check if everything is OK

Execute

``` 
docker exec emby bash -c "curl -w '\n' -s  --cacert /app/emby/etc/ssl/certs/ca-certificates.crt  https://mb3admin.com/admin/service/registration/validateDevice"
```
If the output is as follows everything is fine 

```
{"cacheExpirationDays":3650,"message":"Device Valid (limit not checked)","resultCode":"GOOD"}
```

## First Run

1. Open https://mb3admin.com in your browser and accept the self-signed certificate

![image](https://gist.github.com/user-attachments/assets/073ce461-a58b-44ba-977e-76cd6a8b14c8)


2. Open the Emby Premiere Section in Settings, and write whatever you want in the "Emby Premiere key (paste from e-mail)" and click "Save"

![image](https://gist.github.com/user-attachments/assets/584b96b6-5745-43d0-ac18-b6cbec523e41)


## Apps
> :warning: You **MUST** do the above steps for this to work

### Emby Theater

1. Go to 
- **Windows:** `%appdata%\Emby-Theater\system\electronapp`
- **Linux:** `/opt/emby-theater/electron/resources/app/`
2. Open `main.js` with text editor
3. After this
```Javascript
app.on('window-all-closed', function () {
    // On OS X it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    if (process.platform != 'darwin') {
        app.quit();
    }
});
```
Add this:
```Javascript
app.on('certificate-error', (event, webContents, url, error, certificate, callback) => {
        event.preventDefault()
        callback(true)
})
```

### Android

You **DON'T NEED TO DO** any extra steps to make it work on Android on <ins>local network</ins>. First time you open the app it will prompt a dialog to accept self-signed certificate. If this dialog does not appear you have done something wrong.

![Dialog](https://i.imgur.com/71b3D3n.jpg)

If you want it to work outside the local network, you need to get a modded apk

### Android TV

You must go to the settings and enable "Allow Untrusted SSL Playback"

![image](https://gist.github.com/user-attachments/assets/29d265d5-6f6d-4527-ab45-a25c83b2a207)

Thanks @OrpheeGT for the information

## Miscellaneous

### Update Emby version
1. Change to the folder where the `compose.yml` file is
2. Build a new emby image
```Shell
docker compose build emby --pull --no-cache
```
3.  Restart container
```Shell
docker compose up -d
```


## Credits
- https://gist.github.com/all3kcis/66909ed95755146a6969b32f21171642
- https://mosarin.tech/archives/75/
- https://github.com/acxcx/docker-emby

### Special thanks for helping me improve this information to:
- @potatoru 
- @orangejuice 
- @OrpheeGT
- @senhan07