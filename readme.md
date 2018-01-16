# SVN-JIRA

This is a small utility to integrate Tortoise SVN with JIRA. It allows you to mention a JIRA issue in a commit message and have a comment with a contents of that message automatically added to that issue. You can also use shortcut commands like `/fixed <id>` which will transition the issue into the "waiting for testing" state.

Here is a little demo:

![demo](https://dha4w82d62smt.cloudfront.net/items/1c2l0f2u2G221t1N1B3l/Screen%20Recording%202018-01-16%20at%2006.15.38%20PM.gif)

# Installation

Download the powershell scripts to some folder and configure a hook in Tortoise SVN to run the `post-commit-hook.ps1` script on commit with the following values

* Hook Type = "Post-Commit Hook"
* Working Copy Path = _\<the-path-to-your-working-copy-folder\>_
* Command Line to Execute = `powershell.exe -ExecutionPolicy Unrestricted -File "C:\the-folder-where-you-downloaded-the-files\post-commit-hook.ps1"`

Here is how it looks with `the-folder-where-you-downloaded-the-files=C:\Users\Dima\Dev\other\svn-jira-cmd\` and `the-path-to-your-working-copy-folder=C:\Dev\other\test-a`

![config demo](https://dha4w82d62smt.cloudfront.net/items/2L1E301w1w1e2x1e1n3M/Image%202018-01-16%20at%206.51.04%20PM.png)
# Commands
These command/shortucts are inspired by quick actions like the ones found on [GitLab](https://docs.gitlab.com/ee/user/project/quick_actions.html).
All commands must appear as separate lines at the end of the commit mesage. They will not be a part of the final commit message. You can use each command more than once, if necessary

* `/fixed [issue]` (aka 'fixes') - transition the issue to the "Fixed not comitted" state
* `/view [issue]` - open the issue page

# Caveats
:warning: Note that TSVN hooks work only with TSVN and will not run if you use SVN from commandline or through some other implementation
