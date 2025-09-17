# Changelog

## [Released]

### Improvements (AI Assisted by GPT-5 Code)
- **Project Structure**
  - Refined overall layout and consistency.
  - Added clearer separation of `manifests`, `patches`, and `src` directories.

- **Makefile**
  - Simplified workflow and improved readability.
  - Added `help` target with categorized usage output.
  - Enhanced version check (`ISTIO_CODE_VERSION` vs `IMAGE_VERSION`).
  - Added better error handling for `USER` and `OWNER`.
  - Improved logging messages with clear status indicators.

- **Documentation**
  - Expanded **Prerequisites** section with Docker, kubectl, and kind setup.
  - Clarified **Build Image Workflow** with a detailed target reference table.
  - Improved **Usage Examples** with step-by-step commands for both Kubernetes and Docker.
  - Added **AI Assisted** note to acknowledge optimization.

- **Patches (patches/ directory)**
  - `debugtool.go`: Developed and optimized with **GPT-5 Codex** to extend `istioctl` with custom commands.
  - `root.go`: Refined and patched to register the new `debugtool` command, with Codex-assisted improvements.
  - General coding style and maintainability enhanced by Codex suggestions.

---
