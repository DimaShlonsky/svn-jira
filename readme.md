# SVN-JIRA

This is a small utility to integrate Tortoise SVN with JIRA. It allows you to mention a JIRA issue in a commit message and have a comment with a contents of that message automatically added to that issue. You can also use shortcut commands like `/fixed <id>` which will transition the issue into the "waiting for testing" state.

Here is a little demo:

![demo](https://dha4w82d62smt.cloudfront.net/items/1c2l0f2u2G221t1N1B3l/Screen%20Recording%202018-01-16%20at%2006.15.38%20PM.gif)

# Installation

1. Make sure you have your JIRA username and password. If you don't, follow [these](https://seatgeekenterprise.atlassian.net/wiki/spaces/~dshlonsky/pages/41615836/How+to+get+JIRA+username+and+password) instructions to get it.
1. Download the powershell scripts to some folder. This will be the installation folder.
1. Open a Powershell prompt **as admin**, `cd` to the installation folder and run the install script for the SVN working copy folder that you want to integrate with JIRA. For example, if your working folder is `c:\SroDev\CurrentVersion`, run:
    ```
    PS C:\> cd C:\tmp\svn-jira-master
    PS C:\tmp\svn-jira-master> Set-ExecutionPolicy -Scope Process Unrestricted
    PS C:\tmp\svn-jira-master> .\install.ps1 d:\SroDev\CurrentVersion
    ```
1. Provide your JIRA username and password
1. Done!

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
