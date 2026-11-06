# Box Office App
![CI](https://github.com/TomasGic/box-office-app/actions/workflows/ci.yml/badge.svg)

## About the project
This project simulates a real box-office app for a small concert venue and is built from scratch with Ruby, SQLite, HTML, CSS and Vanilla Javascript, without any frameworks. The goal of this project is to explore and internalize how a complex framework, such as Ruby on Rails, works under the hood, so that working with it does not feel like magic later on.


## Requirements
* **Ruby**: version 3.4.7
* **Bundler**: version 2.6.9

## Setup
## Running the app

## Running the Tests
This project has been developed using TDD (Test Driven Development). It uses RSpec as the testing framework, configured with random test order to prevent state leakage between specs and verified partial doubles to prevent stubbing or mocking methods that do not exist on real objects.

To execute all tests at once run this command in the project root directory:
```bash
bundle exec rspec
```

To run a specific test file (spec), run the following command:
```bash
bundle exec rspec spec/box_office_spec.rb
```

### Replaying a failing seed
Because RSpec randomizes the test execution order, every test run outputs the test results with a specific seed number, for example `Randomized with seed 41093`. The seed number makes it possible to replay the failing execution in that exact order with `bundle exec rspec --seed 41093`.

### Replaying only failing tests
In this project RSpec is configured to allow for running failing tests separately by running the command `bundle exec rspec --only-failures`.

### Running RuboCop
This project uses the `rubocop` gem to check the Ruby code for style, layout and any potential bugs without executing the code. To check all Ruby files,RuboCop can be run using the following command from the root project directory:

```bash
bundle exec rubocop
```
Rubocop can alse be run on a specific file, for example:

```bash
bundle exec rubocop lib/box_office.rb
```

## Design decisions
## Known limitations
