const http = require('http');

exports.helloPubSub = (data, context) => {
    const pubSubMessage = data;
    const name = pubSubMessage.data
        ? Buffer.from(pubSubMessage.data, 'base64').toString()
        : 'World';
    console.log(`Hello, ${name}`);

    let target_ip = process.env.TARGET_IP;

    console.log("Retrieving data from target address " + target_ip);

    http.get("http://" + target_ip + "/", (resp) => {
        let data = '';

        resp.on('data', (chunk) => {
            data += chunk;
        });

        resp.on('end', () => {
            console.log(data);
        });
    }).on('error', (err) => {
        console.log("Error: " + err.message);
    });
}