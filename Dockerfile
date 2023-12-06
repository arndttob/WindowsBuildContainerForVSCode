FROM mcr.microsoft.com/windows:ltsc2019

# Install Powershell
ADD https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/PowerShell-7.4.0-win-x64.zip c:/powershell.zip
RUN powershell.exe -Command Expand-Archive c:/powershell.zip c:/PS7 ; Remove-Item c:/powershell.zip
RUN C:/PS7/pwsh.EXE -Command C:/PS7/Install-PowerShellRemoting.ps1

# Install SSH
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.4.0.0p1-Beta/OpenSSH-Win64.zip c:/openssh.zip
RUN c:/PS7/pwsh.exe -Command Expand-Archive c:/openssh.zip c:/ ; Remove-Item c:/openssh.zip
RUN c:/PS7/pwsh.exe -Command c:/OpenSSH-Win64/Install-SSHd.ps1

# Configure SSH
COPY sshd_config c:/OpenSSH-Win64/sshd_config

WORKDIR c:/OpenSSH-Win64/
# Don't use powershell as -f paramtere causes problems.
RUN c:/OpenSSH-Win64/ssh-keygen.exe -t dsa -N "" -f ssh_host_dsa_key && \
    c:/OpenSSH-Win64/ssh-keygen.exe -t rsa -N "" -f ssh_host_rsa_key && \
    c:/OpenSSH-Win64/ssh-keygen.exe -t ecdsa -N "" -f ssh_host_ecdsa_key && \
    c:/OpenSSH-Win64/ssh-keygen.exe -t ed25519 -N "" -f ssh_host_ed25519_key

# Create a user to login, as containeradministrator password is unknown
RUN net USER <someUsername> "<somePassword>" /ADD && net localgroup "Administrators" "<someUsername>" /ADD

# Set PS7 as default shell
RUN C:/PS7/pwsh.EXE -Command \
    New-Item -Path HKLM:\SOFTWARE -Name OpenSSH -Force; \
    New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value c:\ps7\pwsh.exe -PropertyType string -Force ; 

RUN C:/PS7/pwsh.EXE -Command \
    ./Install-sshd.ps1; \
    ./FixHostFilePermissions.ps1 -Confirm:$false;

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Download the Build Tools bootstrapper.
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe
    
# Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
RUN (start /w vs_buildtools.exe --quiet --wait --norestart --nocache \
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" \
        --add Microsoft.VisualStudio.Workload.AzureBuildTools \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
        --remove Microsoft.VisualStudio.Component.Windows81SDK \
        || IF "%ERRORLEVEL%"=="3010" EXIT 0)
    
# Cleanup
RUN del /q vs_buildtools.exe

ENV $env:DOTNET_ROOT="C:\Users\ContainerAdministrator\AppData\Local\Microsoft\dotnet\"
ENV $env:PATH=$env:PATH=$env:PATH+";C:\Users\ContainerAdministrator\AppData\Local\Microsoft\dotnet\"

EXPOSE 22

# For some reason SSH stops after build. So start it again when container runs.
CMD [ "c:/ps7/pwsh.exe", "-NoExit", "-Command", "Start-Service" ,"sshd" ]
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
