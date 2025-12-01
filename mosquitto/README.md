# minimal-mosquitto

## Files you will need

`mosquitto.conf`:
```
# Listen on all interfaces
listener 1883 0.0.0.0
protocol mqtt

# log to console
log_dest stdout

# Always use authentication
allow_anonymous false
password_file /mqttpasswd
```

(initial) `mqttpasswd`:
```
user:secretpassword
```

## Usage

Hash passwords - this will assume `mqttpasswd` contains clear-text passwords only. Already hashed passwords will be **re-hashed**!  
`docker run --rm -v /tmp -v ./mqttpasswd:/mqttpasswd:rw --entrypoint /usr/bin/mosquitto_passwd alestrix/minimal-mosquitto:v2.0.21 -U /mqttpasswd`

Start mosquitto  
`docker run --rm -v ./mosquitto.conf:/mosquitto.conf:ro -v ./mqttpasswd:/mqttpasswd:ro alestrix/minimal-mosquitto:v2.0.21 -c /mosquitto.conf`

You might want to chmod and/or chown the files. See mosquitto output about what to do.

## Todo

- Dont copy full `/etc/passwd` and `/etc/group`, but only the mosquitto user/group
- Include default mosquitto.conf and mqttpasswd with some sane defaults
