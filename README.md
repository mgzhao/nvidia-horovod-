# Script to run Resnet Distributed Training using Nvidia NGC TF container on AWS instance #

#### Prepration ####

Copy the private key to EFS folder and copy the Imagenet Training data to EFS

Launch multiple EC2 P3 or G4dn instances together and place them in the same placement group.

#### on AWS EC2 Instance (P3 or G4dn) ####

SSH into each instance

```
mkdir efs
cd efs
sudo chmod go+rw .				 
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-68a047c0.efs.us-west-2.amazonaws.com:/  ~/efs
cp ~/efs/ssh/id_rsa ~/.ssh/
cd ~/
mkdir horovod-docker
cp ~/efs/ssh/* ~/horovod-docker/
wget -O horovod-docker/Dockerfile https://raw.githubusercontent.com/mgzhao/nvidia-horovod-/master/Dockerfile

docker build -t tf-horovod:latest horovod-docker
```

#### Running docker image on each EC2 instance ####

```
docker run --gpus all -it --name=tf-horovod --privileged --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 --network=host -v /home/ubuntu/efs/:/data  tf-horovod:latest
```

#### Open SSH server on each 2-n EC2 instance ####

```
/usr/sbin/sshd -p 12345; sleep infinity	
```

Then Use Ctrl-D to exit docker console

#### on master (1st) EC2 instance ####

Test single node
```
python /workspace/nvidia-examples/cnn/resnet.py --layers=50 --data_dir=/data --precision=fp16 --log_dir=/output/resnet50
```

Run training on multiple node (in example, n=4)
```
mpirun -np 4 \
    -H n1:1,n2:1,n3:1,n4:1 \
	-mca plm_rsh_args "-p 12345" \
	--allow-run-as-root \
    python /workspace/nvidia-examples/cnn/resnet.py --layers=50 --data_dir=/data --precision=fp16 --log_dir=/output/resnet50
```


