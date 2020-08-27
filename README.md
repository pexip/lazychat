# Lazy Chat application

This application makes use of websockets to make a simple chat application. The
application artificially injects errors and delays into chat communication to 
simulate issues that may occur in real-time communication.

## Running the application

The application has the following requirements
* Golang 1.14
* Docker
* Make

Once you have the requirements up and running, run the example using
the following commands.

    $ make docker-run

To use chat application, open http://localhost:8080/ in your browser.
