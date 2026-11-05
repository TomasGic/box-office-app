# Contributing to Box Office App
This file contains notes on the development workflow used in this project, including the branch naming conventions, the use of conventional commits, code quality and continuous integration (CI), and the reviewing and merging of pull requests.

## Development workflow
1. Every piece of work on this project starts with opening an issue (each issue has only two templates: task or bug).
2. For each issue the developer creates a working branch. The work is never done on the `main` branch.
3. When the work is completed, the working branch is pushed to github and a pull request is created and filled in using the pull request template defined in `.github/PULL_REQUEST_TEMPLATE`.
4. Reviewer gets notified the pull request has been created, reviews it and when approved, the working branch can be merged.

**Additional notes**: Developer creates only 1 branch per issue and 1 pull request per branch. If the scope of the development work outlined in the issue turns out to be too big, developer notifies the reviewer, who then divides the issue into smaller chunks.

## Branch Naming Convention
Branch names should summarize the work as concisely as possible and should be prefixed with either `feat/`, `fix/` or `chore/`.

**Examples**:
`feat/add-money-class` - this branch is for the development of a new feature
`fix/money-rounding-logic` - this branch is for fixing incorrect rounding logic in the Money class
`chore/add-rubocop-configuration` - this branch is for adding rubocop configuration files

## Conventional Commits
This project uses conventional commits for a more readable and explicit commit history. Each commit message should adhere to the following structure:
`<type>(<scope>): <short description>`

The type typically corresponds to the prefix in the name of the working branch:

* **feat**: a new feature or functionality of the app
* **fix**: a bug fix
* **chore**: folder structure setup, new or updated configuration files, etc.

The scope can refer to a particular domain of the app, for example:
`feat(database): add schema.sql and seed.sql`

## Code Quality and CI
Before submitting a PR, developer should ensure that the code meets the necessary quality requirements and that all tests pass with random order.

* Running `bundle exec rubocop` returns zero offenses

* Running `bundle exec rspec` returns 0 failures

## Review and Merge Process
Once a pull request is created and its description filled in, mentor will review it and add their comments with suggestions on what to fix or improve. Only when the pull request is approved by the reviewer can the pull request be merged.
