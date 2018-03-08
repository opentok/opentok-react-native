# Contributing Guidelines

If you're interested in contributing to this project, here are a few ways to do so:

*  Bug fixes
    -  If you find a bug, please first report it using Github Issues.
    -  Issues that have already been identified as a bug will be labelled `bug`.
    -  If you'd like to submit a fix for a bug, send a Pull Request from your own fork and mention the Issue number.
        +  Include a test that isolates the bug and verifies that it was fixed.
*  New Features
    -  If you'd like to add a feature to the library that doesn't already exist, feel free to describe the feature in a new Github Issue.
    -  Issues that have been identified as a feature request will be labelled `enhancement`.
    -  If you'd like to implement the new feature, please wait for feedback from the project maintainers before spending too much time writing the code. In some cases, `enhancement`s may not align well with the project objectives at the time.
*  Documentation & Miscellaneous
    -  If you think the documentation could be clearer, or you have an alternative
       implementation of something that may have more advantages, we would love to hear it.
       -  If its a trivial change, go ahead and send a Pull Request with the changes you have in mind
       -  If not, open a Github Issue to discuss the idea first.

## Requirements

For a contribution to be accepted:

*  Code must follow existing styling conventions
*  Commit messages must be descriptive. Related issues should be mentioned by number.

If the contribution doesn't meet these criteria, a maintainer will discuss it with you on the Issue. You can still continue to add more commits to the branch you have sent the Pull Request from.

## How To

1. Fork this repository on GitHub.
2. Clone/fetch your fork to your local development machine.
3. Create a new branch (e.g. `issue-12`, `feat.add_foo`, etc) and check it out.
4. Make your changes and commit them.
5. Push your new branch to your fork. (e.g. `git push myname issue-12`)
6. Open a Pull Request from your new branch to the original fork's `master` branch.

## Development Guidelines

1. Follow [installation guidelines](README.md).
2. Modify JS components in `src/js/`.
3. Modify iOS components in `ios/`.
4. Modify Android components in `android/`.