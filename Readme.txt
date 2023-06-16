Run the following commands while you are in the directory where Dockerfile is placed.

sudo docker build -t basic_nginx .
sudo docker run -d -p 80:80  basic_nginx

