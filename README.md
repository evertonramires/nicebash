## About

These Zsh settings are basically a copy of the default configuration that comes with Kali Linux, but adjusted to include autosuggestions, command highlighting, and a shell script installer for easy redeployment.

[![Support my work ❤️](https://img.shields.io/badge/Support%20my%20work%20❤️-orange?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/c/evertonics)


## Usage

```
sudo chmod +x install_nicebash.sh
sudo ./install_nicebash.sh
exec zsh
```

- ctrl+F to open bash command history
- Each command's output is preceded by a `[HH:MM:SS]` timestamp (24h format) of when the command was sent, on its own line so column-aligned output like `ls -l` isn't shifted. It is drawn by the shell, not written to stdout, so pipes, redirections and `$(...)` captures stay clean
- For long-running commands, `stamp <command>` prefixes **every** output line with its arrival time. Stamping auto-disables when the output is piped or redirected, so `stamp ping 8.8.8.8 | grep ttl` still receives clean data. `ping` is aliased to `stamp ping` out of the box, so a bare `ping 8.8.8.8` gets per-line timestamps — add aliases for other streaming commands the same way
