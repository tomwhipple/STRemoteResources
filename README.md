**Archived:** This library is obsolete.

STRemoteResources
=================

STRemoteResources is set up to lazily retrieve objects from a REST (or REST-ish) data source.

The normal use case is for a UITableView to fetch a set of objects. We don't want to fetch thumbnail images until they are needed, so this is done lazily with incomplete transfers being canceled as the cell moves offscreen. Data transfer happens in a background thread (via NSOperation) so as not to affect UI performance.

Subclasses of STRemoteObject also permit the initial version of a resource (data file or image) to be shipped with the application bundle. Subsequently updates of the content can occur without needing to update the app.


