import json
import subprocess
import base64
import plistlib
import requests


class NACServer:
    def __init__(self, binary="./server"):
        self.server = subprocess.Popen([binary], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=2, bufsize=0)
    
    def send(self, command):
        self.server.stdin.write(json.dumps(command).encode("utf-8") + b"\n")
        output = b""
        while True:
            c = self.server.stdout.read(1)
            if c == b"\n":
                break
            output += c
        return json.loads(output.decode("utf-8"))
    
    def load(self):
        resp = self.send({
            "command": "load"
        })

        if resp["status"] != "ok":
            raise Exception(resp["description"])

    def init(self, cert: bytes) -> bytes:
        resp = self.send({
            "command": "init",
            "cert": base64.b64encode(cert).decode()
        })

        if resp["status"] != "ok":
            raise Exception(resp["description"])
        
        self.context = resp["context"]

        return base64.b64decode(resp["request"])
    
    def submit(self, response: bytes):
        resp = self.send({
            "command": "submit",
            "context": self.context,
            "response": base64.b64encode(response).decode()
        })

        if resp["status"] != "ok":
            raise Exception(resp["description"])
        
    def generate(self) -> bytes:
        resp = self.send({
            "command": "generate",
            "context": self.context
        })

        if resp["status"] != "ok":
            raise Exception(resp["description"])
        
        return base64.b64decode(resp["validation"])
        
        

def get_cert():
    resp = requests.get("http://static.ess.apple.com/identity/validation/cert-1.0.plist")
    resp = plistlib.loads(resp.content)
    return resp["cert"]

def get_session_info(req: bytes) -> bytes:
    body = {
        'session-info-request': req,
    }
    body = plistlib.dumps(body)
    resp = requests.post("https://identity.ess.apple.com/WebObjects/TDIdentityService.woa/wa/initializeValidation", data=body, verify=False)
    resp = plistlib.loads(resp.content)
    return resp["session-info"]

def build():
    # Get data.plist ?
    # check if data.plist exists
    # if not, download it
    import os
    if not os.path.exists("data.plist"):
        print("DID NOT FIND data.plist")
        print("You can ask @JJTech for a testing one")
        print("Or, if this is macOS on a non-m1 machine, you can try to run build_extractor.sh to generate it")
    # Run stubber
    subprocess.run(["python3", "stubber.py"])
    # Compile
    subprocess.run(["bash", "build.sh"])

if __name__ == "__main__":
    print("Building...")
    build()
    print("Done building")
    server = NACServer()
    server.load() # Technically unnecessary because init will load if not loaded
    req = server.init(get_cert())
    server.submit(get_session_info(req))
    print(base64.b64encode(server.generate()).decode())
