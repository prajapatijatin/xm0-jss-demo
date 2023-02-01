###### Setup instructions
**Before you start, you must have the following software components on your system**
- A valid Sitecore license file.
- Windows PowerShell 5.1. PowerShell 7 is not supported at this time.
- The current long-term support (LTS) version of the [Node.js](https://nodejs.org/)
- [.NET Core 3.1 SDK](https://dotnet.microsoft.com/download/dotnet-core/3.1) or higher (check your installed version with the `dotnet --version` command)
- [.NET Framework 4.8 SDK](https://dotnet.microsoft.com/download/dotnet-framework/net48)
- [Visual Studio 2019](https://visualstudio.microsoft.com/downloads/) or [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
- [Docker for Windows](https://docs.docker.com/docker-for-windows/install/, with *Windows Containers* enabled
- Any required components for [using Sitecore Containers](https://doc.sitecore.com/xp/en/developers/102/developer-tools/en/set-up-the-environment.html).

Once you cloned this repository, use the following instructions to set up the project.
1. Execute the following command in terminal while you are in the root directory of this project.
 `copy .\docker\.env.working .\docker\.env`
2. Place the license.xml file into <root>/docker/license folder. Please create the license folder if it does not exist. 