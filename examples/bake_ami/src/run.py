import http.server
import  socketserver

DIRECTORY = "./"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)


with socketserver.TCPServer(("", 8000), Handler) as httpd:
    httpd.serve_forever()

