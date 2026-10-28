# CHIP 8.5: Intro to RSpec and TDD

[View this assignment on GitHub](https://github.com/saasbook/hw-rspec-rails-intro)

[Read the assignment instructions](instructions/README.md)

In this assignment you will take a deep dive into both the concepts and mechanics of doing test-driven development (TDD) with the RSpec testing framework, using the Guard tool to automatically re-run tests as you change code and using WebMock to provide "canned" responses for tests that exercise code that communicates with an external service. You will use TDD to add a feature to RottenPotatoes that searches The Movie Database (TMDb) and adds the movies it finds, then deploy the result to Render or Heroku. The autograder tests both your deployed app and the code you submit.

This repo is the RottenPotatoes app from CHIPS 5.3 (Rails 7.1, Ruby 3.3), with starter files for the search page.

**Remember, commit early and often!**

## GitHub

If your course staff created a repository for you, clone that one. Otherwise, make your own **private** repository from the template [`https://github.com/saasbook/hw-rspec-rails-intro`](https://github.com/saasbook/hw-rspec-rails-intro) (it will hold your TMDb API key), or, if you are not pushing your changes to GitHub, clone the template directly:

```sh
git clone https://github.com/saasbook/hw-rspec-rails-intro.git rspec-rails-intro
```

## Instructions

The assignment itself is in the [instructions](instructions/README.md) folder of this repo:

1. [Intro to RSpec and TDD](instructions/01-Intro-to-RSpec-and-TDD.md)
2. [Getting Started](instructions/02-Getting-Started.md)
3. [Part 1: TDD drives creating route, view, and controller method](instructions/03-Part-1--TDD-drives-creating-route--view--and-controller-method.md)
4. [Part 2: Getting the first spec to pass](instructions/04-Part-2--Getting-the-first-spec-to-pass.md)
5. [Part 3: More controller behaviors](instructions/05-Part-3--More-controller-behaviors.md)
6. [Part 4: TDD for the Model](instructions/06-Part-4--TDD-for-the-Model.md)
7. [Part 5: Implementing find_in_tmdb, and Stubbing the Internet](instructions/07-Part-5--Implementing-find-in-tmdb--and-Stubbing-the-Internet.md)
8. [Deploying and submitting](instructions/08-Submission-Instructions.md)

## Running the completed TMDb feature

Use Ruby 3.3.8 or newer, then run:

```sh
bundle config set without 'production'
bundle install
bin/rails db:prepare
bundle exec rspec
```

Set `TMDB_API_KEY` to your TMDb API v3 key in your shell or hosting provider's
Environment settings. No real key is required for tests: WebMock supplies the
responses and blocks external requests. Start the app with `bin/rails server`
and follow **Search TMDb** from the movie list. The title is required; the year
is optional. **English Only** filters results to English original-language
movies. Searches return unsaved movies; **Add movie** saves the selected result
with the assignment's default rating of R.

For automatic test runs, use `bundle exec guard`. Before submitting, follow
[instructions/08-Submission-Instructions.md](instructions/08-Submission-Instructions.md)
to deploy, configure `TMDB_API_KEY`, and fill `rottenpotatoes-url.txt` with the
actual deployed URL.
