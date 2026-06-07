# Industry-standard Minecraft base image
FROM itzg/minecraft-server:latest

# Set environment variables
ENV EULA=TRUE
ENV TYPE=FABRIC