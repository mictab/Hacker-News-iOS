# Hacker News iOS app

## Introduction
If you're a real computer scientist of course you're already reading the news.

Wouldn't you like to be able to read the news in your phone, in an app?? The answer is yes.

## Wat is this?

A native iOS app (or soon to be!)

## Our workflow

### General Guidelines

- **English or code, nothing else**

No commit messages in languages other than English. No code comments in anything but English. This topic applies everywhere that is relevant. 
Please use your own good judgement :-)

- **Don't be afraid to ask questions**

For reals. No one's judging you.

- **Use the issue tracker for issues, enhancements, questions etc.**

It keeps all the relevant info in one place and is good for documentation and reference. Also label the issues.

- **Use 'good' code style**

'Good' you ask, wat is dat? Well, for example, variables should have logical names and be in English. Indentation should be consistent and the code style in general should be consistent.
Self documenting code is great but if necessary comment the code. In Swift using `//MARK: Blablabla` is pretty nice style for sectioning the code.

- **Test your code**

Yep, this is a good idea.

### Github workflow

- **Always branch out of `develop`**

`master` is for production code and should not have broken code. Basically, we're using the feature branch model (see [here](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)). Create a feature branch (with a good name), branching out of `develop`. Work on it and do ya thing, and when ready create a PR (pull request) into `develop` and have someone else look at the code. Please test the code before creating the pull request (or add WIP in the PR title if the PR is a work in progress, see next section).

- **Add [WIP] in the PR title if it's a work in progress**

If you're working on the PR and still pushing code to the branch, add [WIP] into the title. For example:
`[WIP] Add dancing zebra functionality`. This means that you're still working on the feature and that the other devs don't need to look at the PR just yet.

- **Always use feature branches**

New functionality? Then create a new branch.

- **Commit your code often**

Commit often. Also make sure that the commit messages look good. Use the imperative, present tense like so: 'Change localization strings'
The first line of the commit message should be a short summary of the commit itself. Then, if necessary, add a new empty line to the commit and after that write a more descriptive message. Ehhh, you know what? See [here](http://git.kernel.org/cgit/git/git.git/tree/Documentation/SubmittingPatches?id=HEAD) for guidelines to commit messages.