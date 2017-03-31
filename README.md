# Docker+Xorg(incl. openGL)+NVIDIA+CUDA+XPRA+VMD(incl. openGL+CUDA)

Requirements:

- Get a copy of VMD Molecular visualization tool from http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD, i used "LINUX_64 OpenGL, CUDA, OptiX, OSPRay (Linux (RHEL 6.7 and later) 64-bit Intel/AMD x86_64 SSE, with CUDA 8.x, OptiX, OSPRay)"

- You need a free TTY for mapping into the Docker Container

HowTo:

Copy vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz install file besides Dockerfile

Build your Docker Container:

```
docker build -t vmd-1-9-3 .
```

Run your Container with e.g. tty60 and third nvidia card:

```
docker run --device=/dev/nvidiactl --device=/dev/nvidia-uvm --device=/dev/nvidia7 --device=/dev/tty60 -p 10050:10050 -e XPRA_PASSWORD=Nextpass -e USERNAME=testing -h vmd-1-9-3 --name=vmd-1-9-3 vmd-1-9-3
```

possible vars:

XPRA_PASSWORD, xpra password, default testgeheim

USERNAME, username for running xpra in linux system, default testing

XPRAPORT, xpra port number, default 10050

SCREEN_RESOLUTION, Xorg Screen Resolution, default 4096x2160


You have to use a free tty where Xorg can run on. 

## Connect with Xpra Client 

```sh
XPRA_PASSWORD=Nextpass xpra attach ssl:HOSTNAME:10050 --ssl-server-verify-mode=none
```

The switch --ssl-server-verify-mode=none is necessary, because we used a self signed Cert.

On http://www.ks.uiuc.edu/Training/Tutorials/vmd/vmd-tutorial-files.tar.gz you can get some demo data sets. On http://www.ks.uiuc.edu/Training/Tutorials/vmd/vmd-tutorial.pdf you can read how to load the demo sets into VMD. 

Without an nvenc h264 encoder this app performs the best when choosing jpeg as encoding method!
