echo -n v
docker run --rm minimal-mosquitto -h | grep -Po '(?<=mosquitto version ).*'
