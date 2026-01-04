# mise-moonbit

A mise tool plugin for MoonBit toolchain.

## Installation

```bash
mise plugin install moonbit https://github.com/3w36zj6/mise-moonbit
```

## Environment variables

- `MOON_HOME` points to the installation root.
- `PATH` is extended with `${MOON_HOME}/bin` so `moon`, `moonfmt`, `mooninfo`, etc. are available.
- Override downloads with `CLI_MOONBIT` (default `https://cli.moonbitlang.com`).
- Set `MOONBIT_INSTALL_VERSION` to pin a release instead of `latest`/`nightly`.
- Set `MOONBIT_INSTALL_DEV=true` to request the `<target>-dev` builds the official script supports.

## Usage

```bash
mise exec moonbit@latest -- moon version
mise exec moonbit@latest -- moon new hello
mise exec moonbit@latest -- moon run cmd/main
```

## Development

1. Link your plugin for development:

   ```bash
   mise plugin link --force mise-moonbit .
   ```

2. Run tests:

   ```bash
   mise run test
   ```

3. Run linting:

   ```bash
   mise run lint
   ```

4. Run full CI suite:

   ```bash
   mise run ci
   ```

## References

- MoonBit download page: https://www.moonbitlang.com/download
- Original installer script that inspired this plugin: https://cli.moonbitlang.com/install/unix.sh

## License

MIT
