# Apigee Emulator – Simple Guide

## What is it?
The Apigee Emulator is Apigee's gateway running locally in one Docker container.
You write proxies as XML files, deploy them to the emulator, and call them with curl/Postman.
There is no web dashboard – VS Code (Cloud Code extension) and the files are the UI.

## Where does it run?
- Machine: Linux Mint, `192.168.1.16`
- Container name: `apigee-emulator`
- Image: `gcr.io/apigee-release/hybrid/apigee-emulator:2.0.1`
- Ports:
  - `8080` – control port (deploy, status)
  - `8998` – traffic port (call your APIs here)
- Options: privileged, DNS 8.8.8.8, no auto-restart

## Where is the code?
Project folder: `~/labs/myapigeeproxy`

```
emulator.sh                 start / stop / status / deploy
deploy.sh                   sends the code to the emulator
src/main/apigee/
  apiproxies/hello/apiproxy/
    hello.xml               proxy name
    proxies/default.xml     URL path (/hello) and which policies run
    policies/AM-Hello.xml   the policy (returns a JSON message)
  environments/dev/
    deployments.json        list of proxies to deploy: {"proxies":["hello"]}
  sharedflows/              (empty for now)
```

## Daily commands
```bash
cd ~/labs/myapigeeproxy
./emulator.sh start     # start emulator + deploy all proxies (~30 s)
./emulator.sh status    # is it up, what is deployed
./emulator.sh deploy    # redeploy after you change XML
./emulator.sh stop      # stop emulator
```

## Test
```bash
curl http://localhost:8998/hello
# {"message":"hello from Apigee emulator","path":"","verb":"GET"}
```
From the Windows laptop: VS Code → **Ports** tab → forward `8998` → open `http://localhost:8998/hello`.

## Make a change
1. Edit an XML file under `src/main/apigee`.
2. Run `./emulator.sh deploy`.
3. Test with curl.

## Add a new proxy
1. VS Code → APIGEE view → `apiproxies` → **+** (or copy the `hello` folder).
2. Add its name to `environments/dev/deployments.json`.
3. Run `./emulator.sh deploy`.

## Important
- **Stop/start loses deployments.** Your files are safe; `./emulator.sh start` redeploys them.
- After a Mint reboot, run `./emulator.sh start`.
- Log errors like `Datastore Error` or `api_security_actions_contract_ref` are normal noise – proxies still work.
- Save your work: `git add -A && git commit -m "message"`.
