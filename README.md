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
- Each command's output is followed by a `[HH:MM:SS]` timestamp (24h format), so the scrollback tells when each command finished. It is rendered by the shell after the output, not written to stdout, so pipes, redirections and `$(...)` captures stay clean
