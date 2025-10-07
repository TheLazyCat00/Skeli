# Skeli

A Neovim plugin that automatically applies skeleton templates to empty buffers based on filename patterns.

## Features

- Automatically detects empty buffers and applies matching templates
- Supports pattern matching with `-` to `*` conversion (e.g., `-.py` becomes `*.py`)
- Exact filename matching (e.g., `main.js` matches exactly)
- Multiple skeleton directory locations
- Manual template application commands

## Installation

Add this to your Neovim configuration:

```lua
-- If using lazy.nvim
{
    "",
    event = "VeryLazy",
    opts = {},
}

-- Or directly in your init.lua
require('skeleton').setup()
```

## Configuration

```lua
require('skeleton').setup({
    template_dir = vim.fn.stdpath('config') .. '/skeleton',
    fallback_dirs = {
        vim.fn.stdpath('data') .. '/skeleton',
        vim.fn.expand('~/.local/nvim/skeleton'),
    }
})
```

## Template Directories

The plugin searches for templates in these locations (in order):
1. `~/.config/nvim/skeleton/` (or your `stdpath('config')`)
2. `~/.local/share/nvim/skeleton/` (or your `stdpath('data')`)
3. `~/.local/nvim/skeleton/`

## Template Naming

### Pattern Templates
- `-.py` → matches any `.py` file (e.g., `script.py`, `test.py`)
- `-.html` → matches any `.html` file
- `-.go` → matches any `.go` file

### Exact Match Templates
- `main.js` → matches only `main.js`
- `README.md` → matches only `README.md`
- `Makefile` → matches only `Makefile`

## Usage

### Automatic
The plugin automatically applies templates when:
- Opening a new file (`BufNewFile`)
- Entering an empty buffer with a filename

### Manual Commands
- `:SkeletonApply` - Apply template to current buffer
- `:SkeletonList` - List available templates and their patterns

## Example Templates

Create these files in your skeleton directory:

**skeleton/-.py** (Python template):
```python
#!/usr/bin/env python3
"""
Module description here.
"""

def main():
    """Main function."""
    pass

if __name__ == "__main__":
    main()
```

**skeleton/main.js** (Express server template):
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'Hello World!' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

## How It Works

1. When you open an empty buffer (e.g., `nvim test.py`)
2. The plugin checks if the buffer is empty or contains only whitespace
3. It searches the skeleton directories for matching templates
4. Template names with `-` are converted to `*` for pattern matching
5. The best matching template is inserted into the buffer

## Priority System

1. **Exact matches** have highest priority (e.g., `main.js` matches `main.js`)
2. **Pattern matches** have lower priority (e.g., `-.py` matches `script.py`)

This ensures specific templates override general ones when both exist.
