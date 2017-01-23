# FB events
Get list of Facebook events that your friends are planning to attend or they are interested in.

## Installation
```
git clone https://github.com/janzikan/fb-events
cd fb-events
bundle
```

## Facebook acount
In order to be able to get data from Facebook you need an account. Rename **.env.example** file to **.env** and modify the file so it would contain real FB account login credentials.

## Usage
Simply use the following command
```
bin/scrape
```

This will generate file `events.html` containing the list of events.
