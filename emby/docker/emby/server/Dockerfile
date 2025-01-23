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