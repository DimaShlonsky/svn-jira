# SVN-JIRA

This is a small utility to integrate Tortoise SVN with JIRA. It allows you to mention a JIRA issue in a commit message and have a comment with a contents of that message automatically added to that issue. You can also use shortcut commands like `/fixed <id>` which will transition the issue into the "waiting for testing" state.

Here is a little demo:

![demo](https://dha4w82d62smt.cloudfront.net/items/1c2l0f2u2G221t1N1B3l/Screen%20Recording%202018-01-16%20at%2006.15.38%20PM.gif)

# Installation

Download the powershell scripts to some folder and configure a hooks in Tortoise SVN like this:
1. Open the Tortoise SVN settings (right-click->TortoiseSVN->settings) and go to "Hook scripts"
1. Add hooks like shown below:

|Hook type  |Path   |Command Line   |Wait   |Show/Hide  | Enforce|
|-----------|-------|---------------|-------|-----------|--------|
`pre_commit_hook`|your working copy path|`powershell.exe -ExecutionPolicy Unrestricted -File "C:\install-folder\pre-commit-hook.ps1"`|true|hide|true
`post_commit_hook`|your working copy path|`powershell.exe -ExecutionPolicy Unrestricted -File "C:\install-folder\post-commit-hook.ps1"`|true|hide|true

Where `install-folder` is the folder where you placed the downloaded scripts and "your working copy path" is the root folder where you checked out your SVN repository 

# Commands
These command/shortucts are inspired by quick actions like the ones found on [GitLab](https://docs.gitlab.com/ee/user/project/quick_actions.html).
All commands must appear as separate lines at the end of the commit mesage. They will not be a part of the final commit message. You can use each command more than once, if necessary

* `/fixed [issue]` (aka 'fixes') - transition the issue to the "Fixed not comitted" state
* `/view [issue]` - open the issue page

:warning: Because the commands are stripped from the commit message, it is recommended that you also mention the name of the issue in the message itself in order to be able to see the issue number in SVN log's "Bug Id" column. When you do this you don't have to specify the issue id in the command - it will use the id you mentioned.
For example:
```
Did so-and-so change (DEV-9999)
/fixed
```

If your commit resolves multiple issues, you can do:
```
Did some other change (DEV-10001)(DEV-10002)
/fixed DEV-10001
/fixed DEV-10002
```
# Caveats
:warning: Note that TSVN hooks work only with TSVN and will not run if you use SVN from commandline or through some other implementation
