/// Only the browser can save a file from the portal.
Future<void> saveDownload(List<int> bytes, String fileName) async =>
    throw UnsupportedError('Saving files is only available in the browser.');
