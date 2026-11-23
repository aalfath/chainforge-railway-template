# Changelog

Breaking changes are listed first in each entry. Read this before you apply a Railway update notice.

## 0.3.7.8 (2026-11-23)

- First release of the template.
- ChainForge 0.3.7.8 from PyPI (hash-locked `requirements.txt`, core install without the RAG extra) on `python:3.12.16-slim@sha256:5e2bdb1b0d542d5039cffb8181c65930093949194a65c365dfb1b0fe13a4fa5b`.
- Caddy 2.11.9 (`caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b`) in front: password on everything except `/healthz`, cross-site requests refused.
- Data on the Railway volume at `/data` (`/data/chainforge`).
