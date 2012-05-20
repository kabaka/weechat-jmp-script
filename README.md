# WeeChat j.mp URL Shortener

Shorten URLs in the input bar using Bitly's j.mp service.

Requires a j.mp user name and API key.

Shortened URLs are stored in a persistent local cache to save look-ups on
repeated URLs.

# Usage

Bind a key to `/jmp`. For example, for alt-enter (on some terminal emulators):

    /key bind meta-ctrl-M /jmp

Once you have typed your input, press the key you bound. URLs that are longer
than the threshold length will be shortened in the input bar.

# Known Problems

* If j.mp is down or your connection is slow, WeeChat will hang until the
connection times out.
* No error handling on bad API replies, so errors like 504s will result in
silliness.

# To-do

* Delete very old cache records (max cache size setting?).
* Make the settings into WeeChat options.
* Make the cache a little better.
* Shorten timeout.
* Better failure handling.
* Refactor.

