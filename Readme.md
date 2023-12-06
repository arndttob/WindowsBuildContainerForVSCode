# WindowsBuildContainerForVSCode
## Installation / Configuration
- installed docker desktop
  - switched from linux to windows containers
- created an image from windows:ltsc2019
  - installed latest powershell, openssh and VS BuildTools 2022
  - configured the openssh-server (hostkeys, new user, fix filepermissions)
  - started container as daemon and mounting source code to build
- in visual studio code
  - install remote explorer, remote development, remote - ssh
  - in remote-explorer connect to docker containers openssh-server
  - in remote-explorer open mounted folder (your source code to build) in container
  - start build/debug (works also with breakpoints e.g.)
Depending on the language you want to build, VS code lets you install the required extension into the remote (container).

## Tested so far
- Build and debug powershell script in the docker container via Visual Studio Code

## To Do
- SSH public key authentication. By now, password has to be entered several times for connecting to the container
- Preinstalled Visual Studio Code extensions (powershell, C#/.Net)
