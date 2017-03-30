# Docker+Xorg(incl. openGL)+NVIDIA+XPRA+MESHLAB 2016.12

Attention: Do not start this on your Host with running Xorg. 

Build with 

docker build -t meshlab-2016 .

and run e.g.
```sh
docker run --device=/dev/nvidiactl --device=/dev/nvidia-uvm --device=/dev/nvidia7 --device=/dev/tty60 -p 10050:10050 -e XPRA_PASSWORD=Nextpass -e USERNAME=testing -h meshlab-2016 --name=meshlab-2016 meshlab-2016
```
possible vars:

XPRA_PASSWORD, xpra password, default testgeheim

USERNAME, username for running xpra in linux system, default testing

XPRAPORT, xpra port number, default 10050

SCREEN_RESOLUTION, Xorg Screen Resolution, default 4096x2160


You have to use a free tty where Xorg can run on. 

Connect with Xpra Client 

```sh
XPRA_PASSWORD=Nextpass xpra attach ssl:HOSTNAME:10050 --ssl-server-verify-mode=none
```

The switch --ssl-server-verify-mode=none is necessary, because we used a self signed Cert.
