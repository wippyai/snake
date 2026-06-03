# Snake

Classic snake game for the terminal.

## Installation

```yaml
entries:
  - name: snake
    kind: ns.dependency
    component: wippy/snake
    version: "*"
```

## Usage

```bash
wippy run snake [width] [height]
```

Default size is 40x20.

## Controls

- **WASD** or **Arrow keys**: Move
- **Q**: Quit
- **R**: Restart
