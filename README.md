BBC-RSS-Reader
==============

This is an example project of how it is possible to mix different techniques into an RSS Reader.

Improvements
==============
There is always room for improvements. 

The <b>UITableView reloadData</b> has to update a lot of cells when all rss feeds are active. It can block the ui thread.
I could try to only update relevant cells. However according a simple update on only relevant cells is slower than
reloading all data inside the UITableView. If we stack updates for blocks of cells there is a possible performance gain.

The <b>Core Data database will not yet be cleaned</b>. It depends on the purpose of the RSS feed of how long the data should be saved.

<b>Comments are "overused"</b> to demonstrate the use of different techniques. Production code should have less comments and only explain 
neccesary bits of code.

<i>You can see more improvements in the code source itself. I added TODO statements when there is improvement to be made</i>
