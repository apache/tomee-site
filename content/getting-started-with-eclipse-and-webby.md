# TomEE and Eclipse using Webby

If you want to use Eclipse and WTP (the classic way), please read this [docs](http://tomee.apache.org/tomee-and-eclipse.html).

If you intends to run a Maven WAR project, you can adopt [m2eclipse-webby](https://github.com/tesla/m2eclipse-webby), because it will be more efficient. In this case, follow this docs.

## Prerequisite
Download and install both Apache TomEE (1.7.2 minimum) and Eclipse IDE (not JavaEE version, because Webby doesn't work if [m2eclipse-WTP](https://www.eclipse.org/m2e-wtp/) is present).

### m2eclipse
The next thing you need is [m2eclipse](http://www.eclipse.org/m2e/) plugin.
If you doesn't have it in your eclipse package, install it like another plugin.

### Webby
0. Then you need to install [m2eclipse-webby](https://github.com/tesla/m2eclipse-webby)
1. In eclipse, select menu "Help" / "Install new software", and type this URL : https://repository.takari.io/content/sites/m2e.extras/m2eclipse-webby/0.2.2/N/LATEST/
2. Select Web Application Launcher for M2Eclipse / Webby Core
3. Click Finish and continue the classic installation way.
4. Restart eclipse.

## Setting up eclipse project
1. Create new Maven project or import an existing one (only War project are accepted with Webby).
2. Add new Debug configuration (Right click on the project / Debug As / Debug Configuration)
3. Select Launch Type "Webby", right click "New"
4. Browse your project if it not present
5. Type an optionnal context root
6. Select container "tomee1x" and select "Installed" as type (the only way who works right now)
7. Browse your tomEE installation in "Home" section
8. Optionnal : change port and timeout values.
9. Click "Apply", and "Debug" to start TomEE.

## Webby capabilities
* Webby manage code hot replacement if you don't change method signature and so on... If other case you need to restart it.
* Webby manage hot jsp replacement too.
* If you want to see Webby status Click menu "Widows" / "Show View" / "Other" / "Webby" / "Webapps". You can start and stop webby in this panel.
* If you need to start 2 or more Webby in the same time, you need to change port to at least 3 numbers more. Example : 8080 and 8084 (other value are reserved by Webby automatically).
* If you have an error "timeout ..." during Webby start, you can change the Webby timeout in debug configurations (Note : this error will not stop Webby, it's just a warning).
* In opposite to m2eclipse-WTP, Webby will not "publish" all of your project dependencies. It makes just a link to your Maven local repositories. You can see the entire list of dependencies in Webby start console.
* If you want to "publish" you code in Webby, just start it and it works.
