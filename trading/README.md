# 📈 Trading Script Repository Structure

This section of the EVBoise repo is reserved for stock trading automation scripts.
Each folder has a specific purpose to keep development clean and versioned.

trading/
├── _dev/        → Sandbox for development and experiments
├── active/      → Stable, production-ready scripts
├── _archive/    → Retired or old versions
└── README.md    → Folder purpose and workflow

## Workflow Summary

1. Develop new scripts in _dev/
2. Test and validate results in VS Code
3. Promote finished scripts to /active/ using Promote-TradingScript.ps1
4. Archive any replaced scripts automatically
5. Push to GitHub to back up your work

Example usage:
.\scripts\Promote-TradingScript.ps1 -FileName MyScript.py
