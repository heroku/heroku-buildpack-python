import pylibmc

try:
    mc = pylibmc.Client(["127.0.0.1"])
    mc["some_key"] = "Some value"

except pylibmc.ConnectionError:
    print("Could not connect")

