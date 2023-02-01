# escape=`

ARG BASE_IMAGE
ARG SPE_IMAGE
ARG TOOLING_IMAGE
# ARG SOLUTION_IMAGE
ARG SXA_IMAGE
ARG SMS_IMAGE
ARG HEADLESS_IMAGE

# FROM ${SOLUTION_IMAGE} as solution
FROM ${TOOLING_IMAGE} as tooling
FROM ${SPE_IMAGE} as spe
FROM ${SXA_IMAGE} as sxa
FROM ${SMS_IMAGE} as sms
FROM ${HEADLESS_IMAGE} as headless
FROM ${BASE_IMAGE}


SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Copy development tools and entrypoint
COPY --from=tooling \tools\ \tools\

WORKDIR C:\inetpub\wwwroot

# Add SMS module
COPY --from=sms \module\cm\content .\

# Add SPE module
COPY --from=spe \module\cm\content .\
# RUN Rename-Item -Path "c:\inetpub\wwwroot\App_Config\Include\Spe\Spe.IdentityServer.config.disabled" -NewName "Spe.IdentityServer.config"

# Add SXA module
COPY --from=sxa \module\cm\content .\
COPY --from=sxa \module\tools \module\tools
RUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; Remove-Item -Path C:\module -Recurse -Force; 

# Add Headless module
COPY --from=headless \module\cm\content .\
COPY --from=headless \module\tools \module\tools
RUN C:\module\tools\Initialize-Content.ps1 -TargetPath .\; Remove-Item -Path C:\module -Recurse -Force; 

# Copy solution website files
# COPY --from=solution \artifacts\website\ .\

# Copy solution transforms
# COPY --from=solution \artifacts\transforms\ \transforms\solution\

# Copy role transforms
# COPY .\transforms\ \transforms\role\

# Perform role transforms
# RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\role








