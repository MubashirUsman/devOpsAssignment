#base os
FROM ubuntu

#Update and install nginx 
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install nginx -y

#nginx will listen on port 80 for http
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
