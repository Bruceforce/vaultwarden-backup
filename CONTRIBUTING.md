# Contributing to Vaultwarden Backup

Welcome to Vaultwarden Backup! We appreciate your interest in contributing to the project.

All types of contributions are encouraged and valued. Please make sure to read this document before making your contribution.

---

## How to Contribute

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) to create new releases. This heavily relies on following the [Conventional Commits](https://www.conventionalcommits.org/) specification. So please ensure that all your commits are following the specification. There is an automated check included in the CI/CD pipeline which may cause the pipeline to fail if you try to submit a commit without a valid prefix.

The general flow is pretty easy:

1. Before creating a merge request you should open a new [issue](https://gitlab.com/1O/vaultwarden-backup/-/issues/new) describing the bug you have or the feature you want to implement.
2. Fork the repository.
3. Create a new branch from the [dev](https://gitlab.com/1O/vaultwarden-backup/-/tree/dev) branch: git checkout -b my-feature-branch.
4. Make your changes and commit them using the semantic commit message format.
5. Push your changes to your forked repository: git push origin my-feature-branch.
6. Submit a merge request to the [dev](https://gitlab.com/1O/vaultwarden-backup/-/tree/dev) branch of this repository.
